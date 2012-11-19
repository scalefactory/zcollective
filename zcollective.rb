#!/usr/bin/env ruby

require 'optparse'
require 'logger'
require 'mcollective'

$:.push( File.join( File.dirname(__FILE__), 'lib' ) )
require 'zabbixclient'

options = {}
optparse = OptionParser.new do |opts|

    options[:zabbix_api_url] = 'http://localhost/zabbix/api_jsonrpc.php'
    opts.on('z', '--zabbix-api-url url', 'JSON-RPC endpoint for zabbix server') do |u|
        options[:zabbix_api_url] = u
    end

    options[:zabbix_user] = 'Admin'
    opts.on('u', '--zabbix-user user', 'Zabbix API username') do |u|
        options[:zabbix_user] = u
    end

    options[:zabbix_pass] = 'zabbix'
    opts.on('p', '--zabbix-pass pass', 'Zabbix API password') do |p|
        options[:zabbix_pass] = p
    end

    options[:debug] = false
    opts.on('d', '--debug', 'Enable debugging') do
        options[:debug] = true
    end

    options[:noop] = false
    opts.on('n', '--noop', 'Don\'t make changes') do
        options[:noop] = true
    end

end

begin

    optparse.parse!

rescue OptionParser::InvalidOption, OptionParser::MissingArgument

    $stderr.puts $!.to_s
    $stderr.puts optparse
    exit 2

end

log = Logger.new(STDERR)

if options[:debug]
    log.level = Logger::DEBUG
else
    log.level = Logger::WARN
end
log.info( "Connecting to Zabbix RPC service" )

zabbix_client = ZabbixClient.new(
    :url      => options[:zabbix_api_url],
    :user     => options[:zabbix_user],
    :password => options[:zabbix_pass]
)

log.info( "Connected and authenticated" )

############################################################################
# Fetch list of zabbix templates

log.info( "Fetching list of zabbix templates" )

zabbix_templates = {}

zabbix_client.request( 'template.get', 
    'search' => '', 
    'output' => 'extend' 
).each do |template|

    log.info( "\tName: #{template['name']} ID: #{template['templateid']}" )
    zabbix_templates[ template['name'] ] = template['templateid']

end

# We're going to build a big nasty hash of zabbix and mcollective data
# because apparently I still think like a Perl engineer.  It seems this
# dirty bit of Ruby is necessary to allow them to be anonymously built.
#
nested_hash = lambda {|hash, key| hash[key] = Hash.new(&nested_hash)}
hosts = Hash.new(&nested_hash)


############################################################################
# Iterate through zabbix hosts

zabbix_client.request( 'host.get', 
    'search' => '', 
    'output' => 'extend' 
).each do |host|

    log.info( "Host: #{host['name']}, ID: #{host['hostid']}" )

    # Iterate through hostinterfaces, looking for zabbix agent type
    #  interfaces.

    zabbix_client.request( 'hostinterface.get',
        'hostids' => host['hostid'], 
        'output'  => 'extend'
    ).each do |interface|

        next unless interface['type'] == "1" # skip non-Zabbix agent interfaces

        log.info( "\tIP: #{interface['ip']}" )
        hosts[ host['name'] ][:zabbix][:ip] = interface['ip']

    end

    hosts[ host['name'] ][:zabbix][:hostid]    = host['hostid']
    hosts[ host['name'] ][:zabbix][:templates] = []

    # Iterate through this host's templates

    zabbix_client.request(
        'template.get',
        'search'  => '',
        'output'  => 'extend',
        'hostids' => host['hostid']
    ).each do |template|

        log.info( "\tTemplate: #{template['name']}" )
        hosts[ host['name'] ][:zabbix][:templates].push( template['name'] )

    end

end

############################################################################
# Iterate through MCollective hosts

include MCollective::RPC

mc = rpcclient("rpcutil")
mc.progress = false

mc.discover.sort.each do |host|

    log.info("Host: #{host}")

    # Get inventory details for each host
    inventory = mc.custom_request( "inventory", {}, host,
        { "identity" => host }
    ).first

    log.info("\tIP #{inventory[:data][:facts]['ipaddress']}")

    hosts[ host ][:mcollective][:ip]      = inventory[:data][:facts]['ipaddress']
    hosts[ host ][:mcollective][:classes] = inventory[:data][:classes]

end

mc.disconnect

############################################################################
# Rationalise the two datasets

hosts.each do |host,data|

    if data.has_key?(:mcollective) and !data.has_key?(:zabbix)

        log.info( "Host #{host} found by mcollective but not in zabbix" )

    end

    if data.has_key?(:zabbix) and !data.has_key?(:mcollective)

        log.info( "Host #{host} found in zabbix but not by mcollective" )

    end

    if data.has_key?(:zabbix) and data.has_key?(:mcollective)

        log.info( "Host #{host} in both zabbix and mcollective" )

    end

end
