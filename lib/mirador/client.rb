require 'httparty'

module Mirador

  class Client
    include HTTParty
    include Processing
    include Formatting

    # the number of items
    # to actuall send in a request
    CHUNK_SIZE = 4

    base_uri 'api.mirador.im'
    default_timeout 20

    format_map(
      url: :url,
      default: :image,
    )

    max_key_size 369

    def initialize(api_key, opt={})
      raise AuthenticationError.new("api key required") if not api_key

      @options = { api_key: api_key }
      @parser = opt[:parser] || ResultList
      @chunk_size = opt[:chunk_size] || CHUNK_SIZE
    end


    [:url, :file, :buffer, :encoded_string, :data_uri].each do |datatype|

      define_method("classify_#{datatype.to_s}s") do |args, params={}|
        flexible_request args, params do |item|
          format_items(datatype, item)
        end
      end

      define_method("classify_#{datatype.to_s}") do |args, params={}|
        res = self.send("classify_#{datatype.to_s}s", args, params)
        res and res[0]
      end

    end

    protected

    def flexible_request(args, params={}, &cb)
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
        make_request(cb.call(item))
      end
    end


    # given a request and a block,
    # call the block X number of times
    # where X is request.length / MAX_LEN
    def chunked_request req, &mthd
      output = @parser.new

      req.each_slice(@chunk_size).each do |slice|
        output.update(mthd.call(slice))
      end

      return output
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

      return @parser.parse_results(res[k])
    end

  end

end
