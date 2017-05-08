require "thor"
require "cloudstack_stats/version"
require "cloudstack_stats/collect"
require "cloudstack_stats/feed"

module CloudstackStats
  class Cli < Thor
    include Thor::Actions

    package_name "cloudstack_stats"

    class_option :config_file,
      default: File.join(Dir.home, '.cloudstack-cli.yml'),
      aliases: '-C',
      desc: 'Location of your cloudstack-cli configuration file'

    class_option :env,
      aliases: '-E',
      desc: 'cloudstack-cli environment to use'

    class_option :connection_string,
      default: "http://localhost:8086/",
      aliases: '-I',
      desc: 'Influxdb connection string'

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
      Feed.new(options).write(stats) do |stat, res|
        print_in_columns [
          stat['name'],
          res.code == '204' ? 'OK' : 'FAIL'
        ]
      end
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
      Feed.new(options).write(stats) do |stat, res|
        print_in_columns [
          stat['name'],
          res.code == '204' ? 'OK' : 'FAIL'
        ]
      end
    rescue => e
      say "ERROR: ", :red
      puts e.message
    end

  end # class
end # module
