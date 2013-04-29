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

require 'date'
require 'time'
require 'pathname'

module Seahorse
  # @api private
  class ParamValidator

    # @param [Hash] rules
    def initialize rules
      @rules = (rules || {})['members'] || {}
    end

    # @param [Hash] params A hash of request params.
    # @raise [ArgumentError] Raises an `ArgumentError` if any of the given
    #   request parameters are invalid.
    # @return [Boolean] Returns `true` if the `params` are valid.
    def validate! params
      validate_structure(@rules, params || {})
      true
    end

    private

    def validate_structure rules, params, context = "params"
      # require params to be a hash
      unless params.is_a?(Hash)
        raise ArgumentError, "expected a hash for #{context}"
      end

      # check for missing required params
      rules.each_pair do |param_name, rule|
        if rule['required']
          unless params.key?(param_name) or params.key?(param_name.to_sym)
            msg = "missing required option :#{param_name} in #{context}"
            raise ArgumentError, msg
          end
        end
      end

      # validate hash members
      params.each_pair do |param_name, param_value|
        if param_rules = rules[param_name.to_s]
          member_context = "#{context}[#{param_name.inspect}]"
          validate_member(param_rules, param_value, member_context)
        else
          msg = "unexpected option #{param_name.inspect} found in #{context}"
          raise ArgumentError, msg
        end
      end
    end

    def validate_list rules, params, context
      # require an array
      unless params.is_a?(Array)
        raise ArgumentError, "expected an array for #{context}"
      end
      # validate array members
      params.each_with_index do |param_value,n|
        validate_member(rules, param_value, context + "[#{n}]")
      end
    end

    def validate_map rules, params, context
      # require params to be a hash
      unless params.is_a?(Hash)
        raise ArgumentError, "expected a hash for #{context}"
      end
      # validate hash keys and members
      params.each_pair do |key,param_value|
        unless key.is_a?(String)
          msg = "expected hash keys for #{context} to be strings"
          raise ArgumentError, msg
        end
        validate_member(rules, param_value, context + "[#{key.inspect}]")
      end
    end

    def validate_member rules, param, context
      member_rules = rules['members'] || {}
      case rules['type']
      when 'structure' then validate_structure(member_rules, param, context)
      when 'list' then validate_list(member_rules, param, context)
      when 'map' then validate_map(member_rules, param, context)
      else validate_scalar(rules, param, context)
      end
    end

    def validate_scalar rules, param, context
      case rules['type']
      when 'string', nil
        unless param.respond_to?(:to_str)
          raise ArgumentError, "expected #{context} to be a string"
        end
      when 'integer'
        unless param.respond_to?(:to_int)
          raise ArgumentError, "expected #{context} to be an integer"
        end
      when 'timestamp'
        case param
        when Time, DateTime, Date, Integer
        when /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?Z$/
        else
          msg = "expected #{context} to be a Time/DateTime/Date object, "
          msg << "an integer or an iso8601 string"
          raise ArgumentError, msg
        end
      when 'boolean'
        unless [true,false].include?(param)
          raise ArgumentError, "expected #{context} to be a boolean"
        end
      when 'float'
        unless param.is_a?(Numeric)
          raise ArgumentError, "expected #{context} to be a Numeric (float)"
        end
      when 'base64', 'binary'
        unless
          param.is_a?(String) or
          (param.respond_to?(:read) and param.respond_to?(:rewind)) or
          param.is_a?(Pathname)
        then
          msg = "expected #{context} to be a string, an IO object or a "
          msg << "Pathname object"
          raise ArgumentError, msg
        end
      else
        raise ArgumentError, "unhandled type `#{rules['type']}' for #{context}"
      end
    end

    class << self

      # @param [Hash] rules
      # @param [Hash] params
      # @raise [ArgumentError] Raises an `ArgumentError` when one or more
      #   of the request parameters are invalid.
      # @return [Boolean] Returns `true` when params are valid.
      def validate! rules, params
        ParamValidator.new(rules).validate!(params)
      end

    end

  end
end
