require 'base64'

module Mirador

  module Formatting

    @@format_map = {}

    module ClassMethods
      protected

      def format_map map={}

        # get the default from the map, or use 'image',
        # which is most likely correct..
        default = (map.delete(:default) || :image)

        map.default_proc = Proc.new { |h, k|
          h[k] = default
        }

        Formatting.class_variable_set(:@@format_map, map)

      end

    end

    def self.included(base)
      base.extend(ClassMethods)
      Formatting.class_variable_set(:@@formatter, Formatter.new)
    end

    protected

    def format_items dtype, items
      Hash[items.each_with_index.map do |kv, idx|
        format_item(dtype, idx, kv[0], kv[1])
      end.flatten(1)]
    end

    private

    def format_item dtype, idx, id, data
      formatted, dt = get_format(data, dtype.to_sym)

      [
        ["#{ dt }[#{ idx }][id]", id],
        ["#{ dt }[#{ idx }][data]", formatted],
      ]
    end

    def get_format item, dtype
      dtype = dtype.to_sym

      if not @@formatter.respond_to? dtype
        raise ApiError, "unsupported datatype: #{ dtype }"
      end

      return @@formatter.send(dtype, item), @@format_map[dtype]
    end

  end

  class Formatter
    DATA_URI_RXP = /^.+;base64,/

    def url item
      item
    end

    def buffer item
      encode_filedata(item)
    end

    def file item
      encode_filedata(
        if item.respond_to? :read
          item.read
        else
          File.read(item)
        end
      )
    end

    def encoded_string item
      item.gsub(/\n/, '')
    end

    def data_uri item
      item.sub(DATA_URI_RXP, '').gsub(/\n/,'')
    end

    private

    def encode_filedata(data)
      Base64.encode64(data).gsub(/\n/, '')
    end

  end

end
