module Seahorse
  class Type
    attr_accessor :name, :required, :model, :location, :header, :uri, :as
    attr_accessor :documentation

    def self.type; @type || name.to_s.underscore.gsub(/_type$|^.+\//, '') end
    def self.type=(v) @type = v end
    def self.inspect; "Type(#{type})" end

    def initialize(*args)
      name, opts = nil, {}
      if args.size == 0
        name = type
      elsif args.size == 2
        name, opts = args.first, args.last
      elsif Hash === args.first
        opts = args.first
      else
        name = args.first
      end

      self.name = name.to_s
      opts.each {|k, v| send("#{k}=", v) }
    end

    def inspect
      variables = instance_variables.map do |v|
        next if v.to_s =~ /^@(?:(?:default_)?type|name|model)$/
        [v.to_s[1..-1], instance_variable_get(v).inspect].join('=')
      end.compact.join(' ')
      variables = ' ' + variables if variables.length > 0
      "#<Type(#{type})#{variables}>"
    end

    def type
      @type ||= self.class.type.to_s
    end

    def default_type
      klass = self.class
      last_klass = nil
      while klass != Type
        last_klass = klass
        klass = klass.superclass
      end
      @default_type ||= last_klass.type
    end

    def complex?; false end

    def add(shape)
      raise NotImplementedError, "Cannot add #{shape.inspect} to #{type}"
    end

    def to_hash
      hash = {'type' => default_type}
      hash['required'] = true if required
      hash['location'] = location if location
      hash['location'] = 'uri' if uri
      if header
        header_name = header == true ? name : header
        hash['location'] = 'header'
        hash['location_name'] = header_name
        hash['name'] = header_name
      end
      hash['documentation'] = documentation if documentation
      hash
    end

    def from_input(data, filter = true) data end
    def to_output(data) pull_value(data).to_s end
    def to_strong_params; name.to_s end

    def pull_value(value)
      found = false
      names = as ? as : name
      if names
        names = [names].flatten
        names.each do |name|
          if value.respond_to?(name)
            value = value.send(name)
            found = true
          elsif Hash === value
            if value.has_key?(name)
              value = value[name]
              found = true
            end
          else
            raise ArgumentError, "no property `#{name}' while looking for " +
                                 "`#{names.join('.')}' on #{value.inspect}"
          end
        end
      end
      found ? value : nil
    end
  end

  class StringType < Type
    def from_input(data, filter = true) data.to_s end
  end

  class TimestampType < Type
    def from_input(data, filter = true)
      String === data ? Time.parse(data) : data
    end
  end

  class IntegerType < Type
    def from_input(data, filter = true) Integer(data) end
    def to_output(data) (value = pull_value(data)) ? value.to_i : nil end
  end

  class BooleanType < Type
    def from_input(data, filter = true) !!pull_value(data) end
  end

  class ListType < Type
    attr_accessor :collection

    def initialize(*args)
      super
    end

    def complex?; true end

    def add(shape)
      self.collection = shape
    end

    def to_hash
      hash = super
      hash['members'] = collection ? collection.to_hash : {}
      hash
    end

    def from_input(data, filter = true)
      data.each_with_index {|v, i| data[i] = collection.from_input(v, filter) }
      data
    end

    def to_output(data)
      pull_value(data).map {|v| collection.to_output(v) }
    end

    def to_strong_params
      collection.complex? ? collection.to_strong_params : []
    end
  end

  class StructureType < Type
    attr_accessor :members

    def initialize(*args)
      @members = {}
      super
    end

    def complex?; true end

    def add(shape)
      members[shape.name.to_s] = shape
    end

    def to_hash
      hash = super
      hash['members'] = members.inject({}) do |hsh, (k, v)|
        hsh[k.to_s] = v.to_hash
        hsh
      end
      hash
    end

    def from_input(data, filter = true)
      return nil unless data
      data.dup.each do |name, value|
        if members[name]
          if filter && members[name].type == 'list' && members[name].collection.model &&
             ActiveRecord::Base > members[name].collection.model
          then
            data.delete(name)
            data[name + '_attributes'] = members[name].from_input(value, filter)
          else
            data[name] = members[name].from_input(value, filter)
          end
        elsif filter
          data.delete(name)
        end
      end
      data
    end

    def to_output(data)
      if Hash === data
        data = data.with_indifferent_access unless HashWithIndifferentAccess === data
      end

      members.inject({}) do |hsh, (name, member)|
        value = member.to_output(data)
        hsh[name] = value if value
        hsh
      end
    end

    def to_strong_params
      members.map do |name, member|
        if member.complex?
          if member.type == 'list' && member.collection.model &&
             ActiveRecord::Base > member.collection.model
          then
            name += '_attributes'
          end

          {name => member.to_strong_params}
        else
          name
        end
      end
    end
  end
end
