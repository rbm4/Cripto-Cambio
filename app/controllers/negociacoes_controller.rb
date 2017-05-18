class NegociacoesController < ApplicationController
    
    def requisicao_html(header,param)
        host = 'http://www.mercadobitcoin.com.br'
        uri = URI.parse(host + '/tapi/v3/?')
        http = Net::HTTP.new(uri.host, 443)
        http.use_ssl = true
        http.ssl_version = :TLSv1
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
        request = Net::HTTP::Post.new(uri.to_s, initheader = header)
        request.set_form_data(param)
        response = http.request(request)
      
        #comparar solicitação e ver 
        return JSON.parse(response.body)
    end
    def overview_mbtc
        #requisição de informações do mercado
        cabeca, parametros = header("list_orders","BRLLTC","[4]","1")                      #fazer headers
        json = requisicao_html(cabeca,parametros)                                          #obter JSON das últimas ordens de compra feitas
        
        #informações da última compra
        qtd = json["response_data"]["orders"][0]["quantity"]
        limit = json["response_data"]["orders"][0]["limit_price"]
        fee = BigDecimal(json["response_data"]["orders"][0]["fee"],8)
        

        preco_comprado = BigDecimal(limit,8)      #valor em real comprado - deve ser obtido a partir dos métodos da api de negociações
        taxa_porcentagem    = 0.007                                             #0,7% de cada transação do mercado bitcoin
        volume_desejado_moeda = BigDecimal(qtd,8)  #quanto você quer comprar? Definido pela quantidade de crédito dentro do mercado
        tax_coin = BigDecimal((volume_desejado_moeda * taxa_porcentagem), 8)    #valor em criptomoeda de taxa na compra
        resultado_em_coin = volume_desejado_moeda - fee                    #valor obtido na compra após taxação
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
        
        @messages = ""
        @ticker_ltc = BigDecimal(hash['ticker']['last'],2) 
        @last_buy = preco_comprado
        @volume_comprado = volume_desejado_moeda
        @return = resultado_em_coin
        @profit = minimo_lucro
        @estimativa = estimativa_lucro_real
        @tax_ltc = fee
        
        #verificar última venda
        cabeca, parametros = header("list_orders","BRLLTC","[4]","2")                      #fazer headers
        vendas = requisicao_html(cabeca,parametros)                                        #receber json
        qtd = BigDecimal(vendas["response_data"]["orders"][0]["quantity"],8)               # Litecoin
        limit = BigDecimal(vendas["response_data"]["orders"][0]["limit_price"],8)          # real
        fee = BigDecimal(vendas["response_data"]["orders"][0]["fee"],8)                    # litecoin
        
    
        valor_real = (limit * qtd) 
        valor_taxado = valor_real - fee
        #cálculo de lucro a partir do preço da venda, o preço da compra
        valor_compra = limit - (fee) - (limit * 0.015)
        @limite = limit
        @volumes = qtd
        @taxado = valor_taxado
        @tax_fee = fee
        @buy_price = valor_compra
        @buy_qtd = "x"
        
        
        
    end
    
    def consultar_ordens
        @messages = ''
        host = 'http://www.mercadobitcoin.com.br'
        headers, params = header("list_orders","BRLLTC","","")
        
        #realizar solicitação HTML
        uri = URI.parse(host + '/tapi/v3/?')
        http = Net::HTTP.new(uri.host, 443)
        http.use_ssl = true
        http.ssl_version = :TLSv1
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
        request = Net::HTTP::Post.new(uri.to_s, initheader = headers)
        request.set_form_data(params)
        response = http.request(request)
      
        #comparar solicitação e ver 
        json = JSON.parse(response.body)
        @messages << "<table style='width:100%'><tr>"
        @messages << "<td>ID</td>"
        @messages << "<td>Par</td>"
        @messages << "<td>Status</td>"
        @messages << "<td>Execucoes?</td>"
        @messages << "<td>Tipo</td>"
        @messages << "<td>volume</td>"
        @messages << "<td>Preco limite</td>"
        @messages << "<td>taxa</td>"
        @messages << "</tr>"
        json["response_data"]["orders"].each do |q|
            @messages << "<tr>"
            @messages << "<td>" + q["order_id"].to_s + "</td>"
            @messages << "<td>" + q["coin_pair"].to_s + "</td>"
            #diferenciar status das ordens
            if q["status"] == 2
                @messages << "<td>Aberta</td>"
            elsif q["status"] == 3
                @messages << "<td>Cancelada</td>"
            elsif q["status"] == 4
                @messages << "<td>Concluída</td>"
            end
            @messages << "<td>" + q["has_fills"].to_s + "</td>"
            #diferenciar tipo de ordem
            if q["order_type"] == 1
                @messages << "<td>Compra</td>"
            elsif q["order_type"] == 2
                @messages << "<td>Venda</td>"
            end
            @messages << "<td>" + q["quantity"].to_s + "</td>"
            @messages << "<td>" + q["limit_price"].to_s + "</td>"
            @messages << "<td>" + q["fee"].to_s + "</td>"
            @messages << "</tr>"
        end
        @messages << "</table>"
    end
    def account_info
        @messages = ''
        host = 'http://www.mercadobitcoin.com.br'
        headers, params = header("get_account_info","","","")
        uri = URI.parse(host + '/tapi/v3/?')
        http = Net::HTTP.new(uri.host, 443)
        http.use_ssl = true
        http.ssl_version = :TLSv1
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
        request = Net::HTTP::Post.new(uri.to_s, initheader = headers)
        request.set_form_data(params)
        response = http.request(request)
      
        #comparar solicitação e ver 
        json = JSON.parse(response.body)
        a = 0
        @messages << "<p>Saldos:<p><table style='width:70%'>"
        @messages << "<td>Moeda</td>"
        @messages << "<td>Disponivel</td>"
        @messages << "<td>Total</td>"
        @messages << "<td>Ordens abertas</td>"
        json["response_data"]["balance"].each do |m|
            @messages << '<tr>'
            @messages << '<td>' + m[0].to_s.upcase + '</td>'
            @messages << '<td>' + m[1]["available"].to_s + '</td>'
            @messages << '<td>' + m[1]["total"].to_s + '</td>'
            @messages << '<td>' + m[1]["amount_open_orders"].to_s + '</td>'
            @messages << '</tr>'
        end
        @messages << "</table>"
        render 'consultar_ordens'
    end
    def cancel_order
        params["order"]["id"]
        headers, parametros = header("","")
    end
    def header(metodo,par,status,tipo)
        tapi_id = ENV['TAPI_ID_MERCADO_BTC']
        tapi_secret = ENV['TAPI_KEY_MERCADO_BTC']
        request_path = '/tapi/v3/'
        tapi_nonce = (Time.now.to_i)*1000
        if metodo == "list_orders" and status == "" and tipo == ""
            params = {
                'tapi_nonce': tapi_nonce,
                'tapi_method': metodo, 
                'coin_pair': par,
                
            }
        elsif metodo == "get_account_info"
            params = {
                'tapi_nonce': tapi_nonce,
                'tapi_method': metodo,
            }
        elsif metodo == "list_orders" and status != "" and tipo != ""
            params = {
                'tapi_nonce': tapi_nonce,
                'tapi_method': metodo,
                'status_list': status,
                'order_type': tipo,
                'coin_pair': par,
            }
        
        else
            raise 'Parâmetro de método passado errado'
        end
        params2 = URI.encode_www_form(params)
        params_string = request_path + '?' + params2
        #parâmetros gerados
        
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
        sleep(1)
        return headers, params
    end
end
