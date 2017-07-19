class WalletsController < ApplicationController
    require 'coinbase/wallet'
    before_action :require_wallet, only: [:withdraw, :withdraw_helper, :notifications]
    
    def create_btc_wallet
        usuario = current_user
        keys = Bitcoin::generate_key
        usuario.pubkeybtc = keys[1]
        usuario.privkeybtc = keys[0]
        usuario.bitcoin = Bitcoin::pubkey_to_address(keys[1])
        usuario.save
        @messages = '<div class="errorspeech">Seu endereço bitcoin: <font color="red">' + usuario.bitcoin + '</font><br>Sua chave privada: ' + keys[0] + '<p>Parabéns! Você acabou de criar o endereço acima e associá-lo a sua conta.</p> <p><j>Com ele, você poderá utilizar nossos serviços com maior praticidade, adicionando créditos ao nosso site apenas enviando bitcoins para o endereço em destaque!<br> Melhorando sua comodidade na aquisição de nossos serviços e agilidade na compra de produtos.</j></div>'
        render 'sessions/loginerror'
    end
    def create_ltc_wallet
        usuario = current_user
        Bitcoin.network = :litecoin
        keys = Bitcoin::generate_key
        usuario.pubkeybtc = keys[1]
        usuario.privkeybtc = keys[0]
        usuario.litecoin = Bitcoin::pubkey_to_address(keys[1])
        usuario.save
        @messages = '<div class="errorspeech">Seu endereço bitcoin: <font color="red">' + usuario.litecoin + '</font><br>Sua chave privada: ' + keys[0] + '<p>Parabéns! Você acabou de criar o endereço acima e associá-lo a sua conta.</p> <p><j>Com ele, você poderá utilizar nossos serviços com maior praticidade, adicionando créditos ao nosso site apenas enviando bitcoins para o endereço em destaque!<br> Melhorando sua comodidade na aquisição de nossos serviços e agilidade na compra de produtos.</j></div>'
        render 'sessions/loginerror'
    end
    def withdraw
        
    end
    def terms
        
    end
    def notifications
        endereco = params["address"]
        valor_movido = params["amont"]
        id = params["transaction"]["id"]
        logr = ""
        logr << "\nTransação registrada no endereço #{endereco}, movendo um montante equivalente a #{valor_movido} com o ID de transação #{id}"
        arquivo_log = File.open("./statistics/transacoes.log", "a")
        arquivo_log << logr
        arquivo_log.close
    end
    def withdraw_helper
        puts 'helper chamado'
        if params['moeda'] == "BTC"
            @avaiable = balance_btc_coinbase + " BTC"
            @minimal = "0.0004 BTC"
        end
        if params['moeda'] == "ETH"
        #    @avaiable = balance_eth_coinbase + " ETH"
            @avaiable = "20" + " ETH"
            @minimal = "0.005"  + " ETH"
           # @minimal = "0.005"
        end
        respond_to do | format |  
            format.js {render :layout => false}
        end
    end
    def withdraw_remove
        hash = captcha(params["g-recaptcha-response"])
        if hash["success"] == true    
            @messages = ""
            if params["moeda"] == "Moeda:"
                @messages << "Selecione uma moeda para transferir.<br>"
                renderi = true
            end
            if params["quantidade"].match(/[a-zA-Z]/) or params["quantidade"] == "" or params["destino"] == ""
                @messages  << 'Formulário com dados inválidos. Preencha-o novamente.<br>'
                renderi = true
            else 
                @amount_transfer = params['quantidade']
            end
            if (Bitcoin.valid_address? params['destino']) == false
                @messages << 'O endereço bitcoin digitado é inválido!<br>'
                renderi = true
            else
                @address_form = params['destino']
            end
            if (BigDecimal(params['quantidade'],8) + BigDecimal("0.0004", 8)) >= BigDecimal(balance_btc_coinbase,8)
                renderi = true
                @messages << "Seu saldo não condiz com o valor que você está tentando transferir.<br>"
            end
            if renderi == true
                render 'withdraw'
                return
            end
            params['quantidade'].gsub!(',','.')
            client = Coinbase::Wallet::Client.new(api_key: ENV["COINBASE_KEY"], api_secret: ENV["COINBASE_SECRET"])
            client.accounts.each do |account|
                balance = account.balance
                puts "#{account.name}: #{balance.amount} #{balance.currency}"
                puts account.transactions
                if account.name == current_user.username + '@cptcambio.com'
                    @messages = account.send( :to => params['destino'], :amount => params['quantidade'], :currency => 'BTC')
                    print @messages
                end
            end
        else
            @messages = "Captcha inválido! Tente novamente."
            render 'withdraw'
        end
    end
end
