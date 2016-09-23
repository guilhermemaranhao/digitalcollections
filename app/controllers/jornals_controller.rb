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

  def self.testar_indexacao ano, caminho_arquivo
    Jornal.indexar ano, caminho_arquivo, "somente tesseract"
    Jornal.indexar ano, caminho_arquivo, "convert tesseract"
    Jornal.indexar ano, caminho_arquivo, "convert cleaner tesseract"
  end

end

