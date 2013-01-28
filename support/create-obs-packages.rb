#!/usr/bin/env ruby

# This is a really nasty script to make generating OBS packages from
#  the gem more straightforward.  You probably won't need it.

require 'fileutils'

@gemfile = ARGV[0] or raise "Give a gemfile"

filename = File.basename(@gemfile)
if ( filename =~ /^(.+)-([0-9\.]+)\.gem/ )
    @gemname    = $1
    @gemversion = $2
else
    raise "Gem filename doesn't match expected pattern"
end

def create_debian_package

    dir = "#{@gemfile}_debian"

    if File.directory? dir
        raise "Debian directory already exists"
    end

    Dir.mkdir(dir)
    FileUtils.cp(@gemfile, "#{dir}/#{@gemfile}")
    Dir.chdir(dir) do

        system("gem2deb #{@gemfile}")

        control_file = "ruby-#{@gemname}-#{@gemversion}/debian/control"

        # Munge the stupid dependencies lines

        parse_mode = 0
        saved_line = nil
        new_control = []

        File.open(control_file).each do |line|

            line.chomp!

            case parse_mode
                when 0
                    if line =~ /^Depends: /
                        parse_mode = 1
                        saved_line = line
                    else
                        new_control.push( line )
                    end
                when 1
                    if line =~ /^# (.+) (.+)$/
                        saved_line = "#{saved_line}, ruby-#{$1} #{$2}"
                    elsif line =~ /^[^#]/
                        new_control.push( saved_line )
                        new_control.push( line )
                        parse_mode = 0
                    end
            end

        end

        File.open(control_file, 'w') do |file|
            file.puts new_control.join("\n")
        end

        Dir.chdir("ruby-#{@gemname}-#{@gemversion}") do
            system("dpkg-buildpackage")
        end

    end

end

def create_redhat_package

    dir = "#{@gemfile}_redhat"

    if File.directory? dir
        raise "RedHat directory already exists"
    end

    Dir.mkdir(dir)
    FileUtils.cp(@gemfile, "#{dir}/#{@gemfile}")
    Dir.chdir(dir) do

        file = open("rubygem-#{@gemname}.spec",'w')

        output = open("|gem2rpm #{@gemfile}")
        output.readlines.each do |line|

            next if line =~ /^Source1:/

            line.gsub!('ruby-gems-%{rbname}', 'rubygem-%{rbname}')
            line.gsub!('ruby-gems >= 1.8.15', 'rubygems >= 1.3.7')
            line.gsub!('Requires: ruby-gems', 'Requires: rubygem')
            line.gsub!('%define gemdir /var/lib/gems/1.8', '%define gemdir /usr/lib/ruby/gems/1.8')

            file.write line

        end

        file.close
    end

end

def copy_files_for_build

    dir = "#{@gemfile}_osc"

    if File.directory? dir
        raise "OSC directory already exists"
    end

    Dir.mkdir(dir)

    FileUtils.cp("#{@gemfile}_redhat/rubygem-#{@gemname}.spec", dir)
    FileUtils.cp(@gemfile, dir)
    FileUtils.cp("#{@gemfile}_debian/ruby-#{@gemname}_#{@gemversion}-1.debian.tar.gz", dir)
    FileUtils.cp("#{@gemfile}_debian/ruby-#{@gemname}_#{@gemversion}-1.dsc", dir)
    FileUtils.cp("#{@gemfile}_debian/#{@gemname}-#{@gemversion}.tar.gz", "#{dir}/ruby-#{@gemname}_#{@gemversion}.orig.tar.gz")
 

end

create_debian_package
create_redhat_package
copy_files_for_build
