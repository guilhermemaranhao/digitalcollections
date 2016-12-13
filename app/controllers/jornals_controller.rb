class JornalsController < ApplicationController

  def create
    Jornal.indexar ano, caminho_arquivo, tipo_extracao
  end

  def index
    @termo=params[:termo]
    parametros={}
    @ano_selecionado=false
    if params[:anosList]
      parametros[:anosList] = params[:anosList]
      @ano_selecionado=true
    end
    resultado = JSON.parse(Jornal.pesquisar @termo, parametros)
    @jornais = resultado['hits']
    @agregacoes = resultado['aggregations']

  end

  def show
    jornal = JSON.parse(Jornal.pesquisar_jornal params[:id])
    caminho_arquivo = jornal['hits']['hits'][0]['_source']['caminho_arquivo']
    File.open(caminho_arquivo) do |f|
      send_data f.read, :type => "image/jpeg", :disposition => "inline"
    end
  end

  def self.testar_indexacao ano
    #Jornal.indexar ano, caminho_arquivo, "tika"
    Dir.foreach('arquivos/jornais') do |nome_arquivo|
      next if nome_arquivo == '.' or nome_arquivo == '..' or nome_arquivo == '.DS_Store'
      # do work on real items
      caminho_arquivo = '/Users/guilhermemaranhao/Projetos/ruby/museu_digital/app/museu_digital/arquivos/jornais/' + nome_arquivo
      Jornal.indexar ano, caminho_arquivo, "somente tesseract"
      #Jornal.indexar ano, caminho_arquivo, "convert tesseract"
      #Jornal.indexar ano, caminho_arquivo, "convert cleaner tesseract"
    end

    Dir.foreach('arquivos/revistas') do |nome_arquivo|
      next if nome_arquivo == '.' or nome_arquivo == '..'
      # do work on real items
      caminho_arquivo = '/Users/guilhermemaranhao/Projetos/ruby/museu_digital/app/museu_digital/arquivos/revistas/' + nome_arquivo
      Jornal.indexar ano, caminho_arquivo, "somente tesseract"
      #Jornal.indexar ano, caminho_arquivo, "convert tesseract"
      #Jornal.indexar ano, caminho_arquivo, "convert cleaner tesseract"
    end

  end

end

