class JornalsController < ApplicationController

  def create
    Jornal.indexar ano, caminho_arquivo
  end

  def index
    @termo=params[:termo]
    parametros={}
    @ano_selecionado=false
    if params[:ano]
      parametros[:ano] = params[:ano]
      @ano_selecionado=true
    end
    resultado = JSON.parse(Jornal.pesquisar @termo, parametros)
    @jornais = resultado['hits']
    @agregacoes = resultado['aggregations']

  end

  def show
    jornal = JSON.parse(Jornal.pesquisar_jornal params[:id])
    caminho_arquivo = jornal['hits']['hits'][0]['_source']['caminho_arquivo']
    send_file(caminho_arquivo, :filename => "jornal.pdf", :disposition => 'inline', :type => "application/pdf")
  end

  def self.testar_indexacao ano, caminho_arquivo
    Jornal.indexar ano, caminho_arquivo
  end

end

