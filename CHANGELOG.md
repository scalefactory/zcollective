30/05/2018 - Update Gem dependencies to assure netaddr API v1

27/07/2017 - Add Zabbix Automatic Host Inventory support (`--auto-zabbix-inventory`)

01/11/2016 - Add support for SSL and --insecure-https

15/08/2016 - Fix issue with --http-timeout not accepting values and ensure value is an int before use.

11/08/2016 - Add --http-timeout argument to increase the HTTP timeout if API calls are slow.

27/06/2016 - Fix for missing facts array when host option used

12/04/2016 - Support for --hostgroup-facts added

14/09/2015 - 0.0.14 - Fix regression for pre-2.2 support.

11/09/2015 - 0.0.13 - Support changes in API from 2.2 onwards

25/09/2014 - Support for --ignore-classes added

08/09/2014 - Support for --host and --template switch for manual addition of hosts.

28/11/2013 - Support for --timeout and --lockfile added

23/08/2013 - ZCollective will now create hostgroups in zabbix based on collectives it's discovered; it will then assign hosts to these hostgroups, based on f
acts it's discovered via mcollective.
