require 'httparty'
require 'base64'

module Mirador

  API_BASE = "http://api.mirador.im/v1/"

  class Result

    def initialize name, data
      @name = name

      @safe = data['safe']
      @value = data['value']
    end

    def to_s
      "<Mirador::Result; name: #{ @name }; safe: #{ @safe }; value: #{ @value }/>"
    end

    def self.parse_results reqs, results

      if not results
        return nil
      end

      results.each_with_index.map do |v, i|
        Result.new(reqs[i], v['result'])
      end
    end

  end

  class ApiError < StandardError
  end

  class Client
    include HTTParty
    base_uri 'api.mirador.im'

    def initialize(api_key)
      @options = { api_key: api_key }
    end

    def classify_urls urls
      res = self.class.get(
        "/v1/classify",
        {
          query: @options.merge({url: urls})
        }
      )

      if res['errors']
        raise ApiError, res['errors']
      elsif not res
        raise ApiError, "no response: #{ res.code }"
      end

      Result.parse_results urls, res['results']
    end

    def classify_files files
      processed = files.map do |f| self.process_file(f) end

      res = self.class.post(
        "/v1/classify",
        {
          body: @options.merge({image: processed}),
          headers: {'User-Agent' => 'Mirador Client v1.0/Ruby'},
        }
      )

      if res['errors']
        raise ApiError, res['errors']
      end

      if not res
        raise ApiError, "no response", res.code
      end

      return Result.parse_results(files, res['results'])
    end

    def process_file file
      data = File.read(file)
      Base64.encode64(data).gsub("\n", '')
    end

  end

end

if __FILE__ == $0

  client = Mirador::Client.new('your_key_here')
  client.classify_urls(ARGV).each do |res|
    puts(res)
  end

end
