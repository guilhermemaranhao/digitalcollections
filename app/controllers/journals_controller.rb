class JournalsController < ApplicationController

  def create
    Journal.indexar ano, caminho_arquivo, tipo_extracao, ["palavra"]
  end

  def index
    @termo=params[:termo]
    parametros={}
    @ano_selecionado=false
    if params[:anosList]
      parametros[:anosList] = params[:anosList]
      @ano_selecionado=true
    end
    resultado = JSON.parse(Journal.pesquisar @termo, parametros)
    @jornais = resultado['hits']
    @agregacoes = resultado['aggregations']

  end

  def show
    jornal = JSON.parse(Journal.pesquisar_jornal params[:id])
    caminho_arquivo = jornal['hits']['hits'][0]['_source']['caminho_arquivo']
    File.open(caminho_arquivo) do |f|
      send_data f.read, :type => "image/jpeg", :disposition => "inline"
    end
  end

  def self.testar_indexacao

    # Indexa palavras-chave
    Keyword::LISTA_KEYWORDS.each do |palavra|
      Keyword.indexar palavra
    end

    #Journal.indexar ano, caminho_arquivo, "tika"
    Dir.foreach('arquivos/jornais') do |nome_arquivo|
      next if nome_arquivo == '.' or nome_arquivo == '..' or nome_arquivo == '.DS_Store'
      # do work on real items
      caminho_arquivo = $files_path + '/jornais/' + nome_arquivo

      lista_palavras_jornal = JournalsController.obtem_palavras_chave
      ano = JournalsController.obtem_ano

      Journal.indexar ano, caminho_arquivo, "somente tesseract", lista_palavras_jornal
      #Journal.indexar ano, caminho_arquivo, "convert tesseract"
      #Journal.indexar ano, caminho_arquivo, "convert cleaner tesseract"
    end

    Dir.foreach('arquivos/revistas') do |nome_arquivo|
      next if nome_arquivo == '.' or nome_arquivo == '..'
      # do work on real items
      caminho_arquivo = $files_path + '/revistas/' + nome_arquivo

      lista_palavras_revista = JournalsController.obtem_palavras_chave
      ano = JournalsController.obtem_ano

      Journal.indexar ano, caminho_arquivo, "somente tesseract", lista_palavras_revista
      #Journal.indexar ano, caminho_arquivo, "convert tesseract"
      #Journal.indexar ano, caminho_arquivo, "convert cleaner tesseract"
    end

  end

  private

  def self.obtem_palavras_chave

    # Obtem número randômico para quantidade de palavras-chaves para o jornal
    rand = Random.new
    quantidade = rand.rand(0..10)

    indices_escolhidos = Array.new
    lista_palavras = Array.new
    if quantidade > 0
      for i in 1..quantidade
        novo_rand = Random.new
        indice = novo_rand.rand(0..9)
        while (indices_escolhidos.include? indice)
          indice = novo_rand.rand(0..9)
        end
        indices_escolhidos << indice
        lista_palavras << Keyword::LISTA_KEYWORDS[indice]
      end
    end

    return lista_palavras
  end

  def self.obtem_ano

    # obter ano
    rand_ano = Random.new
    indice_ano = rand_ano.rand(0..5)
    ano = Journal::LISTA_ANOS[indice_ano]

    return ano
  end

end

