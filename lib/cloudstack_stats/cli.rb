require "thor"
require "cloudstack_stats/version"
require "cloudstack_stats/collect"
require "cloudstack_stats/feed"

module CloudstackStats
  class Cli < Thor
    include Thor::Actions

    package_name "cloudstack_stats"

    class_option :cloudstack_url,
      default: "http://localhost:8080/client",
      aliases: '-A',
      desc: 'CloudStack API URL'

    class_option :cloudstack_api_key,
      aliases: '-k',
      desc: 'CloudStack API Key'

    class_option :cloudstack_api_secret,
      aliases: '-s',
      desc: 'CloudStack API Secret'

    class_option :cloudstack_config,
      default: File.join(Dir.home, '.cloudstack-cli.yml'),
      aliases: '-C',
      desc: 'Location of your cloudstack-cli configuration file'

    class_option :env,
      aliases: '-E',
      desc: 'cloudstack-cli environment to use'

    class_option :influx_url,
      default: "http://localhost:8086/",
      aliases: '-U',
      desc: 'Influxdb URL'

    class_option :influx_user,
      default: "cloudstack-stats",
      aliases: '-u',
      desc: 'Influxdb user'

    class_option :influx_password,
      aliases: '-p',
      desc: 'Influxdb password'

    class_option :database,
      default: "cloudstack-stats",
      aliases: '-D',
      desc: 'Influxdb database'

    class_option :debug,
      aliases: '-D',
      desc: 'Enable debug output',
      type: :boolean,
      default: false

    # catch control-c and exit
    trap("SIGINT") do
      puts
      puts "exiting.."
      exit!
    end

    # exit with return code 1 in case of a error
    def self.exit_on_failure?
      true
    end

    desc "version", "Print version number"
    def version
      say "cloudstack_stats v#{CloudstackStats::VERSION}"
    end
    map %w(-v --version) => :version

    desc "projects", "Pull projects stats from CloudStack."
    option :domain,
      desc: "Name of Domain (for recursive search)",
      default: "ROOT"
    def projects
      say "Collect stats...", :yellow
      stats = Collect.new(options).project_stats
      say "Write stats to influxdb...", :yellow
      Feed.new(options).write(stats) {|stat, res| print_status(stat, res)}
    rescue => e
      say "ERROR: ", :red
      puts e.message
    end

    desc "accounts", "Pull account stats from CloudStack."
    option :domain,
      desc: "Name of Domain (for recursive search)",
      default: "ROOT"
    def accounts
      say "Collect stats...", :yellow
      stats = Collect.new(options).account_stats
      say "Write stats to influxdb...", :yellow
      Feed.new(options).write(stats) {|stat, res| print_status(stat, res)}
    # rescue => e
    #   say "ERROR: ", :red
    #   puts e.message
    end

    no_commands do
      def print_status(stat, res)
        print_in_columns [
          stat['name'],
          res.code == '204' ?
            "OK (HTTP #{res.code})" :
            "FAIL (HTTP #{res.code})"
        ]
      end
    end

  end # class
end # module
