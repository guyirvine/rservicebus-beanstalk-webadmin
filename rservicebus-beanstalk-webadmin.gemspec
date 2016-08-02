Gem::Specification.new do |s|
  s.name        = 'rservicebus-beanstalk-webadmin'
  s.version     = '0.0.4'
  s.date        = '2016-08-02'
  s.summary     = 'rservicebus-beanstalk-webadmin'
  s.description = 'A web based admin interface for beanstalk, targeted at rservicebus users.'
  s.authors     = ['Guy Irvine']
  s.email       = 'guy@guyirvine.com'
  s.files       = Dir['{lib}/**/*.rb', 'public/*', 'bin/*', 'LICENSE', '*.md']
  s.homepage    = 'http://rubygems.org/gems/rservicebus-beanstalk-webadmin'
  s.license     = 'LGPL-3.0'
  s.executables << 'rservicebus-beanstalk-webadmin'
end
