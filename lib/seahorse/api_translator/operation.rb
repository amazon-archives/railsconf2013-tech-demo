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
require_relative './shape'

module Seahorse
  class ApiTranslator

    # @private
    class Operation

      include Inflector

      def initialize rules, options = {}
        @options = options

        @method_name = rules['name'].sub(/\d{4}_\d{2}_\d{2}$/, '')
        @method_name = inflect(@method_name, @options[:inflect_method_names])

        @rules = rules

        if @rules['http']
          @rules['http'].delete('response_code')
        end

        translate_input
        translate_output

        if @options[:documentation]
          @rules['errors'] = @rules['errors'].map {|e| e['shape_name'] }
        else
          @rules.delete('errors')
          @rules.delete('documentation')
          @rules.delete('documentation_url')
          @rules.delete('response_code')
        end
      end

      # @return [String]
      attr_reader :method_name

      # @return [Hash]
      attr_reader :rules

      private

      def translate_input
        if @rules['input']
          rules = InputShape.new(@rules['input'], @options).rules
          rules['members'] ||= {}
          rules = normalize_inputs(rules)
        else
          rules = {
            'type' => 'structure',
            'members' => {},
          }
        end
        @rules['input'] = rules
      end

      def translate_output
        if @rules['output']
          rules = OutputShape.new(@rules['output'], @options).rules
          move_up_outputs(rules)
          cache_payload(rules)
        else
          rules = {
            'type' => 'structure',
            'members' => {},
          }
        end
        @rules['output'] = rules
      end

      def normalize_inputs rules
        return rules unless @options[:type].match(/rest/)

        xml = @options[:type].match(/xml/)
        payload = false
        wrapper = false

        if rules['members'].any?{|name,rule| rule['payload'] }

          # exactly one member has the payload trait
          payload, rule = rules['members'].find{|name,rule| rule['payload'] }
          rule.delete('payload')

          #if rule['type'] == 'structure'
          #  wrapper = payload
          #  payload = [payload]
          #end

        else

          # no members marked themselves as the payload, collect everything
          # without a location
          payload = rules['members'].inject([]) do |list,(name,rule)|
            list << name if !rule['location']
            list
          end

          if payload.empty?
            payload = false
          elsif xml
            wrapper = @rules['input']['shape_name']
          end

        end

        rules = { 'wrapper' => wrapper }.merge(rules) if wrapper
        rules = { 'payload' => payload }.merge(rules) if payload
        rules

      end

      def move_up_outputs output
        move_up = nil
        (output['members'] || {}).each_pair do |member_name, rules|
          if rules['payload'] and rules['type'] == 'structure'
            rules.delete('payload')
            move_up = member_name
          end
        end

        if move_up
          output['members'].merge!(output['members'].delete(move_up)['members'])
        end
      end

      def cache_payload rules
        (rules['members'] || {}).each_pair do |member_name, rule|
          rules['payload'] = member_name if rule['payload'] || rule['streaming']
          rule.delete('payload')
        end
      end

    end
  end
end
