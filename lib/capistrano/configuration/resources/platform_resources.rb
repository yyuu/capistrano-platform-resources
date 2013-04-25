require "capistrano/configuration/resources/platform_resources/version"
require "capistrano/configuration"

module Capistrano
  class Configuration
    module Resources
      module PlatformResources
        def self.extended(configuration)
          configuration.load {
            namespace(:platform) {
              _cset(:platform_family) { platform.family(fetch(:platform_family_options, {})) }
              def family(options={})
                capture((<<-EOS).gsub(/\s+/, " "), options).strip.to_sym
                  if test -f /etc/debian_version; then
                    echo debian;
                  elif test -f /etc/redhat-release; then
                    echo redhat;
                  elif test -f /etc/system-release; then
                    echo redhat;
                  else
                    echo unknown;
                  fi;
                EOS
              end

              _cset(:platform_lsb_packages) {
                case platform_family
                when :debian
                  %w(lsb-release lsb-core)
                when :redhat
                  %w(redhat-lsb)
                else
                  []
                end
              }

              def lsb_setup(options={})
                if fetch(:platform_setup, false)
                  false
                else
                  lsb_setup!(options)
                  set(:platform_setup, true)
                  true
                end
              end

              def lsb_setup!(options={})
                platform.packages.install(platform_lsb_packages, options)
              end

              _cset(:platform_identifier) { platform.identifier(fetch(:platform_identifier_options, {})) }
              def identifier(options={})
                options = options.dup
                options.delete(:family) # for backward compatibility
                lsb_identifier(options)
              end

              def lsb_identifier(options={})
                lsb_setup(options)
                identifier = capture("lsb_release --id --short || true", options).strip.downcase
                not(codename.empty?) ? identifier.to_sym : :unknown
              end

              _cset(:platform_release) { platform.release(fetch(:platform_release_options, {})) }
              def release(options={})
                options = options.dup
                options.delete(:family) # for backward compatibility
                lsb_release(options)
              end

              def lsb_release(options={})
                lsb_setup(options)
                release = capture("lsb_release --release --short || true", options).strip.downcase
                not(release.empty?) ? release.to_sym : :unknown
              end

              _cset(:platform_codename) { platform.codename(fetch(:platform_codename_options, {})) }
              def codename(options={})
                options = options.dup
                options.delete(:family) # for backward compatibility
                lsb_codename(options)
              end

              def lsb_codename(options={})
                lsb_setup(options)
                codename = capture("lsb_release --codename --short || true", options).strip.downcase
                not(codename.empty?) ? codename.to_sym : :unknown
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
                  options = options.dup
                  packages = [ packages ].flatten
                  family = ( options.delete(:family) || fetch(:platform_family) )
                  if packages.empty?
                    true
                  else
                    not /not-installed/ =~ case family
                      when :debian
                        capture("dpkg-query -s #{packages.map { |x| x.dump }.join(" ")} 1>/dev/null 2>&1 || echo not-installed")
                      when :redhat
                        capture("rpm -qi #{packages.map { |x| x.dump }.join(" ")} 1>/dev/null 2>&1 || echo not-installed")
                      end
                  end
                end

                def install(packages=[], options={})
                  if installed?(packages, options)
                    false
                  else
                    install!(packages, options)
                  end
                end

                def install!(packages=[], options={})
                  update(options)
                  options = options.dup
                  packages = [ packages ].flatten
                  family = ( options.delete(:family) || fetch(:platform_family) )
                  unless packages.empty?
                    case family
                    when :debian
                      sudo("apt-get install -q -y #{packages.map { |x| x.dump }.join(" ")}", options)
                    when :redhat
                      sudo("yum install -q -y #{packages.map { |x| x.dump }.join(" ")}", options)
                    end
                  end
                end

                def uninstall(packages=[], options={})
                  if installed?(packages, options)
                    uninstall!(packages, options)
                  else
                    false
                  end
                end

                def uninstall!(packages=[], options={})
                  options = options.dup
                  packages = [ packages ].flatten
                  family = ( options.delete(:family) || fetch(:platform_family) )
                  unless packages.empty?
                    case family
                    when :debian
                      sudo("apt-get purge -q -y #{packages.map { |x| x.dump }.join(" ")}", options)
                    when :redhat
                      sudo("yum remove -q -y #{packages.map { |x| x.dump }.join(" ")}", options)
                    end
                  end
                end

                def update(options={})
                  if fetch(:platform_packages_updated, false)
                    false
                  else
                    update!(options)
                    set(:platform_packages_updated, true)
                    true
                  end
                end
                alias try_update update # for backward compatibility before 0.1.2

                def update!(options={})
                  options = options.dup
                  family = ( options.delete(:family) || fetch(:platform_family) )
                  case family
                  when :debian
                    sudo("apt-get update -q -y", options)
                  when :redhat
                    sudo("yum check-update -q -y || true", options)
                  end
                end

                def upgrade(options={})
                  if fetch(:platform_packages_upgraded, false)
                    false
                  else
                    upgrade!(options)
                    set(:platform_packages_upgraded, true)
                    true
                  end
                end

                def upgrade!(options={})
                  update(options)
                  options = options.dup
                  family = ( options.delete(:family) || fetch(:platform_family) )
                  case family
                  when :debian
                    sudo("apt-get upgrade -q -y", options)
                  when :redhat
                    sudo("yum upgrade -q -y", options)
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
