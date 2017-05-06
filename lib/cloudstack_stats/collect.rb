require "cloudstack_client"
require "yaml"

module CloudstackStats

  CS_TAGS = %w(domain)

  CS_STATS = %w(
    vmrunning vmstopped
    memorytotal cputotal iptotal
    primarystoragetotal
    secondarystoragetotal
    snapshottotal networktotal
    volumetotal sentbytes
  )

  class Collect

    def initialize(settings)
      @settings = settings.dup
      @config ||= load_configuration
      @cs ||= CloudstackClient::Client.new(
        @config[:url],
        @config[:api_key],
        @config[:secret_key]
      )
      @cs.debug = true if @settings[:debug]
      @cs
    end

    def account_stats
      lines(@cs.list_accounts(client_options), "account")
    end

    def project_stats
      lines(@cs.list_projects(client_options), "project")
    end

    private

    # builds influxdb lines protocol arrays
    def lines(objects, type)
      objects.map do |obj|
        fields = CS_STATS.map {|name| "#{name}=#{obj[name]}" }
        tags = CS_TAGS.map {|name| "#{name}=#{obj[name]}" }
        [
          obj["name"] +
          "," + tags.join(",") +
          ",type=#{type}" +
          " " + fields.join(",")
        ]
      end
    end

    def client_options
      { listall: true, isrecursive: true }.merge(
       resolve_domain(@settings)
      )
    end

    def resolve_domain(opts)
      if opts[:domain]
        if domain = @cs.list_domains(name: opts[:domain]).first
          opts[:domainid] = domain['id']
        else
          raise "Domain #{opts[:domain]} not found."
        end
      end
      opts
    end

    def load_configuration
      unless File.exists?(@settings[:config_file])
        message = "Configuration file '#{@settings[:config_file]}' not found."
        message += "Please run \'cloudstack-cli environment add\' to create one."
        raise message
      end
      begin
        config = YAML::load(IO.read(@settings[:config_file]))
      rescue => e
        message = "Can't load configuration from file '#{@settings[:config_file]}'."
        message += "Message: #{e.message}" if @settings[:debug]
        message += "Backtrace:\n\t#{e.backtrace.join("\n\t")}" if @settings[:debug]
        raise message
      end

      env ||= config[:default]
      if env
        unless config = config[env]
          raise "Can't find environment #{env}."
        end
      end
      unless config.key?(:url) && config.key?(:api_key) && config.key?(:secret_key)
        message = "The environment #{env || '\'-\''} does not contain all required keys."
        message += "Please check with 'cloudstack-cli environment list' and set a valid default environment."
        raise message
      end
      config
    end

  end
end
