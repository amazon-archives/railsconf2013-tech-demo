require_relative './type'

module Seahorse
  class ShapeBuilder
    def self.build_default_types
      hash = HashWithIndifferentAccess.new
      hash.update string: [StringType, nil],
                  timestamp: [TimestampType, nil],
                  integer: [IntegerType, nil],
                  boolean: [BooleanType, nil],
                  list: [ListType, nil],
                  structure: [StructureType, nil]
      hash
    end

    def self.type(type, supertype = 'structure', &block)
      klass = Class.new(type_class_for(supertype))
      klass.type = type
      @@types[type] = [klass, block]
    end

    def self.type_class_for(type)
      @@types[type] ? @@types[type][0] : nil
    end

    def initialize(context)
      @context = context
      @desc = nil
    end

    def build(&block)
      init_blocks = []
      init_blocks << block if block_given?

      # collect the init block for this type and all of its super types
      klass = @context.class
      while klass != Type
        if block = @@types[klass.type][1]
          init_blocks << block
        end
        klass = klass.superclass
      end

      init_blocks.reverse.each do |init_block|
        instance_eval(&init_block)
      end
    end

    def method_missing(type, *args, &block)
      if @@types[type]
        send_type(type, *args, &block)
      else
        super
      end
    end

    def desc(text)
      @desc = text
    end

    def model(model)
      @context.model = model
    end

    private

    def send_type(type, *args, &block)
      klass, init_block = *@@types[type.to_s]
      shape = klass.new(*args)
      shape.documentation = @desc
      @context.add(shape)
      if init_block || block
        old_context, @context = @context, shape
        instance_eval(&init_block) if init_block
        instance_eval(&block) if block
        @context = old_context
      end
      @desc = nil
      true
    end

    @@types = build_default_types
  end
end
