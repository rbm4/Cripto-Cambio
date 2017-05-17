class NegociacoesController < ApplicationController
    
    
    def notifications
        preco_comprado = 105                                                    #valor em real comprado - deve ser obtido a partir dos métodos da api de negociações
        taxa_porcentagem    = 0.007                                             #0,7% de cada transação do mercado bitcoin
        volume_desejado_moeda = 0.0809                                               #quanto você quer comprar? Definido pela quantidade de crédito dentro do mercado
        tax_coin = BigDecimal((volume_desejado_moeda * taxa_porcentagem), 8)    #valor em criptomoeda de taxa na compra
        resultado_em_coin = volume_desejado_moeda - tax_coin                    #valor obtido na compra após taxação
        #Acima, são os cálculos de compra
        #Abaixo são os cálculos de quanto é preciso vender a quanto para obter lucro
        
        taxa_lucro = 1.017                                                      #necessário para lucrar a partir do preco_comprado
        minimo_lucro= preco_comprado * taxa_lucro                               #porcentagem de venda no valor de [hash['ticker']['sell'] tirando o lucro e a taxa do mercado
        tax_real = tax_coin * minimo_lucro                                      #taxa em real no ato da venda
        estimativa_lucro_real = (minimo_lucro * resultado_em_coin) - tax_real
        
        convert_url = 'https://www.mercadobitcoin.com.br/api/ticker_litecoin/'
        convert_uri = URI(convert_url)
        response_convert = Net::HTTP.get(convert_uri)
        hash = JSON.parse(response_convert)
        #preco_unitario = BigDecimal(hash['ticker']['last'],2)
        
         
        @messages = "Preço de compra do ultimo litecoin #{hash['ticker']['last']} BRL no Mercado Bitcoin<br><br>Você comprou litecoin na sua ultima compra a preço unitário de #{preco_comprado} BRL, com volume de #{volume_desejado_moeda} LTC<br>Obtendo de retorno #{resultado_em_coin}"
        @messages << "<br>Para Obter lucro, você precisará vender as #{resultado_em_coin} a um preço de, no mínimo, #{minimo_lucro} para ter #{estimativa_lucro_real} em créditos no exchange"
        @messages << "<br>"
        render 'sessions/loginerror'
    end
    
    def consultar_ticker
        @messages = ''
        tapi_id = ENV['TAPI_ID_MERCADO_BTC']
        tapi_secret = ENV['TAPI_KEY_MERCADO_BTC']
        #tapi_secret = "1ebda7d457ece1330dff1c9e04cd62c4e02d1835968ff89d2fb2339f06f73028"
        host = 'http://www.mercadobitcoin.com.br'
        request_path = '/tapi/v3/'
        tapi_nonce = (Time.now.to_i)*1000
        params = {
            'tapi_nonce': tapi_nonce,
            'tapi_method': 'list_orders', 
            'coin_pair': "BRLLTC",
            
        }
        p params
        params2 = URI.encode_www_form(params)
        params_string = request_path + '?' + params2
        #params_string = "/tapi/v3/?tapi_method=list_orders&tapi_nonce=1"
        #parâmetros gerados
        #1494977670719
        #1494985086
        
        a = OpenSSL::Digest.new('sha512')
        #gerar hmac
        h = OpenSSL::HMAC.new(tapi_secret, a)
        h.update(params_string)
        tapi_mac = h.hexdigest()
        # Gerar cabeçalho da requisição
        headers = {
            'Content-type': 'application/x-www-form-urlencoded',
            'TAPI-ID': tapi_id,
            'TAPI-MAC': tapi_mac
        }
        
        #uri = URI.parse(host + params_string)
        uri = URI.parse(host + '/tapi/v3/?')
        #htp = Net::HTTP::Post.new(a)
        http = Net::HTTP.new(uri.host, 443)
        http.use_ssl = true
        http.ssl_version = :TLSv1
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
        request = Net::HTTP::Post.new(uri.to_s, initheader = headers)
        request.set_form_data(params)
        response = http.request(request)
      
        #response = htp.request(uri.path, headers)
        json = JSON.parse(response.body)
        @messages << "<table style='width:100%;padding: 15px;'><tr>"
        @messages << "<th>ID</th>"
        @messages << "<th>Par<th>"
        @messages << "<th>Status</th>"
        @messages << "<th>Execucoes?</th>"
        @messages << "<th>Tipo</th>"
        @messages << "<th>volume</th>"
        @messages << "<th>Preco limite</th>"
        @messages << "<th>taxa</th>"
        @messages << "</tr>"
        json["response_data"]["orders"].each do |q|
            @messages << "<th>" + q["order_id"].to_s + "</th>"
            @messages << "<th>" + q["coin_pair"].to_s + "</th>"
            @messages << "<th>" + q["status"].to_s + "</th>"
            @messages << "<th>" + q["has_fills"].to_s + "</th>"
            @messages << "<th>" + q["order_type"].to_s + "</th>"
            @messages << "<th>" + q["quantity"].to_s + "</th>"
            @messages << "<th>" + q["limit_price"].to_s + "</th>"
            @messages << "<th>" + q["fee"].to_s + "</th>"
            @messages << "</tr>"
        end
        @messages << "</table>"
        render 'sessions/loginerror'
    end
end
