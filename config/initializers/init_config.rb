require 'yaml'

CONF = YAML.load_file(Rails.root.join('config/config.yml'))[Rails.env]