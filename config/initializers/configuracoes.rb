elasticsearch_configs = Rails.application.config_for 'elasticsearch/elasticsearch_config'

Rails.application.configure do
  config.elasticsearch_configuracoes = ActiveSupport::OrderedOptions.new
  config.elasticsearch_configuracoes.host = elasticsearch_configs['elasticsearch_host']
  config.elasticsearch_configuracoes.nome_indice = elasticsearch_configs['nome_indice']
end