# ZCollective

ZCollective is a tool used to configure Zabbix using data discovered using MCollective.

At [The Scale Factory](http://www.scalefactory.com/), we've used Zabbix for monitoring for some time.  Our main complaint with this software has been that configuration has always been a bit too GUI-focussed.  This has been addressed in recent releases with an improvement in the functionality exposed via the API.

We've written ZCollective to remove some of the GUI legwork required in configuring monitoring for individual hosts - we think it's a cleaner alternative to Zabbix host discovery.

## How does it work?

First of all, ZCollective connects to the Zabbix API to fetch a list of templates that Zabbix knows about.  These have been constructed in the usual way inside the Zabbix UI, and given the same name as the configuration management class they support.

It then pulls a list of hosts, interfaces and templates for each host configured in Zabbix.

Then it uses MCollective to build a view of the hosts on your infrastructure.  For each host, it fetches a name, some IP address details and a list of configuration management classes associated with the node.

Hosts that are found by MCollective but are not monitored will be added to Zabbix, and linked to any templates that match configuration management class names.  Double-colons are substituted for underscores when matching configuration management class names to template names.

Hosts found in Zabbix but not by MCollective are left alone, but reported on.

Hosts found in both Zabbix and MCollective will be linked to any missing templates.  IP address mismatches for the hostname are reported on, but no changes are made.

## Template Aliasing and Extra Templates

Optionally, ZCollective can use the ```zabbix_template``` MCollective plugin to interrogate each host for a list of alternative and extra templates to use for configuration management classes installed on that host.

Aliasing can be very useful, for example, to use a different template on a specific host, if it is a replication master rather than a slave. It can also be handy, if you have a class that is installed on every host, to use that to ensure the ```Template OS Linux``` Zabbix template is linked to that host by ZCollective.

To configure a template alias on a host, put a file in ```/etc/zabbix/template_aliases/``` named after the configuration management class you wish to be aliased. That file should contain a single line, which is the name of the Zabbix template that should be used instead.

For example, we have a ```scalefactory::packages``` Puppet module which is installed on all of our hosts. In that module, we write out a file ```/etc/zabbix/template_aliases/scalefactory_packages``` which contains the text ```Template OS Linux```. This ensures that this standard Zabbix template is linked to all hosts.

To specify extra templates to be linked to the host for a given module, put a file in ```/etc/zabbix/template_extras/``` named after the configuration management class. Add extra templates, one per line, to this file.

This can be useful to add monitoring for optional features of a configuration management class. For example, our Apache puppet module contains a Zabbix template which monitors port 80 by default. If SSL is turned on, we use this extra template feature to ensure that checks are also made for Apache listening on port 443.

Use of the ```zabbix_template``` plugin is completely optional, and ZCollective will work perfectly without it.

## Hostgroups based on collectives

Any subcollectives declared in mcollective's client.cfg will be added as hostgroups to zabbix; the machines discovered via mcollective will be assigned to these hostgroups.


## Usage

```
Usage: zcollective [options]
        --zabbix-api-url url         JSON-RPC endpoint for zabbix server
        --zabbix-user user           Zabbix API username
        --zabbix-pass pass           Zabbix API password
        --debug                      Enable debugging
        --noop                       Don't make changes
        --interface-cidr CIDR        Only consider interfaces matching the given CIDR
        --connect-by-ip              When adding new hosts, get Zabbix to connect to those hosts by
                                     IP address instead of hostname. Useful in scenarios where you
                                     don't have control over your DNS.
        --lockfile=f                 Use alternative lock file
        --timeout=t                  Time out after number of seconds
        --host host                  Ignore mcollective discovery, use this host
        --template template          Add this template (only with --host)
        --ignore-classes c1,c2       Skip hosts containing given puppet classes
```

The URL, username and password options are self-explanatory.

```--interface-cidr```, if passed will filter the interfaces MCollective finds by CIDR range.  This is useful for multihomed hosts where you only want to monitor the interface on an administrative network.

```--debug``` will generate a lot of console noise, but helps with working out what's going on.

Passing ```--noop``` will report on the changes to be made, but not make any.

Using ```--host``` allows you to add a host outside of the scope of mcollective, for example an Amazon RDS or Elasticache instance, to Zabbix. Passing the ```--template``` switch at the same time will add a template to that host in Zabbix. When using the ```--host``` option, the given host will be added to the "ZCollective Discovered Hosts" hostgroup only.


## Example

A run against a fresh Zabbix install on a modest infrastructure, using the default username/password:

```
$ ./zcollective.rb --zabbix-api-url http://zabbix/zabbix/api_jsonrpc.php --interface-cidr 10.0.44.0/24 
I, [2012-11-21T16:43:32.899696 #8727]  INFO -- : Host ljn-live-db2 found by mcollective but not in zabbix
I, [2012-11-21T16:43:32.986700 #8727]  INFO -- : Host ljn-live-db2 added as ID 100100000010157 with 1 templates
I, [2012-11-21T16:43:32.986854 #8727]  INFO -- : Host ljn-live-db1 found by mcollective but not in zabbix
I, [2012-11-21T16:43:33.103230 #8727]  INFO -- : Host ljn-live-db1 added as ID 100100000010158 with 1 templates
I, [2012-11-21T16:43:33.103389 #8727]  INFO -- : Host ljn-core2 found by mcollective but not in zabbix
I, [2012-11-21T16:43:33.456250 #8727]  INFO -- : Host ljn-core2 added as ID 100100000010159 with 5 templates
I, [2012-11-21T16:43:33.456342 #8727]  INFO -- : Host ljn-core1 found by mcollective but not in zabbix
I, [2012-11-21T16:43:33.823787 #8727]  INFO -- : Host ljn-core1 added as ID 100100000010160 with 5 templates
I, [2012-11-21T16:43:33.823875 #8727]  INFO -- : Host ljn-log1 found by mcollective but not in zabbix
I, [2012-11-21T16:43:33.997864 #8727]  INFO -- : Host ljn-log1 added as ID 100100000010161 with 2 templates
I, [2012-11-21T16:43:33.998029 #8727]  INFO -- : Host ljn-live-app2 found by mcollective but not in zabbix
I, [2012-11-21T16:43:34.316868 #8727]  INFO -- : Host ljn-live-app2 added as ID 100100000010162 with 4 templates
I, [2012-11-21T16:43:34.317034 #8727]  INFO -- : Host ljn-live-app1 found by mcollective but not in zabbix
I, [2012-11-21T16:43:34.654262 #8727]  INFO -- : Host ljn-live-app1 added as ID 100100000010163 with 4 templates
```

A second run against the same infrastructure returns nothing on the commandline, as nothing is modified.

If we remove a couple of templates from ljn-live-app1 and run again:

```
$ ./zcollective.rb --zabbix-api-url http://zabbix/zabbix/api_jsonrpc.php --interface-cidr 10.0.44.0/24 
I, [2012-11-21T16:48:59.915380 #10272]  INFO -- : Zabbix ljn-live-app1 not linked to a template for sf_varnish
I, [2012-11-21T16:48:59.915588 #10272]  INFO -- : Zabbix ljn-live-app1 not linked to a template for sf_apache
I, [2012-11-21T16:49:00.184213 #10272]  INFO -- : Added missing templates to ljn-live-app1
```
## Caveats

Beware of running zcollective against puppet runs implemented using the 'puppet apply' runmode: due to a known issue/bug in puppet (http://projects.puppetlabs.com/issues/7917),
the classes.txt file, which mcollective (and by extention zcollective) uses to classify machines, isn't written. Only use zcollective on infrastructures where you're using
the 'puppet agent' runmode, or find another way to populate classes.txt (eg using the `--write-catalog-summary` switch in new versions of puppet) so that mcollective can correctly classify your nodes.

When using ```--host```, the IP address for that host's interface in Zabbix will not be populated. This is because in many contexts for the expected use case, eg. Amazon RDS and Elasticache instances, the IP address is variable and the DNS end point name should always be used. As such, the ```--connect-by-ip``` option is not valid when using ```--host```.

## Assumptions

Because we wrote this to scratch our own itch, we've made assumptions that may only hold for a Scale Factory zabbix setup.

We assume that your Zabbix hosts are named the same as the hostname of the monitored server - so ```ljn-live-web1.scalefactory.net``` will be referred to as ```ljn-live-web1``` by Zabbix.

## Requirements

You need to be runing Zabbix >=2.0,  MCollective >=2.2, and Facter >=1.6.14.  You'll also need the netaddr Ruby Gem.

## "Missing features"

ZCollective currently doesn't know how to cope with hosts that are only visible to Zabbix via a proxy.

Giving a password on the commandline isn't very secure.

ZCollective has only been tested against a small number of use cases - use it at your own risk.

## Changelog

14/09/2015 - 0.0.14 - Fix regression for pre-2.2 support.

11/09/2015 - 0.0.13 - Support changes in API from 2.2 onwards

25/09/2014 - Support for --ignore-classes added

08/09/2014 - Support for --host and --template switch for manual addition of hosts.

28/11/2013 - Support for --timeout and --lockfile added

23/08/2013 - ZCollective will now create hostgroups in zabbix based on collectives it's discovered; it will then assign hosts to these hostgroups, based on facts it's discovered via mcollective. 


## License

ZCollective, and the ```zabbix_template``` mcollective plugin, are both BSD licensed.
