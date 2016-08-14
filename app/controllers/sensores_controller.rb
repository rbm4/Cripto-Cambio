class SensoresController < ApplicationController
require 'open-uri'
  def display
      @sensor1 = Temp1.all
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
  def charte
  end
end
