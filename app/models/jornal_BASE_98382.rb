class Jornal
  include Elasticsearch::API

  CONNECTION = ::Faraday::Connection.new url: 'http://localhost:9200'

  ANALISADOR = '{
  "index" : {
    "analysis" : {
      "analyzer" : {
        "analisador-jornal": {
          "type" : "snowball",
          "language" : "Portuguese"
        }
      }
    }
   }
  }'

  MAPEAMENTO = '{
      "mappings" : {
          "jornal" : {
            "properties" : {
                "ano" : {"type" : "integer", "index" : "not_analyzed"},
                "caminho_arquivo" : {"type": "string", "index": "not_analyzed"},
                "jornal_thumb" : {"type": "string", "index": "not_analyzed"},
                "conteudo_arquivo" : {"type": "string", "analyzer": "analisador-jornal"}
            }
          }
      }
  }'

  def perform_request method, path, params, body
    puts "--> #{method.upcase} #{path} #{params} #{body}"

    CONNECTION.run_request method.downcase.to_sym,
                           path,
                           (body ? MultiJson.dump(body) : nil),
                           {'Content-Type' => 'application/json'}
  end

  def self.mapear

    `curl -XPOST http://localhost:9200/museu_digital/_close`

    `curl -XPUT http://localhost:9200/museu_digital/_settings -d'
        #{ANALISADOR}'`

    `curl -XPOST http://localhost:9200/museu_digital/_open`

    stdout = `curl -XPOST http://localhost:9200/museu_digital -d'
        #{MAPEAMENTO}'`
  end

  def self.indexar ano, caminho_arquivo
    conteudo = Jornal.extrair_conteudo_arquivo caminho_arquivo
    client = Jornal.new

    diretorio_relativo = "thumbs/"
    nome_thumbnail = File.basename(caminho_arquivo, File.extname(caminho_arquivo)) << "_thumb.png"
    caminho_relativo = diretorio_relativo << nome_thumbnail

    novo_jornal = {
        ano: ano,
        caminho_arquivo: caminho_arquivo,
        jornal_thumb: caminho_relativo,
        conteudo: conteudo
    }

    caminho_absoluto = Rails.root.join('app', 'assets', 'images', 'thumbs') + nome_thumbnail

    stdout_thumbnail = `convert #{caminho_arquivo} -thumbnail 120x90 #{caminho_absoluto}`

    p client.index index: 'museu_digital', type: 'jornal', body: novo_jornal

  end

  def self.pesquisar termo, options={}
    query = Jornal.definir_pesquisa termo, options
    client = Jornal.new
    p client.search index: 'museu_digital', body: query
  end

  def self.pesquisar_jornal id

    url = "http://localhost:9200/museu_digital/jornal/#{id}"

    search_definition = {
        _source: ['caminho_arquivo'],
        query: { term: { _id: id}}
    }

    client = Jornal.new
    p client.search index: 'museu_digital', body: search_definition
  end

  private

  def self.definir_pesquisa termo, options={}

    search_definition = {
        _source: ['ano', 'jornal_thumb'],
        aggs: {},
        highlight: {},
        query: {}
    }

    search_definition[:aggs] = definir_clausula_aggregation
    search_definition[:highlight] = definir_clausula_highlight
    search_definition[:query] = definir_clausula_query termo
    if !options.empty?
      incluir_agregacao search_definition, options
    end
    return search_definition
  end

  def self.definir_clausula_aggregation
    aggregation = {
      ano: { terms: {field: 'ano'}}
    }
  end

  def self.definir_clausula_highlight
    highlight = {
        pre_tags: ["<b>"],
        post_tags: ["</b>"],
        fragment_size: 150,
        number_of_fragments: 3,
        fields: {
            ano: { require_field_match: false },
            conteudo: { require_field_match: false }
        }
    }
  end

  def self.definir_clausula_query termo
    query_clause = {
        bool: {
            must: [
              {
                  query_string: {
                      query: termo
                  }
              }
            ]
        }
    }
  end

  def self.incluir_agregacao search_definition, options

    if options[:ano]
      termo_ano = {}
      termo_ano[:term] = {}
      termo_ano[:term][:ano] = {}
      termo_ano[:term][:ano] = options[:ano]
      search_definition[:query][:bool][:must] << termo_ano
    end
  end

  def self.extrair_conteudo_arquivo caminho_do_arquivo
    #stdout = `java -jar lib/tika/tika-app-1.12.jar -t #{caminho_do_arquivo}`
    #stdout = `tesseract #{caminho_do_arquivo} stdout -l por+eng`
    stdout_tiff = `convert #{caminho_do_arquivo} -type Grayscale stdout`
    stdout = `tesseract #{stdout_tiff} stdout -l por+eng`
    conteudo_formatado = stdout.gsub(/[\n\t\r]/m, ' ').gsub(/\s+/m, ' ').strip
    return conteudo_formatado
  end

end