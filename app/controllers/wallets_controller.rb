class WalletsController < ApplicationController
    require 'coinbase/wallet'
    before_action :require_wallet, only: [:withdraw, :withdraw_helper, :notifications]
    
    def create_btc_wallet
        usuario = current_user
        keys = Bitcoin::Key.generate
        usuario.pubkeybtc = keys.pub
        usuario.privkeybtc = keys.priv
        usuario.bitcoin = Bitcoin::pubkey_to_address(keys.pub)
        usuario.save
        @messages = '<div class="errorspeech">Seu endereço bitcoin: <font color="red">' + usuario.bitcoin + '</font><br>Sua chave privada: ' + keys.priv + '<p>Parabéns! Você acabou de criar o endereço acima e associá-lo a sua conta.</p> <p><j>Com ele, você poderá utilizar nossos serviços com maior praticidade, adicionando créditos ao nosso site apenas enviando bitcoins para o endereço em destaque!<br> Melhorando sua comodidade na aquisição de nossos serviços e agilidade na compra de produtos.</j></div>'
        render 'sessions/loginerror'
    end
    def create_ltc_wallet
        usuario = current_user
        Bitcoin.network = :litecoin
        keys = Bitcoin::Key.generate
        usuario.pubkeybtc = keys.pub
        usuario.privkeybtc = keys.priv
        usuario.litecoin = Bitcoin::pubkey_to_address(keys.pub)
        usuario.save
        @messages = '<div class="errorspeech">Seu endereço bitcoin: <font color="red">' + usuario.litecoin + '</font><br>Sua chave privada: ' + keys.priv + '<p>Parabéns! Você acabou de criar o endereço acima e associá-lo a sua conta.</p> <p><j>Com ele, você poderá utilizar nossos serviços com maior praticidade, adicionando créditos ao nosso site apenas enviando bitcoins para o endereço em destaque!<br> Melhorando sua comodidade na aquisição de nossos serviços e agilidade na compra de produtos.</j></div>'
        render 'sessions/loginerror'
    end
    def hexadecimate_it(s)
        s.unpack('H*').first
    end
    
    def withdrawal
        
        if params["commit"] == "Withdrawal"
            carteira = Storage.find_by_endereco(params["endereco"])
            @cart = carteira
            @messages = sign_transaction(carteira.privkey, carteira.pubkey, carteira.tipo, params['destino'])
            @messages << "<br> Bytesize: #{@messages.bytesize}"
            render 'sessions/loginerror'
            return
        end
    end
    
    #Funções de assinatura de transações
    def sign_transaction(pubkey,privkey,network,endereco)
        
        key1 = Bitcoin::Key.new(pubkey,privkey)
        
        value = (BigDecimal(params["valor"].gsub!(",","."),8) * 10000000).to_f.to_s
        p value
        if network == "ltc"
            Bitcoin.network = :litecoin
        elsif network == "btc"
            Bitcoin.network = :bitcoin
        elsif network == "doge"
            Bitcoin.network = :dogecoin
        end
        prev_tx = get_transactions(key1.addr,network)
        prev_tx_output_index = prev_tx["data"]["txs"][0]["output_no"]
        
        tax = Bitcoin::Protocol::Tx.new
        
        p "key publica gerada #{key1.pub}"
        p "key publica original #{@cart.pubkey}"
        p "chave privada #{key1.priv}"
        p "Chave privada original #{@cart.privkey}"
        p "Destino #{endereco}"
        p "Carteira gerada: #{key1.addr}"
        p "carteira original: #{@cart.endereco}"
        #montar inputs
        hash_in = Hash.new
        hash_in['previous_transaction_hash'] = prev_tx["data"]["txs"][0]["txid"]
        hash_in['output_index'] = prev_tx_output_index
        hash_in['script'] = prev_tx["data"]["txs"][0]["script_asm"]
        inputs = Bitcoin::Protocol::TxIn.from_hash(hash_in)
        
        #montar outputs
        hash_out = Hash.new
        hash_out['value'] = value
        hash_out['scriptPubKey'] = Bitcoin::Script.to_address_script(endereco)
        p "endereco de destino: #{endereco}"
        outputs = Bitcoin::Protocol::TxOut.value_to_address(value.to_i, endereco)
        #output = Bitcoin::Protocol::TxOut.new
        #outputs = Bitcoin::Protocol::TxOut.from_hash(hash_out)
        #output.script {|s| s.recipient endereco }
        #output.value = value
        #outputs = Bitcoin::Protocol::TxOut.new
        #outputs.amount = value
        #script = Bitcoin::Script.to_address_script(endereco)
        #outputs.pk_script = script
        
        
        
        tax.add_in(inputs)
        tax.add_out(outputs)
        saldo_total = (BigDecimal(consulta_saldo_cripto(network,key1.addr),8) * 100000000)
        if value.to_i <= saldo_total.to_i
            output_send2 = Bitcoin::Protocol::TxOut.value_to_address((saldo_total - value.to_i - 200000).to_i, key1.addr)
            #output_send2.pk_script = output_send2.script {|s| s.recipient endereco }
            #output_send2.value = (saldo - value - 170000).to_i
            tax.add_out(output_send2)
        end
        p tax.out
        #
        p "transação com inputs e outputs: \n"
        p "tax #{tax.inspect}"
        p "\n"
      
        #p "taxa em json #{tax.to_s}"
        p "taxa finalizada, assinar"
        #assinatura da tranção
        sig = Bitcoin.sign_data(key1.key, signature_hash_for_input(0, tax))
        
        tax.in[0].script_sig = Bitcoin::Script.binary_from_string(key1.pub)
        
        p tax.verify_input_signature(0, sig) == true
        puts "json:\n"
        puts tax.to_json # json
        puts "\nhex:\n"
        puts tax.to_payload.unpack("H*")[0] # hex binary
        
        
        return tax.to_payload.unpack("H*")[0]
    end
    def signature_hash_for_input(input_idx, subscript, hash_type=nil)
        # https://github.com/bitcoin/bitcoin/blob/e071a3f6c06f41068ad17134189a4ac3073ef76b/script.cpp#L834
        # http://code.google.com/p/bitcoinj/source/browse/trunk/src/com/google/bitcoin/core/Script.java#318
        # https://en.bitcoin.it/wiki/OP_CHECKSIG#How_it_works
        # https://github.com/bitcoin/bitcoin/blob/c2e8c8acd8ae0c94c70b59f55169841ad195bb99/src/script.cpp#L1058
        # https://en.bitcoin.it/wiki/OP_CHECKSIG
        data = nil
        @ver, @lock_time, @in, @out, @scripts = 1, 0, [], [], []
        @enable_bitcoinconsensus = !!ENV['USE_BITCOINCONSENSUS']
        parse_data_from_io(data) if data
        # Note: BitcoinQT checks if input_idx >= @in.size and returns 1 with an error message.
        # But this check is never actually useful because BitcoinQT would crash 
        # right before VerifyScript if input index is out of bounds (inside CScriptCheck::operator()()).
        # That's why we don't need to do such a check here.
        #
        # However, if you look at the case SIGHASH_TYPE[:single] below, we must 
        # return 1 because it's possible to have more inputs than outputs and BitcoinQT returns 1 as well.
        return "\x01".ljust(32, "\x00") if input_idx >= @in.size # ERROR: SignatureHash() : input_idx=%d out of range

        hash_type ||= SIGHASH_TYPE[:all]

        pin  = @in.map.with_index{|input,idx|
            if idx == input_idx
            subscript = subscript.out[ input.prev_out_index ].script if subscript.respond_to?(:out) # legacy api (outpoint_tx)
            input.to_payload(subscript)
            else
            case (hash_type & 0x1f)
            when SIGHASH_TYPE[:none];   input.to_payload("", "\x00\x00\x00\x00")
            when SIGHASH_TYPE[:single]; input.to_payload("", "\x00\x00\x00\x00")
            else;                       input.to_payload("")
            end
            end
        }
        
        pout = @out.map(&:to_payload)
        in_size, out_size = Protocol.pack_var_int(@in.size), Protocol.pack_var_int(@out.size)
        
        case (hash_type & 0x1f)
        when SIGHASH_TYPE[:none]
            pout = ""
            out_size = Protocol.pack_var_int(0)
        when SIGHASH_TYPE[:single]
            return "\x01".ljust(32, "\x00") if input_idx >= @out.size # ERROR: SignatureHash() : input_idx=%d out of range (SIGHASH_SINGLE)
            pout = @out[0...(input_idx+1)].map.with_index{|out,idx| (idx==input_idx) ? out.to_payload : out.to_null_payload }.join
            out_size = Protocol.pack_var_int(input_idx+1)
        end
        
        if (hash_type & SIGHASH_TYPE[:anyonecanpay]) != 0
            in_size, pin = Protocol.pack_var_int(1), [ pin[input_idx] ]
        end
        
        buf = [ [@ver].pack("V"), in_size, pin, out_size, pout, [@lock_time, hash_type].pack("VV") ].join
        Digest::SHA256.digest( Digest::SHA256.digest( buf ) )
    end
    #função de enviar transação
    def send_transaction(hex,network)
        hash = Hash.new
        hash["tx_hex"] = hex
        url = "https://chain.so/api/v2/send_tx/#{network}"
        p url
        uri = URI(url)
        http = Net::HTTP.new(uri.host, 443)
        http.use_ssl = true 
        request = Net::HTTP::Post.new(uri.path, {'Content-Type' =>'application/json'})
        request.body = hash.to_json
        response = http.request(request)
        puts response.body
        return true
    end
    #Buscar último tx_id que referencia o endereço de origem
    def get_transactions(endereco,rede)
        uri = URI("https://chain.so/api/v2/get_tx_received/#{rede}/#{endereco}")
        response = Net::HTTP.get(uri)
        return JSON.parse(response.gsub!("\n",""))
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
