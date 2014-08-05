require 'httparty'
require 'base64'

module Mirador

  class ApiError < StandardError
  end

  class ResultList
    include Enumerable

    def initialize(items=[])
      @items = {}

      items.each do |x|
        @items[x.id] = x
      end
    end

    def <<(item)
      @items[item.id] = item
    end

    def [](key)
      if key.is_a? Integer and not @items.has_key? key
        @items.values[key]
      else
        @items[key.to_s]
      end
    end

    def to_a
      @items.values
    end

    def length
      @items.values.length
    end

    def update other
      @items.update(other)
    end

    def to_h
      @items
    end

    def to_json
      @items.to_json
    end

    def each &block
      if block.arity == 1
        @items.values.each do |x|
          block.call(x)
        end
      else
        @items.each do |k, v|
          block.call(k, v)
        end
      end
    end

    def self.parse_results res

      output = {}
      res.each do |x|
        r = Result.new(x)
        output[r.id] = r
      end

      output
    end

  end

  class Result
    attr_accessor :id, :safe, :value, :error

    def initialize data

      if data.has_key? 'errors'
        @error = data['errors']
        return
      end

      @id = data['id']
      @safe = data['result']['safe']
      @value = data['result']['value']

    end

    def to_h
      {
        id: @id,
        safe: @safe,
        value: @value,
      }
    end

    def to_json
      as_h = self.to_h

      if as_h.respond_to? :to_json
        as_h.to_json
      else
        nil
      end
    end

    def failed?
      @error != nil
    end

    def to_s
      "<Mirador::Result; id: #{ @id }; safe: #{ @safe }; value: #{ @value }/>"
    end

    def name
      @id
    end

  end

  class Client
    include HTTParty
    base_uri 'api.mirador.im'

    default_timeout 20

    MAX_LEN = 4
    MAX_ID_LEN = 256
    DATA_URI_PRE = ';base64,'
    DATA_URI_PRELEN = 8

    def initialize(api_key)
      @options = { api_key: api_key }
    end

    # metaprogramming extreme
    [:url, :file, :buffer, :encoded_string, :data_uri].each do |datatype|
      define_method("classify_#{datatype.to_s}s") do |args, params={}|
        flexible_request args, params do |item|
          fmt_items(datatype, item)
        end
      end

      define_method("classify_#{datatype.to_s}") do |args, params={}|
        res = self.send("classify_#{datatype.to_s}s", args, params)
        res[0]
      end

    end

    protected

    def flexible_request(args, params={}, &cb)
      req = {}

      req = (if args.is_a? Hash

        Hash[args.map do |k, v|
          process_param(k, v)
        end]

      elsif args.is_a? String
        Hash[[process_argument(args)]]

      elsif args and args.length
        Hash[args.each_with_index.map do |a, idx|
          process_argument(a, idx)
        end]

      elsif params
        Hash[params.map do |k, v|
          process_param(k, v)
        end]
      end)

      chunked_request(req) do |item|
        formatted = cb.call(item)
        make_request(formatted)
      end
    end

    def process_argument arg, idx=0

      if arg.is_a?(String) 
        if arg.length < MAX_ID_LEN
          [arg,  arg]
        else
          [idx, arg]
        end

      elsif arg.respond_to?(:name) and arg.respond_to?(:read)

        [arg.name, arg]

      elsif arg.respond_to?(:id) and arg.respond_to?(:data)

        [arg.id, arg.data]

      elsif arg.is_a?(Hash)

        if arg.has_key? :id and arg.has_key? :data
          [arg[:id], arg[:data]]
        elsif arg.has_key? 'id' and arg.has_key? 'data'
          [arg['id'], arg['data']]
        end

      else
        raise ApiError, "Invalid argument: #{ arg }"
      end

    end

    # given a parameter passed in,
    # assuming that its a id => data mapping, return
    # the correct formatting/check for any fuck ups
    # @arguments:
    #   k - key
    #   v - value
    # @returns:
    #   { k => v } pair
    def process_param k, v

      if v.is_a?(File)
        [ k, v.read ]
      elsif k.respond_to?(:to_s) and v.is_a?(String)
        [ k.to_s, v ]
      else
        raise ApiError, "Invalid Argument: #{ k } => #{ v }"
      end

    end

    # given a request and a block,
    # call the block X number of times
    # where X is request.length / MAX_LEN
    def chunked_request req, &mthd
      output = ResultList.new
      req.each_slice(MAX_LEN).each do |slice|
        output.update(mthd.call(slice))
      end

      return output
    end

    # basically, transform hash h into a hash
    # where the key-value pairs are all formatted
    # by 'fmt-item' (should double the number of key-value
    # pairs in the hash)
    def fmt_items name, h
      out = {}
      h.each_with_index do |kv, idx|
        out.update fmt_item(name, idx, kv[0], kv[1])
      end
      return out
    end

    @@name_map = {
      file: 'image',
      buffer: 'image',
      raw: 'image',
      url: 'url',
      encoded_string: 'image',
      data_uri: 'image',
    }

    @@formatters = {
      url: Proc.new { |url| url },

      file: Proc.new { |file|

        Base64.encode64(if file.respond_to? :read
          file.read
        else
          File.read(file)
        end).gsub(/\n/, '')

      },

      buffer: Proc.new { |file|

        Base64.encode64(file).gsub(/\n/, '')

      },

      raw: Proc.new { |file|

        Base64.encode64(file).gsub(/\n/, '')

      },

      encoded_string: Proc.new { |b64str|
        b64str.gsub(/\n/, '')
      },

      data_uri: Proc.new { |datauri|
        datauri.sub(/^.+;base64,/, '').gsub(/\n/,'')
      },

    }

    # produce a k-v mapping internal to the API,
    # so that 'name' is the datatype: 
    # e.g., name[idx][id], name[idx][data]
    def fmt_item name, idx, id, data
      formatted = @@formatters[name].call(data)
      datatype = @@name_map[name]
      {
        "#{datatype}[#{idx}][id]" => id,
        "#{datatype}[#{idx}][data]" => formatted,
      }
    end

    # base method to actually make the request
    def make_request params

      res = self.class.post(
        "/v1/classify",
        {
          body: @options.merge(params),
          headers: {"User-Agent" => "Mirador Client v1.0/Ruby"}
        }
      )

      k = 'results'

      if res['errors']

        if not res['result']
          raise ApiError, res
        else
          k = 'result'
        end

      elsif not res
        raise ApiError, "no response: #{ res.code }"
      end

      return ResultList.parse_results res[k]
    end

  end

end
