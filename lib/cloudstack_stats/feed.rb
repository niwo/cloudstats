module CloudstackStats
  class Feed

    def initialize(options = {})
      load_configuration(options)
    end

    def client(db = @database, opts = {})
      @client ||= InfluxDB::Client.new db, {
        host: @host,
        port: @port,
        username: @username,
        password: @password,
        use_ssl: @use_ssl,
        time_precision: @time_precision
      }.merge(opts)
    end

    def setup
      begin
        client = self.client(nil, retry: 0)
        client.ping
        unless client.list_databases.any? {|db| db['name'] == @database}
          logger.warn "No database with name #{@database} found. Creating it."
          client.create_database(@database)
          self.setup
        end
        if @username && !client.list_users.any?{|u| u["username"] == @username}
          logger.warn "No user with name #{@username} found. Creating it."
          client.create_database_user(@database, @username, @password)
          self.setup
          exit 0
        end
      rescue InfluxDB::ConnectionError => e
        puts e.inspect
        logger.fatal "Can't connect to influxdb. Please check if influxdb service is running."
        exit 1
      rescue => e
        puts e.inspect
        logger.fatal "Unhandled error: #{e.message}"
        exit 1
      end
      logger.info "Influxdb setup passed."
    end

    def load_configuration(options)
      @configuration_file = options[:configuration_file] || File.expand_path(
        "../../../config/influxdb.yml", __FILE__
      )
      file_settings = load_configuration_file(@configuration_file)
      @username = options[:username] || file_settings["username"]
      @password = options[:password] || file_settings["password"]
      @host = options[:host] || file_settings["host"]
      @port = options[:port] || file_settings["port"]
      @use_ssl = options[:use_ssl] || file_settings["use_ssl"]
      @database = options[:database] || file_settings["database"]
      @time_precision = options[:time_precision] || file_settings["time_precision"]
    end

    def load_configuration_file(file_path)
      begin
        file_settings = YAML.load ERB.new(File.read(file_path)).result
      rescue => e
        logger.fatal "Error while loading influxdb configuration file: #{e.message}"
        exit 1
      end
      file_settings["host"] ||= "localhost"
      file_settings["port"] ||= 8086
      file_settings["use_ssl"] ||= false
      file_settings["database"] ||= "cloudstack-stats"
      file_settings["time_precision"] ||= "s"
      file_settings
    end

  end # class
end # module
