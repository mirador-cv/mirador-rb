module Mirador

  module Processing

    MAX_KEY_SIZE = 256

    module ClassMethods
      attr_accessor :_max_key_size

      def max_key_size num
        Processing.class_variable_set(:@@max_key_size, num)
      end

    end

    def self.included(base)
      base.extend(ClassMethods)
      Processing.class_variable_set(:@@max_key_size, MAX_KEY_SIZE)
    end

    protected 

    # given an argument, e.g.,
    # an item in a *args list, 
    # return the proper datatype-pair
    # (to be put into a Hash)
    def process_argument arg, idx=0

      if arg.is_a?(String) 
        if arg.length < @@max_key_size
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

  end

end
