# Cloudstats

Cloudstats pulls project and account statistics from the CloudStack API and feeds them into a Influxdb database.
Whit the help of Grafana this let's you craft beautiful usage dashboards.

## Installation

Install the gem as:

    $ gem install cloudstats

## Usage

Make sure you have a working [cloudstack_client](https://github.com/niwo/cloudstack_client) configuration file in your home directory.
Usually this is found under `~/.cloudstack.yml`

Install gem dependencies:

    $ bundle install

See the help for more options:

    $ bin/cloudstats help


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/niwo/cloudstats.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
