module Seahorse
  class Railtie < Rails::Railtie
    rake_tasks do
      load File.dirname(__FILE__) + '/../tasks/seahorse_tasks.rake'
    end
  end
end
