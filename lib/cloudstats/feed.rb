module Cloudstats
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
      @total = {type: "total", stats: [{}]}
    end

    def write(stats, total = true)
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
      stats[:stats].each do |stat|
        add_to_total(stat) if total
        request.body = line = stat_to_line(stat, type)
        puts line if @debug
        response = http.request(request)
        yield(stat, response) if block_given?
      end
      if total
        @total[:stats][0]['name'] = type
        write(@total, total = false) {|stat, response| yield(stat, response)}
      end
    end

    private

    # builds influxdb line protocol strings
    def stat_to_line(obj, type)
      fields = Cloudstats::CS_STATS.map {|name| "#{name}=#{obj[name].to_i}i" }
      unless type == "total"
        tags = Cloudstats::CS_TAGS.map {|name| "#{name}=#{obj[name]}" }
      end
      line = "#{type}.#{normalize_name(obj["name"])},type=#{type}"
      line += "," + tags.join(",") if tags
      line +=  " " + fields.join(",")
    end

    def add_to_total(obj)
      Cloudstats::CS_STATS.each do |stat|
        if @total[:stats][0].key? stat
          @total[:stats][0][stat] += obj[stat].to_i
        else
          @total[:stats][0][stat] = obj[stat].to_i
        end
      end
    end

    def normalize_name(name)
      name.downcase.tr(" ", "-").tr("--", "-").gsub(/[^0-9A-Za-z\-\_]/, '')
    end

  end # class
end # module
