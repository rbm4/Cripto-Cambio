class SensoresController < ApplicationController
require 'open-uri'
  def display
      sensores_xml = Nokogiri::HTML(open("http://hackercidadao.com.br/embarquelab/downloads/EL_sensores.xml"))
      puts sensores_xml
  end
end
