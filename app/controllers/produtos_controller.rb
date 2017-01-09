class ProdutosController < ApplicationController
    #convert BRL to BTC https://blockchain.info/tobtc?currency=BRL&value=VALOR DO PRODUTO
    require 'net/http'
    require 'uri'
    require 'net/https'
    require 'json'
    require 'block_io'
    require 'paypal-sdk-rest'
    include PayPal::SDK::REST
    before_action :require_user, only: [:show, :solicitar_pagamento]
    BlockIo.set_options :api_key=> 'ac35-6ff5-e103-d1c3', :pin => 'Xatm@074', :version => 2
    
    
    def list_all_payment
        puts params[:id]
        Pagamento.destroy(params[:id])
        @pagamentos = Pagamento.all
        render 'sessions/detalhes'
    end
    def pagar_coinpayment
        pgto = Pagamento.find(params[:id])
        puts pgto.address
        puts pgto.network
        puts pgto.produtos
        puts pgto.volume
        puts pgto.user_id
        @id = pgto.user_id
        if pgto.produtos != "btc"
            @moeda = "BTC"
            if pgto.produtos == "ltc"
                @preco_bitcoin = litecoin_para_x_bitcoin(BigDecimal(pgto.volume))
                puts @preco_bitcoin
            end
        else
            @moeda = "USD"
            string = 'https://blockchain.info/pt/ticker' 
            btc_desejado = String(BigDecimal(BigDecimal(pgto.volume).mult(1.3,8)))
            uri = URI(string)
            response = Net::HTTP.get(uri)
            json = JSON.parse(response)
            dec = BigDecimal(json["USD"]["last"],8)
            @preco_bitcoin = dec.mult(BigDecimal(btc_desejado),8)
            puts @preco_bitcoin
        end
        @coinpay = true
        render 'sessions/loginerror'
    end
    def save_coinpay
        pgto = Pagamento.new
        order = Shoppe::Order.find(current_order.id)
        #params = {'cmd' => '_pay', 'reset' => '1', 'merchant' => 'b1e3df05f8a772fc276f4b79aef1c551', 'item_name' => id, 'currency' => pagar_em , 'amountf' => volume, 'quantity' => '1', 'allow_quantity' => '0', 'want_shipping' => '0', 'success_url' => 'https://mkta.herokuapp.com/', 'cancel_url' => 'https://mkta.herokuapp.com/', 'ipn_url' => 'https://bmarket-rbm4.c9users.io/coinpay', 'allow_extra' => '0'}
        #resposta = Net::HTTP.post_form(URI.parse('https://www.coinpayments.net/index.php'), params)
        pgto.user_id = params['coinpay']['item_name'] + '/' + order.id.to_s
        pgto.address = params['coinpay']['address']
        pgto.status = 'Aguardando pgto'
        if params['coinpay']['sku'] != "btc"
            @moeda = "BTC"
            if params['coinpay']['sku'] == "ltc" #colocar abaixo conversao de todas as moedas diferentes de BTC para BTC em valor
                @preco_bitcoin = litecoin_para_x_bitcoin(BigDecimal(params['coinpay']['volume']))
            end
        else
            @moeda = "USD"
            string = 'https://blockchain.info/pt/ticker' 
            btc_desejado = String(BigDecimal(BigDecimal(params['coinpay']['volume']).mult(1.3,8)))
            uri = URI(string)
            response = Net::HTTP.get(uri)
            json = JSON.parse(response)
            dec = BigDecimal(json["USD"]["last"],8)
            @preco_bitcoin = dec.mult(BigDecimal(btc_desejado),8)
            
        end
        pgto.usuario = params['coinpay']['usuario']
        pgto.volume = params['coinpay']['volume']
        pgto.network = 'coinpayments'
        pgto.produtos = params['coinpay']['sku']
        pgto.postcode = params['coinpay']['item_name'] + '/' + order.id.to_s
        pgto.save!
        @id = params['coinpay']['item_name'] + '/' + order.id.to_s
        session[:order_id] = nil
        respond_to do | format |  
            format.js {render :layout => false}  
        end
    end
    def finalizar_compra
       pgto = Pagamento.new(pagamento_params)
       url = 'https://block.io/api/v2/get_new_address/?api_key=ac35-6ff5-e103-d1c3'
       uri = URI(url)
       response = Net::HTTP.get(uri)
       hash = JSON.parse(response)
       @transaction_status = hash["status"].to_s
       net =  hash["data"]["network"].to_s
       userid = hash["data"]["user_id"].to_s
       @payment_address = hash["data"]["address"]
       @identifier = hash["data"]["label"].to_s
       puts @payment_address
       
       
       notifyurl = 'https://block.io/api/v2/create_notification/?api_key=ac35-6ff5-e103-d1c3&type=address&address=' + @payment_address + '&url=http://bmarkets.herokuapp.com/blckrntf'
       #resposta = Net::HTTP.get('https://block.io/api/v2/create_notification/?api_key=ac35-6ff5-e103-d1c3&type=address&address=' + @payment_address + '&url=https://bmarket-rbm4.c9users.io/blckrntf')
       notifyuri = URI(notifyurl)
       response2 = Net::HTTP.get(notifyuri)
       hashntf = JSON.parse(response2)
       puts hashntf
       salvar_pagamento(:user_id => userid, :network => net, :address => @payment_address, :label => @identifier, :volume => pgto.volume, :usuario => pgto.usuario, :status => @transaction_status, :endereco => pgto.endereco, :produtos => pgto.produtos, :postcode => pgto.postcode)
    end
    def finalizar_compra_pagseguro
        puts (String(params['edit']) + String(params['pagamento']['sku']) + String(params['pagamento']['volume']))
        dados = type(String(params['edit']), String(params['pagamento']['sku']),String(params['pagamento']['volume']))
        puts dados[0]
        puts dados[1]
        #BRL = pagar com pagseguro
        #BTC = pagar com bitcoin
        #paypal = pagar com paypal
        
        order = Shoppe::Order.find(current_order.id)
        if dados[0] == 'BTC'
            bitcoinpay(dados[1])
            @transaction_status = hash["status"].to_s
            net =  hash["data"]["network"].to_s
            userid = hash["data"]["user_id"].to_s
            @payment_address = hash["data"]["address"]
            @identifier = hash["data"]["label"].to_s
            puts @payment_address
            notifyurl = 'https://block.io/api/v2/create_notification/?api_key=ac35-6ff5-e103-d1c3&type=address&address=' + @payment_address + '&url=http://bmarkets.herokuapp.com/blckrntf'
            #resposta = Net::HTTP.get('https://block.io/api/v2/create_notification/?api_key=ac35-6ff5-e103-d1c3&type=address&address=' + @payment_address + '&url=https://bmarket-rbm4.c9users.io/blckrntf')
            notifyuri = URI(notifyurl)
            response2 = Net::HTTP.get(notifyuri)
            hashntf = JSON.parse(response2)
            puts hashntf
            salvar_pagamento(:user_id => userid, :network => net, :address => @payment_address, :label => @identifier, :volume => pgto.volume, :usuario => pgto.usuario, :status => @transaction_status, :endereco => pgto.endereco, :produtos => pgto.produtos, :postcode => pgto.postcode)
            render 'finalizar_compra'
        elsif dados[0] == 'BRL'
          if dados[2] == 'pagseguro'
            payment = PagSeguro::PaymentRequest.new
            payment.reference = username.to_s + order.id.to_s + params['pagamento']['sku']
        payment.notification_url = 'mkta.herokuapp.com/pgseguro'
        payment.redirect_url = 'mkta.herokuapp.com/detalhes'
            payment.items << {
                id: 1,
                description: 'Valor requisitado de: ' + params['pagamento']['volume'] + String(params['pagamento']['sku']) + ', Para ser pago em: ' + dados[0],
                amount: dados[1],
                quantity: '1'
            }
            payment.extra_params << { senderEmail: useremail.to_s }
            # payment.extra_params << { senderName: username.to_s }
	    
	        response = payment.register
	        array = response.code.split('')
	        count = 0
	        result = ''
	        array.each do | a |
	            count = count + 1
	            result << a
	            if count == 8
	                result << '-'
	            end
	            if count == 12
	                result << '-'
	            end
	            if count == 16
	                result << '-'
	            end
	            if count == 20
	                result << '-'
	            end
	        end
	        puts result
            if response.errors.any?
                raise response.errors.join("\n")
            else
                salvar_pagamento(:pagseguro => result, :user_id => username, :network => 'pagseguro', :endereco => response.url, :volume => params['pagamento']['volume'], :usuario => username, :status => 'incompleta', :produtos => params['pagamento']['sku'], :postcode => payment.reference )
                redirect_to response.url
            end
          end
          if dados[2] == 'paypal'
                return_paypal = ENV["LOCAL_URL"] + "/paypal"
                cancel_paypal = ENV["LOCAL_URL"] + "/paypal_cancel"
                
                    # Build Payment object
                    
                    @payment = Payment.new({
                        :intent => "sale",
                        :redirect_urls => {
    :return_url => return_paypal,
    :cancel_url => cancel_paypal},
                        :payer => {
                            :payment_method => "paypal",
                            :payer_id => username.to_s + order.id.to_s + params['pagamento']['sku']
                        },
                            #:funding_instruments => [{
                                #:credit_card => {
                                    #:type => "visa",
                                    #:number => "4567516310777851",
                                    #:expire_month => "11",
                                    #:expire_year => "2018",
                                    #:cvv2 => "874",
                                    #:first_name => "Joe",
                                    #:last_name => "Shopper",
                                    #:billing_address => {
                                        #:line1 => "52 N Main ST",
                                        #:city => "Johnstown",
                                        #:state => "OH",
                                        #:postal_code => "43210",
                                        #:country_code => "US" }}}]},
                                        :transactions => [{
                                            :item_list => {
                                                :items => [{
                                                    :name => "Fração de moeda",
                                                    :sku => params['pagamento']['volume'] + String(params['pagamento']['sku']),
                                                    :price => BigDecimal(dados[1],2),
                                                    :currency => "BRL",
                                                    :quantity => 1 }]},
                                                    :amount => {
                                                        :total => dados[1],
                                                        :currency => "BRL" },
                                                        :description => 'Valor requisitado de: ' + params['pagamento']['volume'] + String(params['pagamento']['sku']) + ', Para ser pago em: ' + dados[0] }]})
                                                        # Create Payment and return the status(true or false)
                                                        if @payment.create
                                                            salvar_pagamento(:user_id => username, :network => 'paypal', :endereco => @payment.id, :volume => params['pagamento']['volume'], :usuario => username, :status => 'incompleta', :produtos => params['pagamento']['sku'], :postcode => @payment.links[1].href )
                                                            redirect_to @payment.links[1].href, :method => 'REDIRECT'
                                                        else
                                                            @payment.error  # Error Hash
                                                        end
                                                        
          end        
        end
    end
    def executer
    end
    private
    def salvar_pagamento(pagamento_params)
        #customer = current_user
        pagamento = Pagamento.new(pagamento_params)
        #order = Shoppe::Order.find(current_order.id)
        pagamento.address = params["pagamento"]["address"]
        #order.status = 'received'
        #order.customer_id = customer.id
        #order.first_name = customer.first_name
        #order.last_name = customer.last_name
        #order.billing_address1 = params["pagamento"]["rua"]
        #order.billing_address2 = params["pagamento"]["numero"]
        #order.billing_address3 = params["pagamento"]["complemento"]
        #order.billing_address4 = params["pagamento"]["cidade"]
        #order.billing_postcode = params["pagamento"]["postcode"]
        #order.billing_country_id = '31'
        #order.email_address = useremail.to_s
        #order.phone_number = params["pagamento"]["endereco"]
        #order.confirm!
        pagamento.save
        session[:order_id] = nil
        @messages = 'Order has been placed successfully!'
        puts @messages
    end
    def endereco_params
        params.require(:pagamento).permit(:address)
    end
    
    def pagamento_params
        params.require(:pagamento).permit(:user_id,:network, :address, :label, :volume, :usuario, :endereco, :produtos, :postcode, :pagseguro)
    end
    
end
