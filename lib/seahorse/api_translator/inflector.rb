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

module Seahorse
  class ApiTranslator

    # @private
    module Inflector

      # Performs a very simple inflection on on the words as they are
      # formatted in the source API configurations.  These are *not*
      # general case inflectors.
      # @param [String] string The string to inflect.
      # @param [String,nil] format Valid formats include 'snake_case',
      #   'camelCase' and `nil` (leave as is).
      # @return [String]
      def inflect string, format = nil
        case format
        when 'camelCase' then string.camelize
        when 'snake_case' then string.underscore
        else string
        end
      end
    end

  end
end
