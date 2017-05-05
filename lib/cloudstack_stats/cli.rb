require "thor"
require "cloudstack_stats/version"
require "cloudstack_stats/cloudstack_helper"
require "cloudstack_stats/influxdb"

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
    option :exclude,
      desc: "Projects to exclude (regex).",
      type: :array
    def projects
      cs = CloudstackHelper.new(options).cs

      stats = %w(vmrunning volumetotal vmstopped memorytotal cputotal iptotal primarystoragetotal secondarystoragetotal snapshottotal volumetotal)

      table = [%w(project) + stats]
      cs.list_projects(listall: true).each do |project|
        values = [project["name"]]
        stats.each do |name|
          values << project[name]
        end
        table << values
      end
      print_table(table)

    rescue => e
      say "ERROR: ", :red
      puts e.message
    end

    desc "accounts", "Pull account stats from CloudStack."
    option :exclude,
      desc: "Accounts to exclude (regex).",
      type: :array
    def accounts
      cs = CloudstackHelper.new(options).cs
      stats = %w(vmrunning volumetotal vmstopped memorytotal cputotal iptotal primarystoragetotal secondarystoragetotal snapshottotal volumetotal)

      table = [%w(account) + stats]
      cs.list_accounts(listall: true).each do |account|
        values = [account["name"]]
        stats.each do |name|
          values << account[name]
        end
        table << values
      end
      print_table(table)

    rescue => e
      say "ERROR: ", :red
      puts e.message
    end

    no_commands do
      def filter_objects(objects, key, value)
        objects.select do |object|
          object[key.to_s].to_s =~ /#{value}/i
        end
      rescue RegexpError => e
        say "ERROR: Invalid regular expression in limit option- #{e.message}", :red
        exit 1
      end
    end

  end # class
end # module
