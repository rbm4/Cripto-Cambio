class SensoresController < ApplicationController
require 'open-uri'
require 'gchart'
require "csv"
  def display
      @array1 = Array.new
      @array1x = Array.new
      Temp1.all.each do |p|
        @array1.append(p.valor)
        @array1x.append(p.created_at)
      end
      @array2 = Array.new
      @sensor2 = Temp2.all.each do |t|
        @array2.append(t.valor)
      end
      @array3 = Array.new
      @sensor3 = Temp3.all.each do |y|
        @array3.append(y.valor)
      end
      @uarray1 = Array.new
      @usensor1 = Umi1.all.each do |j|
        @uarray1.append(j.valor)
      end
      @uarray2 = Array.new
      @usensor2 = Umi2.all.each do |k|
        @uarray2.append(k.valor)
      end
      
      print @array2
      sensores_xml = Nokogiri::HTML(open("http://hackercidadao.com.br/embarquelab/downloads/EL_sensores.xml"))
      valor = sensores_xml.xpath("//valor")
      minimo = sensores_xml.xpath("//minimo")
      maximo = sensores_xml.xpath("//maximo")
      descricao = sensores_xml.xpath("//descricao")
      tipo = sensores_xml.xpath("//tipo")
      for x in [4, 5, 6, 7, 15] do
          if x == 5
            puts'temperatura1'
            temperatura1 = [String(valor[x]),String(minimo[x]),String(maximo[x]),String(descricao[x]),String(tipo[x])]
          end
          if x == 7
            puts'temperatura2'
            temperatura2 = [String(valor[x]),String(minimo[x]),String(maximo[x]),String(descricao[x]),String(tipo[x])]
          end
          if x == 15
            puts'temperatura3'
            temperatura3 = [String(valor[x]),String(minimo[x]),String(maximo[x]),String(descricao[x]),String(tipo[x])]
          end
          if x == 4
            puts'umidade1'
            umidade1 = [String(valor[x]),String(minimo[x]),String(maximo[x]),String(descricao[x]),String(tipo[x])]
          end
          if x == 6
            puts'umidade2'
            umidade2 = [String(valor[x]),String(minimo[x]),String(maximo[x]),String(descricao[x]),String(tipo[x])]
          end
      end
      print(temperatura1)
      print(temperatura2)
      print(temperatura3)
      print(umidade1)
      print(umidade2)
      @todos = [temperatura1,temperatura2,temperatura3,umidade1,umidade2]
  end
  def mjolnir
  end
  def smart
    quote_chars = %w(" | ~ ^ & *)
    @result = Array.new
    CSV.open('bairros.csv', 'wb') do |csv|
      CSV.foreach("#{Rails.root}/public/Sedec_solicitacoes.csv", :headers => ["solicitacao_bairro"]) do |row|
        row['solicitacao_bairro'] = row['solicitacao_bairro'].to_s
        csv << row
      end
    end
    puts @result
  end
  def values
   render json: Temp1.group_by_day(:created_at, format: "%B %d, %Y").pluck(:valor)
  end
  helper_method :values
end