set :application, "capistrano-platform-resources"
set :repository,  "."
set :deploy_to do
  File.join("/home", user, application)
end
set :deploy_via, :copy
set :scm, :none
set :use_sudo, false
set :user, "vagrant"
set :password, "vagrant"
set :ssh_options, {:user_known_hosts_file => "/dev/null"}

role :web, "192.168.33.10"
role :app, "192.168.33.10"
role :db,  "192.168.33.10", :primary => true

$LOAD_PATH.push(File.expand_path("../../lib", File.dirname(__FILE__)))
require "capistrano/configuration/resources/platform_resources"

task(:test_all) {
  find_and_execute_task("test_default")
}

namespace(:test_default) {
  task(:default) {
    methods.grep(/^test_/).each do |m|
      send(m)
    end
  }
  before "test_default", "test_default:setup"
  after "test_default", "test_default:teardown"

  task(:setup) {
    platform.packages.try_update
    case platform_family
    when :debian
      set(:missing_packages, %w(mercurial))
    when :redhat
      set(:missing_packages, %w(mercurial))
    else
      set(:missing_packages, [])
    end
  }

  task(:teardown) {
    platform.packages.uninstall(missing_packages)
  }

  task(:test_installed) {
    platform.packages.uninstall(missing_packages)
    abort("packages must not be installed.") if platform.packages.installed?(missing_packages)
    platform.packages.install(missing_packages)
    abort("packages must be installed.") unless platform.packages.installed?(missing_packages)
    platform.packages.uninstall(missing_packages)
  }
}

# vim:set ft=ruby sw=2 ts=2 :
