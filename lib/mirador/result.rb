module Mirador

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

end
