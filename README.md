# Varnish Metrics Collector

A small ruby cli for collecting varnish metrics of a remote varnish instance. It uses ssh to connect to the varnish instance, gets the metrics and formats them depending on the desired output.

## Basic Usage
    $ ./get_varnish_metrics.rb --instance 10.10.10.10 --output text

## Prerequisites

You'll need to have ruby 2.x installed on your system.
If you havent installed bundler install it with `gem install bundler`.
Then run `bundle install`. This will install all libraries needed for the script, for example `nokogiri` and others.

## Assumptions
When developing this script I made the following assumptions:
* The varnish server is reachable via `ssh` on Port 22
* The server user has access to `varnishadm` and `varnishstat`

So if you are able to login to your server via `$ ssh <user>@xxx.xxx.xxx.xxx` and successfully run `varnishadm` and `varnishstat` from the commandline, this script should work too.

## Options

### instance
`--instance HOST` or `-i HOST`, where `HOST` is an ip-address or FQDN

### user

`--user USER` or `-u USER`, defaults to `text`

### output

`--output FORMAT` or `-o FORMAT`, defaults to `text`

You can use any of the following: text, yaml, json, json-pretty, xml

#### Examples:
##### text (default)
    $ ./get_varnish_metrics.rb -i 134.119.24.235

    cachesize=256.0MB
    cache_filling=6.86KB
    cache_hit_rate=83.12%
    backend_server_server1=healthy
    backend_server_server2=healthy
    backend_server_server3=healthy

##### yaml
    $ ./get_varnish_metrics.rb -i 134.119.24.235 -o yaml

    ---
    cache_hit_rate: 83.12%
    cache_filling: 6.86KB
    cachesize: 256.0MB
    backends:
    - name: boot.server1
      state: Healthy
    - name: boot.server2
      state: Healthy
    - name: boot.server3
      state: Healthy

##### json
    $ ./get_varnish_metrics.rb -i 134.119.24.235 -o json
    {"cache_hit_rate":"83.12%","cache_filling":"6.86KB","cachesize":"256.0MB","backends":[{"name":"boot.server1","state":"Healthy"},{"name":"boot.server2","state":"Healthy"},{"name":"boot.server3","state":"Healthy"}]}

##### json-pretty
    $ ./get_varnish_metrics.rb -i 134.119.24.235 -o json-pretty

    {
      "cache_hit_rate": "83.12%",
      "cache_filling": "6.86KB",
      "cachesize": "256.0MB",
      "backends": [
        {
          "name": "boot.server1",
          "state": "Healthy"
        },
        {
          "name": "boot.server2",
          "state": "Healthy"
        },
        {
          "name": "boot.server3",
          "state": "Healthy"
        }
      ]
    }

##### xml
    $ ./get_varnish_metrics.rb -i 134.119.24.235 -o xml

    <?xml version="1.0"?>
    <metric>
      <cachesize>256.0MB</cachesize>
      <cache-filling>6.86KB</cache-filling>
      <cache-hit-rate>83.12%</cache-hit-rate>
      <backends>
        <backend>
          <name>boot.server1</name>
          <state>healthy</state>
        </backend>
        <backend>
          <name>boot.server2</name>
          <state>healthy</state>
        </backend>
        <backend>
          <name>boot.server3</name>
          <state>healthy</state>
        </backend>
      </backends>
    </metric>

### help
    $ ./get_varnish_metrics.rb help get_metrics
