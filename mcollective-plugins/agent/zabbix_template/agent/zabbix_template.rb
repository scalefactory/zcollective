# Copyright 2012 The Scale Factory Limited. All rights reserved.

module MCollective
    module Agent
        class Zabbix_template<RPC::Agent

            action "templates" do

                # Define the directories where we'll find the aliases and
                # extras files

                template_alias_dir  = '/etc/zabbix/template_aliases/'
                template_extras_dir = '/etc/zabbix/template_extras/'



                # Go through all non-zero-byte files in the alias dir and get
                # the entire contents of those files (will only be one line)
                # into a hash, keys are the filenames (puppet module names),
                # values are the templates to be used instead.

                aliases = Hash.new
                Dir.foreach(template_alias_dir) { |f|
                    next if f == '.'
                    next if f == '..'
                    next if File.zero?("#{template_alias_dir}/#{f}")
                    aliases[f] = File.read("#{template_alias_dir}/#{f}").chomp
                }

                reply[:aliases] = aliases



                # Now go through all non-zero-byte files in the extras dir
                # and create a comma separated list of all the entries in
                # each file - there may be multiple entries in this case.
                # Return a hash, keys again module names, values are this
                # comma separated list of extra templates to be linked.

                extras = Hash.new
                Dir.foreach(template_extras_dir) { |f|
                    next if f == '.'
                    next if f == '..'
                    next if File.zero?("#{template_extras_dir}/#{f}")
                    extra_templates = []
                    File.open("#{template_extras_dir}/#{f}") { |ef|
                        ef.each_line do |line|
                            extra_templates << line.chomp
                        end
                    }
                    extras[f] = extra_templates.join(',')
                }

                reply[:extras] = extras

            end

        end
    end
end
