#!/usr/bin/env ruby

require 'autojenkins'

URL='http://jenkins.ng.com:8080'
AUTH=["neurogeek", "123qwe4r!!"]
#TOKEN=""

if URL == ''
    puts "To use this functions, please configure URL and AUTH"
end
JENK = AutoJenkins::Jenkins.new(URL, AUTH)

def ListAll() 
    jobs = JENK.all_jobs()
    if jobs
        jobs.each do |jb|
            print "#{jb.name} --> #{jb.get_url}\n"
            print "DisplayName: #{jb.get_displayName}\n"
            jb.info_items.each do |i|
                puts i
            end
        end
    end
end

def CreateFromJob(jobname, newjobname)
    job = JENK.get_job(jobname)
    job2 = job.copy(newjobname)
    print "#{job2.name}\n"
end

def GetBuildInfo(jobname, buildnum)
    job = JENK.get_job(jobname)
    bld = job.get_build(buildnum)
    return bld
end

def GetConfig(jobname)
    job = JENK.get_job(jobname)
    return job.get_config()
end

def GetJob(jobname)
    return  JENK.get_job(jobname)
end

def GetInfo(jobname)
    def pretty_print(entry, tab=1)

        if entry.kind_of? Hash 
            entry.keys.each do |k|
                print " " * tab * 2
                print "#{k} ----> \n"
                pretty_print(entry[k], tab=tab+1)
            end
        elsif entry == nil
            print " " * tab * 2
            print "[NONE]\n"
        elsif entry.kind_of? Array
            entry.each do |v|
                pretty_print(v, tab+1)
            end
        else
            print "\t" * tab
            print "#{entry}\n"

        end
    end
    job = JENK.get_job(jobname)
    job.info.keys.each do |k|
        print "#{k} ----> \n"
        pretty_print job.info[k]
    end
end

# Uncomment to test functions
#ListAll()
CreateFromJob("TestJOb", "NewJob")
#puts GetBuildInfo("TestJOb", 1)
#puts GetConfig("TestJOb")
#puts GetInfo("TestJOb")
