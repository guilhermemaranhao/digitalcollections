json.jornais (@jornais['hits']) do |jornal|
    json.extract! jornal, '_id'
    json.ano jornal['_source']['ano']
    json.highlight do
      json.conteudo jornal['highlight']['conteudo']
    end
end
