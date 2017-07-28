Gem::Specification.new do |s|
    s.name        = 'zcollective'
    s.version     = '0.0.19'
    s.date        = '2017-07-28'
    s.summary     = 'Zabbix/MCollective integration'
    s.description = 'ZCollective is a tool used to configure Zabbix using data discovered using MCollective.'
    s.authors     = [ 'Jon Topper' ]
    s.email       = 'jon@scalefactory.com'
    s.files       = [
        'lib/zcollective/zabbixclient.rb',
        'bin/zcollective'
    ]
    s.add_runtime_dependency 'netaddr', '>= 1.5.0'
    s.executables << 'zcollective'
    s.homepage    = 'http://github.com/scalefactory/zcollective'
    s.require_path = 'lib'
end
