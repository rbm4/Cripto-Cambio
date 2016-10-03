class ProdutosController < ApplicationController
    #convert BRL to BTC https://blockchain.info/tobtc?currency=BRL&value=VALOR DO PRODUTO
    require 'net/http'
    require 'uri'
    require 'net/https'
    require 'json'
    require 'block_io'
    before_action :require_user, only: [:show, :solicitar_pagamento]
    BlockIo.set_options :api_key=> 'ac35-6ff5-e103-d1c3', :pin => 'Xatm@074', :version => 2
    
    def list_all_payment
         @pagamento = Pagamento.find_by(address: params[:id])
         @endereco = @pagamento.endereco
         @produtos = @pagamento.produtos
         @vol = @pagamento.volume
         @carteira = @pagamento.address
        
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
        
        order = Shoppe::Order.find(current_order.id)
        payment = PagSeguro::PaymentRequest.new
        payment.reference = order.id
        payment.notification_url = 'https://mkta.herokuapp.com/pgseguro'
        payment.redirect_url = 'https://mkta.herokuapp.com'
        order.order_items.each do |product|
            itens_string = product.ordered_item.full_name.to_s + ' ' + product.quantity.to_s + ' ,'
            payment.items << {
                id: product.id,
                description: product.ordered_item.full_name,
                amount: product.ordered_item.price,
                quantity: product.quantity
            }
        end
        payment.extra_params << { senderEmail: useremail.to_s }
       # payment.extra_params << { senderName: username.to_s }
        payment.extra_params << { shippingAddressStreet: params["pagamento"]["rua"]}
        payment.extra_params << { shippingType: '3'}
        payment.extra_params << { shippingAddressNumber: params["pagamento"]["numero"]}
        payment.extra_params << { shippingAddressComplement: params["pagamento"]["complemento"]}
        payment.extra_params << { shippingAddressPostalCode: params["pagamento"]["postcode"]}
        payment.extra_params << { shippingAddressCity: params["pagamento"]["cidade"]}
        payment.extra_params << { shippingAddressState: params["pagamento"]["estado"]}
	    payment.extra_params << { shippingAddressCountry: params["pagamento"]["pais"]}
	    
	    response = payment.register
	    if response.errors.any?
            raise response.errors.join("\n")
        else
            salvar_pagamento(:user_id => username, :network => 'pagseguro', :endereco => params["pagamento"]["rua"].to_s + ' ' + params["pagamento"]["complemento"].to_s + ' ' + params["pagamento"]["cidade"].to_s  + ' ' + params["pagamento"]["estado"].to_s + ' ' + params["pagamento"]["postcode"].to_s + ' ' + params["pagamento"]["pais"].to_s   , :volume => order.total_before_tax, :usuario => username, :status => 'incompleta', :produtos => itens_string, :postcode => params["pagamento"]["postcode"] )
            #redirect_to response.url
            end
    end
    private
    def salvar_pagamento(pagamento_params)
        customer = current_user
        pagamento = Pagamento.new(pagamento_params)
        order = Shoppe::Order.find(current_order.id)
        #order.status = 'received'
        #order.customer_id = customer.id
        order.first_name = customer.first_name
        order.last_name = customer.last_name
        order.billing_address1 = params["pagamento"]["rua"]
        order.billing_address2 = params["pagamento"]["numero"]
        order.billing_address3 = params["pagamento"]["complemento"]
        order.billing_address4 = params["pagamento"]["cidade"]
        order.billing_postcode = params["pagamento"]["postcode"]
        order.billing_country_id = '31'
        order.email_address = useremail.to_s
        order.phone_number = params["pagamento"]["endereco"]
        order.confirm!
        pagamento.save
        session[:order_id] = nil
        @messages = 'Order has been placed successfully!'
        puts @messages
    end
    def endereco_params
        params.require(:pagamento).permit(:address)
    end
    
    def pagamento_params
        params.require(:pagamento).permit(:user_id,:network, :address, :label, :volume, :usuario, :endereco, :produtos, :postcode)
    end
    
end
