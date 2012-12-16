module MCollective
    module Agent
        class Zabbix_template<RPC::Agent

            action "templates" do

                template_alias_dir = '/etc/zabbix/template_aliases/'

                aliases = Hash.new
                Dir.foreach(template_alias_dir) { |f|
                    next if f == '.'
                    next if f == '..'
                    aliases[f] = File.read("#{template_alias_dir}/#{f}").chomp
                }

                reply[:aliases] = aliases

            end
        end
    end
end
