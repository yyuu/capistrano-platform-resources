require "capistrano/configuration/resources/platform_resources/version"
require "capistrano/configuration"

module Capistrano
  class Configuration
    module Resources
      module PlatformResources
        def self.extended(configuration)
          configuration.load {
            namespace(:platform) {
              _cset(:platform_identifier) { platform.identifier(fetch(:platform_identifier_options, {})) }
              def identifier(options={})
                capture((<<-EOS).gsub(/\s+/, " "), options).strip.to_sym
                  if test -f /etc/debian_version; then
                    if test -f /etc/lsb-release && grep -i -q DISTRIB_ID=Ubuntu /etc/lsb-release; then
                      echo ubuntu;
                    else
                      echo debian;
                    fi;
                  elif test -f /etc/redhat-release; then
                    if test -f /etc/centos-release; then
                      echo centos;
                    else
                      echo redhat;
                    fi;
                  else
                    echo unknown;
                  fi;
                EOS
              end

              _cset(:platform_architecture) { platform.architecture(fetch(:platform_architecture_options, {})) }
              def architecture(options={})
                arch = capture("uname -m", options).strip.to_sym
                case arch
                when /^(i[3-6]86|pentium)$/ then :i386
                when /^(amd64|x86_64)$/     then :x86_64
                else
                  arch.to_sym
                end
              end

              namespace(:packages) {
                def installed?(packages=[], options={})
                  packages = [ packages ].flatten
                  identifier = ( options.delete(:identifier) || fetch(:platform_identifier) )
                  if packages.empty?
                    true
                  else
                    !/not-installed/i =~ case identifier
                      when :debian, :ubuntu
                        capture("dpkg-query -s #{packages.map { |x| x.dump }.join(" ")} 1>/dev/null 2>&1 || echo not-installed")
                      when :centos, :redhat
                        capture("rpm -qi #{packages.map { |x| x.dump }.join(" ")} 1>/dev/null 2>&1 || echo not-installed")
                      end
                  end
                end

                def install(packages=[], options={})
                  packages = [ packages ].flatten
                  identifier = ( options.delete(:identifier) || fetch(:platform_identifier) )
                  unless packages.empty?
                    case identifier
                    when :debian, :ubuntu
                      sudo("apt-get install -q -y #{packages.map { |x| x.dump }.join(" ")}", options)
                    when :centos, :redhat
                      sudo("yum install -q -y #{packages.map { |x| x.dump }.join(" ")}", options)
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
