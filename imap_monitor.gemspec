$:.push File.expand_path('../lib', __FILE__)
require 'imap_monitor/version'

Gem::Specification.new do |gm|
  gm.name        = "imap_monitor"
  gm.version     = ImapMonitor::VERSION
  gm.platform    = Gem::Platform::RUBY
  gm.authors     = ["Jon Normington"]
  gm.email       =  ""
  gm.homepage    = "https://github.com/jnormington/imap-monitor"
  gm.summary     = "Imap monitor for measure time on receiving a count of emails"
  gm.description = [gm.summary, "which allows user a matcher filtering emails monitoring count and time broken down."].join(' ')

  gm.add_runtime_dependency '',''
  gm.add_development_dependency 'rspec', '~> 3.3.0'

  gm.files         = `git ls-files`.split("\n")
  gm.test_files    = `git ls-files -- spec/*`.split("\n")
  gm.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gm.require_paths = ['lib']
end
