class KeywordsController < ApplicationController

  def index
    begin
      @resultado = JSON.parse(Keyword.pesquisar_por_parte params[:q])
      @resultado_enxuto = Array.new
      @resultado['suggest']['journal-keyword'].each do |suggestion|
       suggestion['options'].each do |sug|
         @resultado_enxuto << {:id => sug['_id'], :text => sug['text']}
        end
      end
    rescue Exception => e
      respond_to do |format|
        format.html { redirect_to new_journal_path, mensagem_erro: "Erro ao buscar palavras-chave #{e.message}"}
        @msg = "Erro ao buscar palavras-chave #{e.message}"
        format.json { render mensagem_erro: @msg }
      end
     end
  end

end