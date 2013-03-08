require "capistrano/configuration/resources/platform_resources/version"
require "capistrano/configuration"

module Capistrano
  class Configuration
    module Resources
      module PlatformResources
        def self.extended(configuration)
          configuration.load {
            namespace(:platform) {
              def identifier(options={})
                capture((<<-EOS).gsub(/\s+/, " "), options).strip
                  if test -f /etc/debian_version; then
                    if test -f /etc/lsb-release && grep -i -q DISTRIB_ID=Ubuntu /etc/lsb-release; then
                      echo ubuntu;
                    else
                      echo debian;
                    fi;
                  elif test -f /etc/redhat-release; then
                    echo redhat;
                  else
                    echo unknown;
                  fi;
                EOS
              end

              def architecture(options={})
                arch = capture("uname -m", options).strip
                case arch
                when /^(i[3-6]86|pentium)$/ then "i386"
                when /^(amd64|x86_64)$/     then "x86_64"
                else
                  arch
                end
              end

              namespace(:packages) {
                def installed?(packages=[], options={})
                  packages = [ packages ].flatten
                  identifier = options.delete(:identifier)
                  identifier = top.platform.identifier(options) unless identifier
                  if packages.empty?
                    true
                  else
                    status = case identifier
                      when /(debian|ubuntu)/i
                        capture("dpkg-query -s #{packages.map { |x| x.dump }.join(" ")} 1>/dev/null 2>&1 || echo not-installed")
                      when /redhat/i
                        capture("rpm -qi #{packages.map { |x| x.dump }.join(" ")} 1>/dev/null 2>&1 || echo not-installed")
                      end
                    not(/not-installed/i =~ status)
                  end
                end

                def install(packages=[], options={})
                  packages = [ packages ].flatten
                  identifier = options.delete(:identifier)
                  identifier = top.platform.identifier(options) unless identifier
                  unless packages.empty?
                    case identifier
                    when /(debian|ubuntu)/i
                      run("#{sudo} apt-get install -q -y #{packages.map { |x| x.dump }.join(" ")}", options)
                    when /redhat/i
                      run("#{sudo} yum install -q -y #{packages.map { |x| x.dump }.join(" ")}", options)
                    end
                  end
                end
              }
            }
          }
        end
      end
    end
  end
end

if Capistrano::Configuration.instance
  Capistrano::Configuration.instance.extend(Capistrano::Configuration::Resources::PlatformResources)
end

# vim:set ft=ruby sw=2 ts=2 :
