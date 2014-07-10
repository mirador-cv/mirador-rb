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
    default_timeout 10

    MAX_LEN = 8

    def initialize(api_key)
      @options = { api_key: api_key }
    end

    def classify_urls urls

      if urls.length > MAX_LEN
        out = []
        urls.each_slice(MAX_LEN) do |s|
          out << self.classify_urls(s)
        end

        return out.flatten
      end

      res = self.class.post(
        "/v1/classify",
        {
          body: @options.merge({url: urls}),
          headers: {"User-Agent" => "Mirador Client v1.0/Ruby"}
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
      if files.length > MAX_LEN
        out = []
        files.each_slice(MAX_LEN) do |s|
          out << self.classify_files(s)
        end

        return out.flatten
      end

      processed = files.map do |f| self.process_file(f) end
      return self.classify_encoded files, processed
    end


    def classify_raw_images imgs

      if imgs.length > MAX_LEN
        out = []
        imgs.each_slice(MAX_LEN) do |s|
          out << self.classify_raw_images(Hash[s])
        end

        return out.flatten
      end

      # expects a hash
      # id => image
      images, names = [], []
      imgs.each_pair do |k, v|
        images << v
        names << k
      end

      processed = images.map { |i| Base64.encode64(i).gsub("\n", '') }
      return self.classify_encoded names, processed
    end

    protected

    def process_file file
      data = File.read(file)
      Base64.encode64(data).gsub("\n", '')
    end

    def classify_encoded files, encoded
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
