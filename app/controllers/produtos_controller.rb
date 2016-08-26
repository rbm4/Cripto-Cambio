class ProdutosController < ApplicationController
    #convert BRL to BTC https://blockchain.info/tobtc?currency=BRL&value=VALOR DO PRODUTO
    require 'net/http'
    require 'uri'
    require 'net/https'
    require 'json'
    before_action :require_user, only: [:show, :solicitar_pagamento]
    
    def show
        @invoice_id =  9001
        @all = Produto.all
    #    BlockIo.get_new_address
    #    puts(@endereco.address)
    #    puts(@endereco.label)
    end
    
    def solicitar_pagamento
        @endereco = 'teste inicial'
      @volume = '0.00001'
       url = 'https://block.io/api/v2/get_new_address/?api_key=ac35-6ff5-e103-d1c3'
       uri = URI(url)
       response = Net::HTTP.get(uri)
       hash = JSON.parse(response)
       @transaction_status = hash["status"].to_s
       net =  hash["data"]["network"].to_s
       userid = hash["data"]["user_id"].to_s
       @payment_address = hash["data"]["address"].to_s
       @identifier = hash["data"]["label"].to_s
       
       salvar_pagamento(:user_id => userid, :network => net, :address => @payment_address, :label => @identifier, :volume => @volume, :usuario => username, :status => @transaction_status, :endereco => @endereco)
    end
    def salvar_pagamento(pagamento_params)
        pagamento = Pagamento.new(pagamento_params)
        pagamento.save
    end
    
    
    def pagamento_params
        params.require(:pagamento).permit(:user_id,:network, :address, :label, :volume, :usuario, :endereco)
    end
end
