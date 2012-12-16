metadata :name        => "zabbix_template",
         :description => "Zabbix Template Name discovery service",
         :author      => "Mike Griffiths",
         :license     => "(c)2012 The Scale Factory Ltd.",
         :version     => "0.1",
         :url         => "https://github.com/scalefactory/zcollective",
         :timeout     => 5

action "templates", :description => "Return Zabbix Template Aliases for this host" do
   display :always

   output :aliases,
          :description => "Template aliases for this host",
          :display_as  => "Message"
end
