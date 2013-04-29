module Seahorse
  class Operation
    attr_reader :name, :verb, :action
    attr_accessor :documentation

    def initialize(controller, name, action = nil, &block)
      @name = name.to_s
      @action = action.to_s
      @controller = controller
      url_prefix = "/" + controller.model_name.pluralize
      url_extra = nil

      case action.to_s
      when 'index'
        @verb = 'get'
      when 'show'
        @verb = 'get'
        url_extra = ':id'
      when 'destroy', 'delete'
        @verb = 'delete'
        url_extra = ':id'
      when 'create'
        @verb = 'post'
      when 'update'
        @verb = 'put'
      else
        @verb = 'get'
        url_extra = name.to_s
      end
      @url = url_prefix + (url_extra ? "/#{url_extra}" : "")

      instance_eval(&block)
    end

    def verb(verb = nil)
      verb ? (@verb = verb) : @verb
    end

    def url(url = nil)
      url ? (@url = url) : @url
    end

    def input(type = nil, &block)
      @input ||= ShapeBuilder.type_class_for(type || 'structure').new
      type || block ? ShapeBuilder.new(@input).build(&block) : @input
    end

    def output(type = nil, &block)
      @output ||= ShapeBuilder.type_class_for(type || 'structure').new
      type || block ? ShapeBuilder.new(@output).build(&block) : @output
    end

    def to_hash
      {
        'name' => name.camelcase,
        'http' => {
          'uri' => url.gsub(/:(\w+)/, '{\1}'),
          'method' => verb.upcase
        },
        'input' => input.to_hash,
        'output' => output.to_hash,
        'documentation' => documentation
      }
    end
  end
end
