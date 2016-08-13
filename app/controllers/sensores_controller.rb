class SensoresController < ApplicationController
require 'open-uri'
  def display
      sensores_xml = Nokogiri::HTML(open("http://hackercidadao.com.br/embarquelab/downloads/EL_sensores.xml"))
      valor = sensores_xml.xpath("//valor")
      minimo = sensores_xml.xpath("//minimo")
      maximo = sensores_xml.xpath("//maximo")
      descricao = sensores_xml.xpath("//descricao")
      tipo = sensores_xml.xpath("//tipo")
      sensores = Hash.new
      for x in [4, 5, 6, 7, 15] do
          if x == 5
            puts'temperatura1'
            @temperatura1 = [String(valor[x]),String(minimo[x]),String(maximo[x]),String(descricao[x]),String(tipo[x])]
          end
          if x == 7
            puts'temperatura2'
            @temperatura2 = [String(valor[x]),String(minimo[x]),String(maximo[x]),String(descricao[x]),String(tipo[x])]
          end
          if x == 15
            puts'temperatura3'
            @temperatura1 = [String(valor[x]),String(minimo[x]),String(maximo[x]),String(descricao[x]),String(tipo[x])]
          end
          if x == 4
            puts'umidade1'
            @umidade1 = [String(valor[x]),String(minimo[x]),String(maximo[x]),String(descricao[x]),String(tipo[x])]
          end
          if x == 6
            puts'umidade2'
            @umidade2 = [String(valor[x]),String(minimo[x]),String(maximo[x]),String(descricao[x]),String(tipo[x])]
          end
      end
      
      @temperatura2 = sensores[7]
      @temperatura3 = sensores[15]
      @umidade1 = sensores[4]
      @umidade2 = sensores[6]
      print(@temperatura1)
  end
end
