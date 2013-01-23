# Copyright (c) 2012, 2013, The Scale Factory Ltd.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#   * Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
#   * Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
#   * Neither the name of the The Scale Factory Ltd nor the
#     names of its contributors may be used to endorse or promote products
#     derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
# THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

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
