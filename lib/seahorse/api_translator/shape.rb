# Copyright 2011-2013 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You
# may not use this file except in compliance with the License. A copy of
# the License is located at
#
#     http://aws.amazon.com/apache2.0/
#
# or in the "license" file accompanying this file. This file is
# distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF
# ANY KIND, either express or implied. See the License for the specific
# language governing permissions and limitations under the License.

require_relative './inflector'

module Seahorse
  class ApiTranslator

    # @private
    class Shape

      include Inflector

      def initialize rules, options = {}
        @options = options
        @rules = {}
        @rules['name'] = options['name'] if options.key?('name')
        set_type(rules.delete('type'))
        rules.each_pair do |method,arg|
          send("set_#{method}", *[arg])
        end
      end

      def rules
        if @rules['type'] != 'blob'
          @rules
        elsif @rules['payload'] or @rules['streaming']
          @rules.merge('type' => 'binary')
        else
          @rules.merge('type' => 'base64')
        end
      end

      def xmlname
        if @rules['flattened']
          (@rules['members'] || {})['name'] || @xmlname
        else
          @xmlname
        end
      end

      protected

      def set_timestamp_format format
        @rules['format'] = format
      end

      def set_type name
        types = {
          'structure' => 'structure',
          'list' => 'list',
          'map' => 'map',
          'boolean' => 'boolean',
          'timestamp' => 'timestamp',
          'character' => 'string',
          'double' => 'float',
          'float' => 'float',
          'integer' => 'integer',
          'long' => 'integer',
          'short' => 'integer',
          'string' => 'string',
          'blob' => 'blob',
          'biginteger' => 'integer',
          'bigdecimal' => 'float',
        }
        if name == 'string'
          # Purposefully omitting type when string (to reduce size of the api
          # configuration).  The parsers use string as the default when
          # 'type' is omitted.
          #@rules['type'] = 'string'
        elsif type = types[name]
          @rules['type'] = type
        else
          raise "unhandled shape type: #{name}"
        end
      end

      def set_members members
        case @rules['type']
        when 'structure'
          @rules['members'] = {}
          members.each_pair do |member_name,member_rules|

            member_shape = new_shape(member_rules)

            member_key = inflect(member_name, @options[:inflect_member_names])
            member_rules = member_shape.rules

            if member_name != member_key
              member_rules = { 'name' => member_name }.merge(member_rules)
            end

            if swap_names?(member_shape)
              member_rules['name'] = member_key
              member_key = member_shape.xmlname
            end

            @rules['members'][member_key] = member_rules

          end
        when 'list'
          @rules['members'] = new_shape(members).rules
        when 'map'
          @rules['members'] = new_shape(members).rules
        else
          raise "unhandled complex shape `#{@rules['type']}'"
        end
        @rules.delete('members') if @rules['members'].empty?
      end

      def set_keys rules
        shape = new_shape(rules)
        @rules['keys'] = shape.rules
        @rules.delete('keys') if @rules['keys'].empty?
      end

      def set_xmlname name
        @xmlname = name
        @rules['name'] = name
      end

      def set_location location
        @rules['location'] = (location == 'http_status' ? 'status' : location)
      end

      def set_location_name header_name
        @rules['name'] = header_name
      end

      def set_payload state
        @rules['payload'] = true if state
      end

      def set_flattened state
        @rules['flattened'] = true if state
      end

      def set_streaming state
        @rules['streaming'] = true if state
      end

      def set_xmlnamespace ns
        @rules['xmlns'] = ns
      end

      def set_xmlattribute state
        @rules['attribute'] = true if state
      end

      def set_documentation docs
        @rules['documentation'] = docs if @options[:documentation]
      end

      def set_enum values
        @rules['enum'] = values if @options[:documentation]
      end

      def set_wrapper state
        @rules['wrapper'] = true if state
      end

      # we purposefully drop these, not useful unless you want to create
      # static classes
      def set_shape_name *args; end
      def set_box *args; end

      # @param [Hash] rules
      # @option options [String] :name The name this shape has as a structure member.
      def new_shape rules
        self.class.new(rules, @options)
      end

    end

    # @private
    class InputShape < Shape

      def set_required *args
        @rules['required'] = true;
      end

      def set_member_order order
        @rules['order'] = order
      end

      def set_min_length min
        @rules['min_length'] = min if @options[:documentation]
      end

      def set_max_length max
        @rules['max_length'] = max if @options[:documentation]
      end

      def set_pattern pattern
        @rules['pattern'] = pattern if @options[:documentation]
      end

      def swap_names? shape
        false
      end

    end

    # @private
    class OutputShape < Shape

      # these traits are ignored for output shapes
      def set_required *args; end
      def set_member_order *args; end
      def set_min_length *args; end
      def set_max_length *args; end
      def set_pattern *args; end

      def swap_names? shape
        if @options[:documentation]
          false
        else
          !!(%w(query rest-xml).include?(@options[:type]) and shape.xmlname)
        end
      end

    end

  end
end
