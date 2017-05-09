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

  class Feed
    require "net/http"
    require "uri"

    def initialize(opts = {})
      @database = opts[:database]
      @url = opts[:influx_url] ||
        "http://localhost:8086/"
      @user = opts[:influx_user]
      @password = opts[:influx_password]
      @debug = opts[:debug]
    end

    def write(stats)
      uri = URI.parse(
        URI.join(
          @url,
          "write?db=#{@database}&precision=m"
        ).to_s
      )
      http = Net::HTTP.new(uri.host, uri.port)

      if uri.scheme == "https"
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      request = Net::HTTP::Post.new(uri.request_uri)
      request.content_type = "application/octet-stream"
      request.basic_auth(@user, @password) if @user && @password


      type = stats[:type]
      stats[:stats].map do |stat|
        request.body = line = stat_to_line(stat, type)
        puts line if @debug
        response = http.request(request)
        yield(stat, response) if block_given?
      end
    end

    private

    # builds influxdb line protocol strings
    def stat_to_line(obj, type)
      fields = CloudstackStats::CS_STATS.map {|name| "#{name}=#{obj[name] || 0}i" }
      tags = CloudstackStats::CS_TAGS.map {|name| "#{name}=#{obj[name]}" }
      obj["name"].downcase.tr(" ", "-").tr("--", "-").gsub(/[^0-9A-Za-z-_]/, '') +
        "," + tags.join(",") +
        ",type=#{type}" +
        " " + fields.join(",")
    end

  end # class
end # module
