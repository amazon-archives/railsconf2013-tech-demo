module Seahorse
  class Router
    def initialize(model)
      @model = model
    end

    def add_routes(router)
      operations = @model.operations
      controller = @model.model_name.pluralize
      operations.each do |name, operation|
        router.match "/#{name}" => "#{controller}##{operation.action}",
          defaults: { format: 'json' },
          via: [:get, operation.verb.to_sym].uniq
        router.match operation.url => "#{controller}##{operation.action}",
          defaults: { format: 'json' },
          via: operation.verb
      end
    end
  end
end
