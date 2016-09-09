# Tika server start:
# java -Xmx4024m -cp /opt/tika:/opt/tika/custom-properties:/opt/tika/custom-properties/jbig2_1.4.jar:/opt/tika/tika-server-1.13.jar:/opt/tika/custom-prorties/org/apache/tika/parser/ocr/TesseractOCRConfig.properties:/opt/tika/custom-properties/org/apache/tika/parser/pdf/PDFParser.properties org.apache.tika.server.TikaServerCli --host=0.0.0.0  --port=9998

class ExtracaoConteudoArquivo

  def self.extrair(caminho_arquivo)

    if caminho_arquivo.present?
      tika_app_path = File.join(Rails.root, 'lib', 'tika', 'tika-app-1.12.jar')
      cleaner = File.join(Rails.root, 'lib', 'tika', 'textcleaner')
      tika_custom_classpath = File.join(Rails.root, 'lib', 'tika', 'custom-properties')
      java_home = CONF['java_home']
      ENV['PATH'] = "#{java_home}/bin:#{ENV['PATH']}"
      if File.exists?(tika_app_path)
          caminho_do_arquivo_tiff = ''
            conteudo_do_arquivo = ''
            caminho_do_arquivo = caminho_arquivo


            #COPIANDO PARA PASTA TEMPORÁRIA, PQ NEM SEMPRE O PROGRAMA CONSEGUE LER
            match_file = caminho_do_arquivo.match(/([a-z0-9]+)\.([a-z0-9]+)$/i)
            caminho_do_arquivo_tmp = "/tmp/#{match_file[1]}.#{match_file[2]}"
            `cp #{caminho_do_arquivo} #{caminho_do_arquivo_tmp}`
            tempo = Time.now
            # size = `stat --printf="%s" #{caminho_do_arquivo_tmp}`.to_i
            # while((!File.exist?(caminho_do_arquivo_tmp) || size <= 100 || size != `stat --printf="%s" #{caminho_do_arquivo_tmp}`.to_i) && (Time.now - tempo) < 1.minute) do
            #   size = `stat --printf="%s" #{caminho_do_arquivo_tmp}`.to_i
            #   sleep 1
            # end
            # if size.to_i <= 2
            #   raise "#{caminho_do_arquivo} Arquivo não copiado para #{caminho_do_arquivo_tmp} | #{size}"
            # end
            # FIM BLOCO

              begin

                server = 'http://0.0.0.0:9998'

                puts 'Starting... '+caminho_do_arquivo
                stdout = ''

                stdout = `curl -T #{caminho_do_arquivo_tmp} #{server}/tika`
                stdout.strip!

                # BLOCO DE OCR PASSANDO O META TYPE: O 1o curl é para pegar o content_type, o 2o é para tentar extrair o conteúdo
                if !stdout.present?
                  stdout_meta = `curl -T #{caminho_do_arquivo} #{server}/meta`
                  if (stdout_meta.match(/"Content-Type","(.*)\"/))
                    meta_type = stdout_meta.match(/"Content-Type","(.*)\"/)[1]
                    if !meta_type.blank?
                      # stdout = `curl -T #{caminho_do_arquivo_tmp} #{server}/tika  --header \"Content-type: #{meta_type}\" --header \"Accept: text/plain\" --header \"Accept-Charset: utf-8\"`
                      stdout = `curl -T #{caminho_do_arquivo_tmp} #{server}/tika  --header \"Content-type: #{meta_type}\" --header \"Accept: text/plain\"`
                      stdout.strip!
                    end
                  end

                  if !stdout.present? && !caminho_do_arquivo_tmp.match(/(\.odt$|\.doc$|\.docx$)/).nil?
                    `unoconv -fpdf #{caminho_do_arquivo_tmp}`
                    if File.exist?(caminho_do_arquivo_tmp.gsub(/(\.odt$|\.doc$|\.docx$)/, '.pdf'))
                      `rm #{caminho_do_arquivo_tmp}`
                      caminho_do_arquivo_tmp = caminho_do_arquivo_tmp.gsub(/(\.odt$|\.doc$|\.docx$)/, '.pdf')
                      stdout = `curl -T #{caminho_do_arquivo_tmp} #{server}/tika --header "X-Tika-OCRLanguage: por" --header "X-Tika-OCRTimeout: 1800"`
                      if !stdout.present?
                        `cp #{caminho_do_arquivo_tmp} ~/`
                        str = "#{caminho_do_arquivo} | Documento convert or parsing fail! | unoconv -fpdf #{caminho_do_arquivo_tmp} | "
                        str << "curl -T #{caminho_do_arquivo_tiff} #{server}/tika --header \"X-Tika-OCRLanguage: por\" --header \"X-Tika-OCRTimeout: 1800\" | "
                        raise str
                      end
                    end
                  end
                end
                # FIM BLOCO

                # BLOCO DA SEGUNDA TENTATIVA DE EXTRAÇÃO DE CONTEÚDO PELO TIKA
                if !stdout.present?
                  stdout = `curl -T #{caminho_do_arquivo_tmp} #{server}/tika`
                  stdout.strip!
                end
                # FIM BLOCO


                # BLOCO DE EXTRAÇÃO DE CONTEÚDO CONVERTENDO O ARQUIVO PARA TIFF, QUE SERÁ PROCESSADO PELO TIKA
                if !stdout.present?
                  match_file = caminho_do_arquivo_tmp.match(/([a-z0-9]+)\.([a-z0-9]+)$/i)
                  caminho_do_arquivo_tiff = "/tmp/#{match_file[1]}.tiff"

                  # Conversão do arquivo para TIFF
                  # `gs -sDEVICE=tiffgray -r200 -dINTERPOLATE -dTextAlphaBits=4 -dFirstPage=1 -dLastPage=30 -o #{caminho_do_arquivo_tiff} #{caminho_do_arquivo}`
                  # `gs -sDEVICE=tiffgray -r200 -dINTERPOLATE -dTextAlphaBits=4 -o #{caminho_do_arquivo_tiff} #{caminho_do_arquivo}`
                  if File.exist?(caminho_do_arquivo_tmp)
                    # `gs -q -dNOPAUSE -sDEVICE=tiffgray -r200 -dINTERPOLATE -dTextAlphaBits=4 -sOutputFile=#{caminho_do_arquivo_tiff} #{caminho_do_arquivo_tmp} -c quit`
                    `gs -sDEVICE=tiffgray -r200 -dINTERPOLATE -dTextAlphaBits=4 -o #{caminho_do_arquivo_tiff} #{caminho_do_arquivo_tmp}`

                    # size = `stat --printf="%s" #{caminho_do_arquivo_tiff}`.to_i
                    # while((!File.exist?(caminho_do_arquivo_tiff) || size <= 100 || size != `stat --printf="%s" #{caminho_do_arquivo_tiff}`.to_i) && (Time.now - tempo) < 1.minute) do
                    #   size = `stat --printf="%s" #{caminho_do_arquivo_tiff}`.to_i
                    #   sleep 1
                    # end

                  else
                    puts "rm -f #{caminho_do_arquivo_tmp}"
                    `rm -f #{caminho_do_arquivo_tmp}`
                    raise "#{caminho_do_arquivo_tmp} não encontrado!"
                  end

                  # O CLEANER FOI REMOVIDO PORQUE LIMITA O ARQUIVO SOMENTE À PRIMEIRA PÁGINA
                  # caminho_do_arquivo_tiff_clean = caminho_do_arquivo_tiff.gsub('.tiff', '.clean.tiff')
                  # `#{cleaner} -u -T -p 10 #{caminho_do_arquivo_tiff} #{caminho_do_arquivo_tiff_clean}`

                  # stdout = `curl -T #{caminho_do_arquivo_tiff} #{server}/tika  --header \"Content-type: image/tiff\" --header \"X-Tika-OCRLanguage: por\" --header \"X-Tika-OCRTimeout: 600\"`
                  stdout = `curl -T #{caminho_do_arquivo_tiff} #{server}/tika --header "X-Tika-OCRLanguage: por" --header "X-Tika-OCRTimeout: 1800"`
                  stdout.strip!

                end

                puts 'Extração finalizada! '+caminho_do_arquivo

                # CHECAGEM SE O CONTEÚDO DO ARQUIVO FOI EXTRAÍDO, SE NÃO FOI, GERAR ERRO PARA O REDIS DEIXAR COMO ERRO
                if !stdout.present?
                  str_error = "#{caminho_do_arquivo} | #{server} "
                  if File.exist?(caminho_do_arquivo_tiff)
                    # str_error << " Size: "
                    # str_error << `stat --printf="%s" #{caminho_do_arquivo_tmp}`
                    # str_error << " | "
                    # str_error << `stat --printf="%s" #{caminho_do_arquivo_tiff}`
                    # str_error << " === "
                    # str_error << "curl -T #{caminho_do_arquivo_tiff} #{server}/tika  --header \"Content-type: image/tiff\" --header \"X-Tika-OCRLanguage: por\" --header \"X-Tika-OCRTimeout: 1800\" "
                  else
                    str_error << " Tiff não gerado"
                  end
                  str_error << " | curl -T #{caminho_do_arquivo_tiff} #{server}/tika  --header \"Content-type: image/tiff\" --header \"X-Tika-OCRLanguage: por\" --header \"X-Tika-OCRTimeout: 1800\" || IdObjTram: "

                  `rm -f #{caminho_do_arquivo_tiff}`
                  `rm -f #{caminho_do_arquivo_tmp}`
                  raise str_error

                  # puts "java -Dfile.encoding=UTF8 -Xmx512m -cp #{tika_custom_classpath}/levigo-jbig2-imageio-1.6.1.jar:#{tika_custom_classpath}/jai_imageio-1.1.jar:#{tika_app_path}:#{tika_app_path}:$CLASSPATH org.apache.tika.cli.TikaCLI -t #{caminho_do_arquivo_tiff}"
                  # puts "java -Dfile.encoding=UTF8 -Xmx512m -cp #{tika_custom_classpath}/jai_imageio-1.1.jar:#{tika_custom_classpath}/jbig2_1.4.jar:#{tika_custom_classpath}/levigo-jbig2-imageio-1.6.1.jar:#{tika_app_path} org.apache.tika.cli.TikaCLI -t #{caminho_do_arquivo_tiff}"
                  # stdout = `java -Dfile.encoding=UTF8 -Xmx512m -cp #{tika_custom_classpath}/jai_imageio-1.1.jar:#{tika_custom_classpath}/jbig2_1.4.jar:#{tika_custom_classpath}/levigo-jbig2-imageio-1.6.1.jar:#{tika_app_path} org.apache.tika.cli.TikaCLI -t #{caminho_do_arquivo_tiff}`
                  # stdout.strip!

                end
                `rm -f #{caminho_do_arquivo_tiff}`
                `rm -f #{caminho_do_arquivo_tmp}`

                conteudo_do_arquivo = stdout.to_s

                # TENTATIVA DE LIMPEZA DE LIXO DO CONTEÚDO DO ARQUIVO, ISSO É APENAS UM PALEATIVO
                conteudo_do_arquivo = conteudo_do_arquivo.gsub(/[\“\”\"\'\\\']/m, ' ').gsub(/[\n\t\r]/m, ' ').gsub(/\s+/m, ' ').strip
                # conteudo_do_arquivo = JSON.generate(conteudo_do_arquivo, :quirks_mode => true)
                # conteudo_do_arquivo = conteudo_do_arquivo.gsub(/\"/, '')
                # conteudo_do_arquivo = conteudo_do_arquivo.gsub(/\\/, '')

                conteudoBase64 = Base64.encode64(conteudo_do_arquivo)


              rescue Exception => e
                `rm -f #{caminho_do_arquivo_tiff}`
                `rm -f #{caminho_do_arquivo_tmp}`

                puts "***** Erro ao extrair conteúdo de arquivo #{caminho_arquivo} *****"
                puts e.message
                raise e
              end




          if !caminho_do_arquivo_tiff.empty?
            `rm -f #{caminho_do_arquivo_tiff}`
          end


    end

    end
  end

end
