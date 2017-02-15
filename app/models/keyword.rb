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

  def pesquisar_por_parte termo

    # search_definition = {
    #     query: definir_query termo
    # }

  end

  def self.indexar word

    new_indexed_keyword = {
        name: word
    }

    client = Keyword.new
    p client.index index: 'digital_collections', type: 'keyword', body: new_indexed_keyword
  end

  private

  def definir_query termo

    # query = {
    #     match: {
    #
    #     }
    # }

  end

end