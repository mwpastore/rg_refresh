# rg_refresh

Execute a VLAN "flop" to allow the AT&T Residential Gateway (RG) to perform
802.1x authentication via the Optical Network Terminal (ONT) before falling
back to the subscriber's "own" router/gateway hardware. The RG is toggled off
and on as needed via a remote-controlled power outlet (see below).

For more information about this procedure, please see brianlan's [original
document][1] on DSL Reports.

## Requirements

* [Netgear gigabit-speed "Smart Managed Plus" switch][2]. The following models
  are known to work:
  * GS108Ev2
  * GS105PE

  Please submit a PR if you confirm another working model.
* [MQTT broker][3] (like [this one][9])
* "Smart" outlet that can be remotely-controlled (i.e. set "on" or "off") via a
  message published to a MQTT bus. For example:
  * SmartThings Hub, Zigbee or Z-Wave outlet, and [MQTT bridge][4]
  * Z-Wave "stick" and outlet and [Home Assistant][5]
  * Z-Wave "stick" and outlet and [MQTT bridge][6] (or [this one][7])
  * Sonoff outlet flashed w/ [Tasmota][8] firmware
* Host (for the script) with:
  * Ruby interpreter
  * Access to the Netgear management console via HTTP
  * Access to the MQTT broker via TCP/IP

> N.B. With a SmartThings- or other cloud-based solution, an Internet
> connection is required to perform the VLAN flop, so if the operation fails
> (or is attempted after your router has already lost its DHCP lease), your
> network may get stuck in an inconsistent state. To recover, run the script
> and toggle the RG power manually as indicated.

## Installation

Follow the [guide][1] to establish the initial network environment, which
includes copying information from the RG to your own router. You should perform
the VLAN flop one time through by hand to make sure everything is set up and
working correctly. Jot down your VLAN IDs and port assignments for later.

Next, pick a server where the script will run and install it:

```console
$ gem install rg_refresh
```

Create a configuration file and write it somewhere sensible, e.g.
`/etc/rg_refresh.yml`, using the following template:

```yaml
---
:netgear:
  # Tip: Give your switch a static IP address or DNS name if possible.
  :address: 'http://a.b.c.d'
  :password: password
  :vlans:
    :rg: 2
    :my_router: 3
  :ports_vlans:
    # ONT is on switch port #1 in this example.
    # Put .<vlan> to reference above VLAN assignments.
    # Put ~ to preserve the port's current VLAN assignment; trailing ~ can be
    # omitted if desired.
    :reauth: [.rg, .rg, .my_router]
    :bypass: [.my_router, .rg, .my_router]
:mqtt:
  :client:
    # This section is passed to MQTT::Client.connect as-is.
    # https://www.rubydoc.info/gems/mqtt/MQTT/Client#instance_attr_details
    :host: localhost
    :port: 1883
  :topic: smartthings/RG/switch
  :messages:
    # Remember to quote YAML-reserved terms like "on" and "off".
    :reauth: 'on'
    :bypass: 'off'
```

Run the script to make sure it works correctly, passing in the path to the
configuration file created above. For example:

```console
$ rg_refresh -c /etc/rg_refresh.yml
```

Finally, schedule the script to run once a week or so, during off-hours,
and/or when your router loses its DHCP lease.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake test` to run the tests. You can also run `bin/console` for an interactive
prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release`, which will create a git tag for the version, push
git commits and tags, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/mwpastore/rg_refresh.

## License

The gem is available as open source under the terms of the [MIT
License](https://opensource.org/licenses/MIT).

[1]: http://www.dslreports.com/forum/r29903721-AT-T-Residential-Gateway-Bypass-True-bridge-mode
[2]: https://www.netgear.com/business/products/switches/web-managed/gigabit-web-managed-switch.aspx
[3]: https://github.com/mqtt/mqtt.github.io/wiki/servers
[4]: https://github.com/stjohnjohnson/smartthings-mqtt-bridge#readme
[5]: https://www.home-assistant.io/components/mqtt/
[6]: https://github.com/adpeace/zwave-mqtt-bridge#readme
[7]: https://github.com/ltoinel/ZWave2MQTT#readme
[8]: https://github.com/arendst/Sonoff-Tasmota/wiki/MQTT-Overview
[9]: https://github.com/mcollina/mosca#readme
