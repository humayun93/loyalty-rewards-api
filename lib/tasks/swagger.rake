require 'yaml'
require 'json'

namespace :swagger do
  desc 'Convert YAML to JSON for Swagger UI'
  task generate_json: :environment do
    swagger_dir = Rails.root.join('swagger')
    Dir.glob(File.join(swagger_dir, '**', '*.yaml')).each do |yaml_file|
      yaml_content = YAML.load_file(yaml_file)
      json_file = yaml_file.sub(/\.yaml\z/, '.json')
      
      File.open(json_file, 'w') do |file|
        file.write(JSON.pretty_generate(yaml_content))
      end
      
      puts "Generated #{json_file} from #{yaml_file}"
    end
  end
end 