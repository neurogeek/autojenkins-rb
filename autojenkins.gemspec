Gem::Specification.new do |s|
  s.name        = 'autojenkins'
  s.version     = '0.1'
  s.date        = '2012-06-01'
  s.summary     = "Library to remotely control Jenkins CI"
  s.description = "Library to remotely control Jenkins CI. Autojenkins can fetch, create, enable/disable and launch jobs in Jenkins"
  s.authors     = ["Jesus Rivero"]
  s.email       = 'jesus.riveroa@gmail.com'
  s.files       = ["lib/autojenkins.rb",
                   "lib/test.rb"]
  s.license     = "MIT"
  s.executables = ["mjenk"]
  s.requirements = ["nokogiri", "json"]
end
