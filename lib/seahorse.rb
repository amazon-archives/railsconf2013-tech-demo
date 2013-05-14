require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/concern'
require 'active_support/inflector'

require 'seahorse/api_translator/operation'
require 'seahorse/api_translator/shape'
require 'seahorse/api_translator/inflector'
require 'seahorse/controller'
require 'seahorse/router'
require 'seahorse/model'
require 'seahorse/operation'
require 'seahorse/type'
require 'seahorse/shape_builder'
require 'seahorse/version'

require 'seahorse/railtie' if defined?(Rails)