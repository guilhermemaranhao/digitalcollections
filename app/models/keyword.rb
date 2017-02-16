class Keyword
  include Elasticsearch::API

  LISTA_KEYWORDS = ["eleição", "carnaval", "política", "copa do mundo", "segunda guerra mundial",
                                    "turismo", "ditadura", "pedra caída", "praia do tocantins", "as cachoeiras do itapecuru"]

  CONNECTION = ::Faraday::Connection.new url: $elasticsearch_host

  def perform_request method, path, params, body
    puts "--> #{method.upcase} #{path} #{params} #{body}"

    CONNECTION.run_request method.downcase.to_sym,
                           path,
                           (body ? MultiJson.dump(body) : nil),
                           {'Content-Type' => 'application/json'}
  end

  def self.indexar word

    new_indexed_keyword = {
        name: word
    }

    client = Keyword.new
    p client.index index: 'digital_collections', type: 'keyword', body: new_indexed_keyword
  end


  def self.pesquisar_por_parte termo

    search_definition = {
        suggest: {}
    }
    search_definition[:suggest] = definir_suggestion termo

    client = Journal.new
    return client.search index: 'digital_collections', type: 'keyword', body: search_definition

  end

  private

  def self.definir_suggestion termo

    query = {
        "journal-keyword": {
            "prefix": termo,
            "completion": {
            "field": "name"
            }
        }
    }

  end

end