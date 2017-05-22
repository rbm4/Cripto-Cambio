class Mbtc < ActiveRecord::Base
    def requisicao_html(header,param)
        host = "http://www.mercadobitcoin.com.br"
        uri = URI.parse(host + "/tapi/v3/?")
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
    def overview_mbtc(secret,key)
        #requisição de informações do mercado
        cabeca, parametros = header("list_orders","BRLLTC","[4]","1","",secret,key)                      #fazer headers
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
        minimo_lucro= preco_comprado * taxa_lucro                               #porcentagem de venda no valor de [hash["ticker"]["sell"] tirando o lucro e a taxa do mercado
        tax_real = tax_coin * minimo_lucro                                      #taxa em real no ato da venda
        estimativa_lucro_real = (minimo_lucro * resultado_em_coin) - tax_real
        
        convert_url = "https://www.mercadobitcoin.com.br/api/ticker_litecoin/"
        convert_uri = URI(convert_url)
        response_convert = Net::HTTP.get(convert_uri)
        hash = JSON.parse(response_convert)
        #preco_unitario = BigDecimal(hash["ticker"]["last"],2)
        
        @messages = ""
        @ticker_ltc = hash["ticker"]["buy"]
        @last_buy = preco_comprado
        @volume_comprado = volume_desejado_moeda
        @return = resultado_em_coin
        @profit = minimo_lucro
        @estimativa = estimativa_lucro_real
        @tax_ltc = fee
        
        #verificar última venda
        cabeca, parametros = header("list_orders","BRLLTC","[4]","2","",secret,key)                      #fazer headers orderm btc/ltc abertas
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
        
        
        #verificar saldos
        account_inf = account_info(secret,key)
        account_inf["response_data"]["balance"].each do |m|
            if m[0].to_s.upcase == "BRL"
                @real_saldo = m[1]["available"].to_s
            elsif m[0].to_s.upcase == "BTC"
                @btc_saldo = m[1]["available"].to_s
                if m[1]["amount_open_orders"] >= 1
                    @btc_orders = m[1]["amount_open_orders"]
                end
            elsif m[0].to_s.upcase == "LTC"
                @ltc_saldo = m[1]["available"].to_s
                if m[1]["amount_open_orders"] >= 1
                    @ltc_orders = m[1]["amount_open_orders"]
                end
            end
        end
        
        #verificar ordem de compra, cancelar e criar com 1% abaixo do valor de @ticker_ltc
        #verificar se preço atual de venda está acima do preço mínimo para lucro:
        if @profit <= hash["ticker"]["sell"] #se sim, coloque o preço para venda a mais
           @sell_price_ltc = hash["ticker"]["sell"] * 1.01
        else                    
           @sell_price_ltc = @profit 
        end
        
        
        #verificar se o preço de compra está muito abaixo do ticker, ajustar caso diferença maior que 2%
        if @buy_price <= (hash["ticker"]["buy"]*0.97) #preço de compra menor que o atual. É mais de 2%?
            @buy_price_ltc = @ticker_ltc * 0.985
        elsif @buy_price >= hash["ticker"]["buy"] #preço de compra é maior que o ticker atual
            @buy_price_ltc = @ticker_ltc * 0.985
        else
            @buy_price_ltc = @buy_price
        end
        @warnings = "<br>Você precisa vender suas litecoins a um preço de <b>R$#{@sell_price_ltc}</b><br>E comprar litecoin a um preço de <b>R$#{@buy_price_ltc}</b>"
        
        a_cabeca, a_parametros = header("list_orders","BRLLTC","[2]","","",secret,key)
        a_json = requisicao_html(a_cabeca, a_parametros)
        
        ordens_compra = []
        ordens_venda = []
        a_json["response_data"]["orders"].each do |h|
            if h["status"] == 2 and h["order_type"] == 1
                ordens_compra.append(h["order_id"])
                @warnings << "<br>Ordem #{h["order_id"]} é uma ordem de compra de <b>#{h["quantity"]} LTC</b>, pelo preço unitário de #{h["limit_price"]}"
                if BigDecimal(h['limit_price'],2) <= (@ticker_ltc * 0.975) #O preço de compra é 2,5% menor que o preço atual?
                    cancel_order(h['order_id'],"BRLLTC",secret,key)
                    x = (Float(@real_saldo) / 2) / (Float(hash['ticker']['buy']))                                #calcular saldo, para saber quantia de moeda a comprar
                    place_buy_order("BRLLTC",x,@buy_price_ltc,secret,key)
                    @warnings << ", esta ordem foi cancelada.<br> Foi criada uma com o preço referente ao correto: R$#{@buy_price_ltc} de limite, com volume de #{x} litecoin (metade do que seu saldo pode comprar)."
                end
            elsif h["status"] == 2 and h["order_type"] == 2
                ordens_venda.append(h["order_id"])
                @warnings << "<br>Ordem #{h['order_id']} é uma ordem de venda de <b>#{h['quantity']} LTC</b>, pelo preço unitário de <b>#{h['limit_price']}</b>"
            end
        end
        
        #criar ordem de compra / vendas com os saldos atuais
        if Float(@real_saldo) > 0 #verificar se há saldo livre, se sim, criar ordem baseado na metade do saldo livre
                half_saldo = (Float(@real_saldo) / 2).round(2)
                x2 = (Float(half_saldo) / 2) / (Float(hash['ticker']['buy']))
                if x2 > 0.009
                    if k = place_buy_order("BRLLTC",x2,@buy_price_ltc,secret,key)
                        @warnings << "<br>Foi criada uma ordem de compra de litecoin aqui. Pois havia saldo livre disponível, quantidade: #{x3}, pelo preço #{@buy_price_ltc}"
                    end
                elsif (Float(half_saldo)) / (Float(hash['ticker']['buy'])).round(5) > 0.009
                    x3 =  (Float(half_saldo)) / (Float(hash['ticker']['buy'])).round(5)
                    if k = place_buy_order("BRLLTC",x3,@buy_price_ltc,secret,key)
                        @warnings << "<br>Foi criada uma ordem de compra de litecoin aqui. Pois havia saldo livre disponível, quantidade: #{x3}, pelo preço #{@buy_price_ltc}"
                    end
                end
        end
        
        #verificar saldo em litecoins e criar ordens de venda
        if Float(@ltc_saldo) > 0.009
            if place_sell_order("BRLLTC",(Float(@ltc_saldo).round(8)),Float(@sell_price_ltc).round(5),secret,key)
                @warnings << "<br>Ordem de venda de litecoin adicionada."
            end
        end
        return @warnings
    end
    def place_sell_order(par,quantia,limit_price,secret,key)
        headers, params = header("place_sell_order",par,quantia,limit_price,"",secret,key)
        json = requisicao_html(headers,params)
        return json
    end
    def place_buy_order(par,quantia,limit_price,secret,key)
        h = quantia.round(8)
        headers, params = header("place_buy_order",par,h,limit_price,"",secret,key)
        json = requisicao_html(headers,params)
        return json
    end
    def account_info(secret,key)
        @messages = ''
        host = 'http://www.mercadobitcoin.com.br'
        headers, params = header("get_account_info","","","","",secret,key)
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
        return json
    end
    def cancel_order(id_ordem,par,secret,key)
        headers, parametros = header("cancel_order",par,"","",id_ordem,secret,key)
        json = requisicao_html(headers,parametros)
        
        return json
    end
    def header(metodo,par,status,tipo,id,secret,key)
        tapi_id = secret
        tapi_secret = key
        request_path = '/tapi/v3/'
        tapi_nonce = (Time.now.to_i)*1000
        
        if metodo == "list_orders" and status == "" and tipo == ""
            params = {
                "tapi_nonce": tapi_nonce,
                "tapi_method": metodo, 
                "coin_pair": par,
                
            }
        elsif metodo == "place_sell_order"
        params = {
                "tapi_method": metodo,
                "tapi_nonce": tapi_nonce,
                "coin_pair": par,
                "quantity": status,
                "limit_price": tipo,
        }
        elsif metodo == "get_account_info"
            params = {
                "tapi_nonce": tapi_nonce,
                "tapi_method": metodo,
            }
        elsif metodo == "place_buy_order"
            params = {
                "tapi_method": metodo,
                "tapi_nonce": tapi_nonce,
                "coin_pair": par,
                "quantity": status,
                "limit_price": tipo,
            }
        elsif metodo == "list_orders" and status != "" and tipo != ""
            params = {
                "tapi_nonce": tapi_nonce,
                "tapi_method": metodo,
                "status_list": status,
                "order_type": tipo,
                "coin_pair": par,
            }
        elsif metodo == "list_orders" and status != "" and tipo == ""
            params = {
                "tapi_nonce": tapi_nonce,
                "tapi_method": metodo,
                "status_list": status,
                "coin_pair": par,
            }
        elsif metodo == "cancel_order"
            params = {
                "tapi_method": metodo,
                "tapi_nonce": tapi_nonce,
                "order_id": id,
                "coin_pair": par,
            }
        else
            raise "Parâmetro de método passado errado"
        end
        params2 = URI.encode_www_form(params)
        params_string = request_path + "?" + params2
        #parâmetros gerados
        
        a = OpenSSL::Digest.new("sha512")
        #gerar hmac
        h = OpenSSL::HMAC.new(tapi_secret, a)
        h.update(params_string)
        tapi_mac = h.hexdigest()
        # Gerar cabeçalho da requisição
        headers = {
            "content-type": "application/x-www-form-urlencoded",
            "TAPI-ID": tapi_id,
            "TAPI-MAC": tapi_mac
        }
        sleep(1) #forçar espera, para nonce ser diferente sempre
        return headers, params
    end
end
