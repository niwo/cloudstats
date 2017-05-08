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
      @connection_string = opts[:connection_string] ||
        "http://localhost:8086/"
    end

    def write(stats)
      uri = URI.parse("#{@connection_string}write?db=#{@database}")
      http = Net::HTTP.new(uri.host, uri.port)

      if @connection_string =~ /^https::.*/
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      request = Net::HTTP::Post.new(uri.request_uri)
      request.content_type = "application/octet-stream"

      type = stats[:type]
      stats[:stats].map do |stat|
        request.body = stat_to_line(stat, type)
        response = http.request(request)
        yield(stat, response) if block_given?
      end
      nil
    end

    private

    # builds influxdb line protocol strings
    def stat_to_line(obj, type)
      fields = CloudstackStats::CS_STATS.map {|name| "#{name}=#{obj[name] || 0}i" }
      tags = CloudstackStats::CS_TAGS.map {|name| "#{name}=#{obj[name]}" }
      obj["name"] +
        "," + tags.join(",") +
        ",type=#{type}" +
        " " + fields.join(",")
    end

  end # class
end # module
