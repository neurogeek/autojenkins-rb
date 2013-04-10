#Module autojenkins
#Ruby module to talk with Jenkins using JSON API
#

require 'pp'
require 'uri'
require 'json'
require 'yaml'
require 'net/http'
require 'nokogiri'

module AutoJenkins

    LOGIN = 'LOGIN'
    PASSWD = 'PASSWD'
    BASE_URL = "/api/json"

    URLs = {
        'LIST' => "#{BASE_URL}",
        'JOBINFO' => "/job/%s#{BASE_URL}",
        'CONFIG' => "/job/%s/config.xml",
        '_ABLE' => "/job/%s/%s",
        'DELETE' => "/job/%s/doDelete",
        'NEWJOB' => "/createItem?name=%s",
        'LAUNCH' => "/job/%s/build/api/json",
        'BUILD' => "/job/%s/%i#{BASE_URL}",
    }

    class JenkinsException < Exception
    end

    class ExUnauthorized < Exception
    end

    class ExUndefined < Exception
    end

    class Helpers

        def self.parseConfig(config)
            tree = {}

            begin
                tree = YAML::parse(File.open(config)).transform
            rescue 
                raise IOError, "Config file not found"
            end

            ['URL', 'USER', 'PASSWD'].each do |k|
                if not tree.has_key?(k)
                    raise IndexError.new("Key %s not found in config file" % k)
                end
            end

            return tree
        end

        def self._get_request(jurl, command, args, auth, 
                              post_args=nil, content_type=nil)

            url = Helpers._build_url(jurl, command, args)

            url_str = (url.query == nil) ? url.path : "#{url.path}?#{url.query}"

            if post_args.nil?:
                req = Net::HTTP::Get.new(url_str)
            else
                req = Net::HTTP::Post.new(url_str)
                req.body = post_args
            end

            req.basic_auth auth[LOGIN], auth[PASSWD] 

            res = Net::HTTP.start(url.host, url.port) {|http|

                if content_type
                    req["Content-Type"] = content_type
                end

                ret = http.request(req)

                if not [Net::HTTPOK, Net::HTTPFound, Net::HTTPNotFound].include? ret.class 
                    if ret.instance_of? Net::HTTPUnauthorized
                        raise ExUnauthorized, "Unauthorized, check your credentials" 
                    else
                        raise ExUndefined, "Http request failed!"
                    end
                end

                ret
            }

            #Some requests do not return JSON. Such as config.xml
            ct = res.get_fields('Content-type')

            if ct.nil?
                ct = "text/plain"
            else
                ct = ct[0] 
            end

            ctype = ct.split(';')[0]

            if ctype == 'application/javascript' or
                    ctype == 'application/json'
                #handle JSON
                begin
                    return JSON.parse(res.body)
                rescue JSON::ParserError
                    return "{}"
                end
            end

            unless res.body.nil?
                return res.body
            end

            return "{}"
        end

        def self._build_url(jurl, command, args)
            return URI.parse("#{jurl}" + (URLs[command] % args))
        end
    
    end

    class Build
        attr_accessor :name, 
                      :url,
                      :revision, 
                      :branch, 
                      :revision, 
                      :status,
                      :building,
                      :node,
                      :duration
        def ppretty()
            print "Name: #{name}\n"
            print "\tBranch: #{branch}\n"
            print "\tRevision: #{revision}\n"
            print "\tStatus: #{status}\n"
            print "\tDuration: #{duration}\n"
            print "\tNode: #{node}\n"
            print "\tBuilding: #{building}\n"
        end
    end 

    class Job
        attr_accessor :info, :name, :jurl, :auth, :is_set

        def initialize(name, jurl, auth, token=nil)
            @name = name
            @jurl = jurl
            @auth = auth
            @info = false

            if name
                @e_name = URI.escape(@name)
                @info = Helpers._get_request(@jurl, 'JOBINFO', URI.escape(name), auth)
            end

            @is_set = @info ? true : false
        end
        
        def launch(token)
            res = Helpers._get_request(@jurl, 'LAUNCH',
                  [@e_name, token], @auth)
            return true
        end

        def delete()
            res = Helpers._get_request(@jurl, 'DELETE',
                  [@e_name], @auth, post_args="delete=true")
            return true
        end

        def get_build(buildnum)
            res = Helpers._get_request(@jurl, 'BUILD', 
                [@e_name, buildnum], @auth)

            build = Build.new()
            begin
                build.branch = res['actions'][1]['lastBuiltRevision']['branch'][0]['name']
                build.revision = res['actions'][1]['lastBuiltRevision']['branch'][0]['SHA1']
            rescue
            end

            build.status = res['result']
            build.name = res['fullDisplayName']
            build.duration = res['duration']
            build.building = res['building']
            build.url = res['url']
            build.node = res['builtOn']

            return build
        end

        def info_items()
            return @info.keys
        end

        def _able_job(action)
            res = Helpers._get_request(@jurl, '_ABLE', [@e_name, action], @auth, post_args={'data' => ""})
            return true
        end 

        def disable()
            return _able_job('disable')
        end

        def enable()
            return _able_job('enable')
        end

        def copy(jobname, enable=false)
            config = get_config()
            return create_job(jobname, config, enable)
        end

        def create_job(jobname, config, enable=false)
            sts = Helpers._get_request(@jurl, 'NEWJOB', [URI.escape(jobname)],
                    @auth, post_args=config, content_type="application/xml")

            newjob = Job.new(jobname, @jurl, @auth)

            unless enable
                newjob.disable()
            end

            return newjob
        end

        def get_config()
            if @is_set
                config_xml = Helpers._get_request(@jurl, 'CONFIG', [URI.escape(@name)], @auth)
                return config_xml
            end
            return ""
        end

        def is_set?()
            return @is_set
        end

        def method_missing(name)

            name.to_s =~ /^get_(.*)$/
            match = $1

            unless match.nil?
                if @info.has_key? $1
                    return @info[$1]
                end
            end

            return nil
        end
    end

    class Jenkins
        def initialize(s_uri, auth_info, debug=false)
            @debug = debug
            @jurl = s_uri
            @auth = {LOGIN => auth_info[0], PASSWD => auth_info[1]}
        end

        def get_job(jobname)
            return Job.new(jobname, @jurl, @auth)
        end

        def delete_job(jobname)
            j = get_job(jobname)
            res = j.delete()
            return res
        end

        def create_from_xml(jobname, config_xml)
            newjob = Job.new(jobname, @jurl, @auth)
            newjob = newjob.create_job(jobname, config_xml, enable='true') 
            return newjob
        end

        def all_jobs()
            ob_jobs = []
            jobs = Helpers._get_request(@jurl, 'LIST', [], @auth)
	    jobs = JSON::parse(jobs)
            jobs['jobs'].each do |j|
                ob_jobs << Job.new(j['name'], @jurl, @auth)
            end

            return ob_jobs
        end
    end
end
