module Seahorse
  module Model
    @@apis ||= {}

    class << self
      def apis; @@apis end

      def add_all_routes(router)
        Dir.glob("#{Rails.root}/app/models/api/*.rb").each {|f| load f }
        @@apis.values.each {|api| api.add_routes(router) }
      end
    end

    extend ActiveSupport::Concern

    included do
      @@apis[name.underscore.gsub(/_api$|^api\//, '')] = self
    end

    module ClassMethods
      attr_reader :operations

      def model_name
        name.underscore.gsub(/_api$|^api\//, '')
      end

      def add_routes(router)
        Seahorse::Router.new(self).add_routes(router)
      end

      def desc(text)
        @desc = text
      end

      def operation(name, &block)
        name, action = *operation_name_and_action(name)
        @actions ||= {}
        @operations ||= {}
        @operations[name] = Operation.new(self, name, action, &block)
        @operations[name].documentation = @desc
        @actions[action] = @operations[name]
        @desc = nil
      end

      def operation_from_action(action)
        @actions ||= {}
        @actions[action]
      end

      def type(name, &block)
        supertype = 'structure'
        name, supertype = *name.map {|k,v| [k, v] }.flatten if Hash === name
        ShapeBuilder.type(name, supertype, &block)
      end

      def to_hash
        ops = @operations.inject({}) do |hash, (name, operation)|
          hash[name.camelcase(:lower)] = operation.to_hash
          hash
        end
        {'operations' => ops}
      end

      private

      def operation_name_and_action(name)
        if Hash === name
          name.to_a.first.map(&:to_s).reverse
        else
          case name.to_s
          when 'index', 'list'
            ["list_#{model_name.pluralize}", 'index']
          when 'show'
            ["get_#{model_name}", name.to_s]
          else
            ["#{name}_#{model_name}", name.to_s]
          end
        end
      end
    end
  end
end