metadata :name        => "zabbix_template",
         :description => "Zabbix Template Name discovery service",
         :author      => "The Scale Factory Ltd",
         :license     => "BSD",
         :version     => "0.1",
         :url         => "https://github.com/scalefactory/zcollective",
         :timeout     => 5

action "templates", :description => "Return Zabbix Template Aliases and Extras for this host" do
    display :always

    output :aliases,
           :description => "Template aliases for this host",
           :display_as  => "Message"

    output :extras,
           :description => "Extra templates for this host",
           :display_as  => "Message"

end
