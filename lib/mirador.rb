require 'httparty'
require 'base64'

module Mirador

  API_BASE = "http://api.mirador.im/v1/"

  class Result
    attr_accessor :name, :safe, :value

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
      return self.classify_encoded processed
    end


    def classify_raw_images imgs
      processed = imgs.map { |i| Base64.encode(i).gsub("\n", '') }
      return self.classify_encoded processed
    end

    private

    def process_file file
      data = File.read(file)
      Base64.encode64(data).gsub("\n", '')
    end

    def classify_encoded encoded
      res = self.class.post(
        "/v1/classify",
        {
          body: @options.merge({image: encoded}),
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

  end

end
