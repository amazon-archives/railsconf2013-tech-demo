require 'oj'

namespace :seahorse do
  desc 'Builds API clients'
  task :api => :environment do
    filename = 'service.json'
    service = {
      'format' => 'rest-json',
      'type' => 'rest-json',
      'endpoint_prefix' => '',
      'operations' => {}
    }

    Dir.glob("#{Rails.root}/app/models/api/*.rb").each {|f| load f }
    Seahorse::Model.apis.values.each do |api|
      service['operations'].update(api.to_hash['operations'])
    end

    File.open(filename, 'w') do |f|
      f.puts(Oj.dump(service, indent: 2))
    end
    puts "Wrote service description: #{filename}"
  end
end
