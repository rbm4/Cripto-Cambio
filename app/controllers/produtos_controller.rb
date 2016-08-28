class ProdutosController < ApplicationController
    #convert BRL to BTC https://blockchain.info/tobtc?currency=BRL&value=VALOR DO PRODUTO
    require 'net/http'
    require 'uri'
    require 'net/https'
    require 'json'
    before_action :require_user, only: [:show, :solicitar_pagamento]
    
    def list_all_payment
         @pagamento = Pagamento.find_by(address: params[:id])
         @endereco = @pagamento.endereco
         @produtos = @pagamento.produtos
         @vol = @pagamento.volume
        
    end
    def finalizar_compra
        @endereco = 'teste inicial'
      @volume = '0.00001'
       url = 'https://block.io/api/v2/get_new_address/?api_key=ac35-6ff5-e103-d1c3'
       uri = URI(url)
       response = Net::HTTP.get(uri)
       hash = JSON.parse(response)
       @transaction_status = hash["status"].to_s
       net =  hash["data"]["network"].to_s
       userid = hash["data"]["user_id"].to_s
       @payment_address = hash["data"]["address"]
       @identifier = hash["data"]["label"].to_s
       @produtos = ["Purple jesus","Nitro boots","Pure Blotter"].to_s
       @username = username
       
       salvar_pagamento(:user_id => userid, :network => net, :address => @payment_address, :label => @identifier, :volume => @volume, :usuario => @username, :status => @transaction_status, :endereco => @endereco, :produtos => @produtos)
    end
    private
    def salvar_pagamento(pagamento_params)
        pagamento = Pagamento.new(pagamento_params)
        pagamento.save
    end
    def endereco_params
        params.require(:pagamento).permit(:address)
    end
    
    def pagamento_params
        params.require(:pagamento).permit(:user_id,:network, :address, :label, :volume, :usuario, :endereco, :produtos)
    end
end
