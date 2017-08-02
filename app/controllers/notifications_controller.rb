class NotificationsController < ApplicationController
    require 'net/http'
    require 'paypal-sdk-rest'
    include PayPal::SDK::REST
    include PayPal::SDK::Core::Logging
    skip_before_action :verify_authenticity_token, :only => [:bitcoin, :pgseguro, :paypal, :paypalnip, :coinpay, :coinpay_deposits]
    
  def coinpay
    config_block
    params['ipn_id'] 
    if params['merchant'] == 'b1e3df05f8a772fc276f4b79aef1c551'
      puts 'notificação chegou'
      if params['status'] == '1'
        pagto = Pagamento.find_by_postcode(params['item_name'])
        pagto.status = 'accepted'
        pagto.save
        puts 'pagamento recebido, esperando confirmação'
      end
      if params['status'] >= '100'
        puts 'pagamento confirmado, enviando...'
        array = params['item_name'].split('/')
        puts 'enviar volume para carteira ' + array[0]
        puts 'moeda: ' + array[1]
        puts 'quantia: ' + array[2]
        puts 'id da compra: ' + array[3]
        pagto = Pagamento.find_by_postcode(params['item_name'])
        if (pagto.status.to_s == 'accepted' and pagto.produtos == 'btc')
          pagto.status = 'pago'
          client = Coinbase::Wallet::Client.new(api_key: ENV["COINBASE_KEY"], api_secret: ENV["COINBASE_SECRET"])
          client.accounts.each do |account|
              if account.name == 'cpt_vendas'
                  if account.send( :to => array[0], :amount => array[2].to_s, :currency => 'BTC')
                    pagto.save
                  end
              end
          end
          @messages = ""
          @messages = "Valor retirado e transferido, identificador único: " + String(hash["data"]["txid"])
          #pagto.txid_blockchain = hash['data']['txid']
          puts @messages
          render nothing: true, status: 210
          second = false
          #pagto.txid_blockchain = params["data"]['txid']
        end
        if (pagto.status.to_s == 'accepted' and pagto.produtos == 'ltc')
          pagto.status = 'pago'
          url = 'https://block.io/api/v2/withdraw_from_addresses/?api_key=' + @ltc_pin + '&pin=' + @pin + '&from_addresses=' + @ltc_address + '&to_addresses=' + array[0] + '&amounts=' + array[2].to_s
          uri = URI(url)
          response = Net::HTTP.get(uri) 
          hash = JSON.parse(response)
          puts hash
          if hash["data"]["error_message"] != nil
            @messages =  hash["data"]["error_message"]
            if BigDecimal(hash['data']['available_balance'],8) <= BigDecimal(hash['data']['minimum_balance_needed'],8)
              pagto.status = 'accepted'
              pagto.save
            end
            render nothing: true, status: 211
            second = false
            return
          end
          @messages = ""
          @messages = "Valor retirado e transferido, identificador único: " + String(hash["data"]["txid"])
          pagto.txid_blockchain = hash['data']['txid']
          pagto.save
          puts @messages
          render nothing: true, status: 210
          second = false
          #pagto.txid_blockchain = params["data"]['txid']
        end
      end
      #Parameters: "txn_id"=>"CPAK66ELODNBAV3TE8U29WYYPB", "status"=>"0", "status_text"=>"Waiting for buyer funds...", "currency1"=>"BTC", "currency2"=>"LTC", "amount1"=>"1.366E-5", "amount2"=>"0.0026", "subtotal"=>"1.366E-5", "shipping"=>"0", "tax"=>"0", "fee"=>"1.0E-5", "item_amount"=>"1.366E-5", "item_name"=>"FracaoBTC", "quantity"=>"1", "first_name"=>"krobellus", "last_name"=>"alperte", "email"=>"krobellus@protonmail.ch", "received_amount"=>"0", "received_confirms"=>"0"}
    end
  end
  def coinpay_deposits
    if params['merchant'] != 'b1e3df05f8a772fc276f4b79aef1c551' && params['status'] < '100'
      render nothing: true, status: 211
      return
    end
    moeda1 = params["currency1"] #moeda nativa que deve ser igual a moeda da transação
    moeda2 = params["currency2"] #moeda em que foi feito o pagamento
   # amount_1 = params["amount1"] #quantidade da moeda nativa (sem desconto de taxas)
    #amount_2 = params["amount2"] #quantidade da moeda paga na moeda 2, caso diferente da moeda 1 descontar 5%
    array_name = params["item_name"].split("/")
    encrypted = array_name[0]
    datetime = array_name[1]
    username = array_name[2]
    
    #recuperar a tranção do banco
    transacao = Transacao.find_by_user("#{username}/#{datetime}")
    if transacao != nil #transcação válida, prosseguir
      array_cipher = transacao.txid.split("|")
      cipher = OpenSSL::Cipher::Cipher.new("aes-256-cbc")
      cipher.decrypt
      cipher.key = array_cipher[0]
      cipher.iv = array_cipher[1]
      decrypted = cipher.update(encrypted)
      decrypted << cipher.final
      
      dados = decrypted.split("/")
      username = dados[0]
      qtd_moeda = BigDecimal(dados[1],8)
      #verificar moedas nativas e as pagas:
      if moeda2 == moeda1 #sem taxas extras desconto normal
        qtd_moeda = qtd_moeda - BigDecimal(transacao.fee,8)
        moeda = moeda1
      else #taxa de 5% em cima do qtd_moeda
        qtd_moeda = qtd_moeda + (qtd_moeda * 0.95)
        moeda = moeda2
      end
      #descontos calculados
      #encontrar usuário
      user_depto = Usuario.find_by_username(username)
      hash = eval(user_depto.saldo_encrypted)
      hash["#{moeda}"] = (BigDecimal(hash["#{moeda}"],8) + qtd_moeda).to_s
      user_depto.saldo_encrypted = hash.to_s
      if user_depto.save 
        transacao.paid = true
        transacao.txid = qtd_moeda
        transsacao.save
      end
    else
      #transacação inválida, finalizar.
     render nothing: true, status: 211
    end
    
    render nothing: true, status: 211
  end
    
    def balance_change url_string, xml_string
      uri = URI.parse url_string
      request = Net::HTTP::Post.new uri.path
      request.body = xml_string
      request.content_type = 'text/xml'
      response = Net::HTTP.new(uri.host, uri.port).start { |http| http.request request }
      response.body
      return 201
    end
    
    def paypal
     config_block
     payment = Hash.new
     payment['id'] = params['paymentId']
     payment['type'] = params['token']
     payment['payment_id'] = params['PayerID']
     @payment = Payment.find(payment['id'])
     if @payment.execute( :payer_id => payment['payment_id'] )  # return true or false
          @messages =  "Pagamento[#{@payment.id}] executado com sucesso"
          pgto = Pagamento.find_by_endereco(payment['id'])
          puts 'id do pagamento: ' + pgto.endereco
          puts 'Endereco bitcoin de envio: ' + pgto.address
          puts 'volume de bitcoin para enviar: ' + pgto.volume
          if (pgto.status.to_s == 'incompleta' and pgto.produtos == 'btc')
                pgto.status = 'pago'
                url = 'https://block.io/api/v2/withdraw_from_addresses/?api_key=' + @btc_pin + '&pin=' + @pin + '&from_addresses='+ @btc_address + '&to_addresses=' + pgto.address + '&amounts=' + pgto.volume.to_s
                uri = URI(url)
                response = Net::HTTP.get(uri) 
                hash = JSON.parse(response)
                puts hash
            if hash["data"]["error_message"] != nil
                @messages =  hash["data"]["error_message"]
                if BigDecimal(hash['data']['available_balance'],8) <= BigDecimal(hash['data']['minimum_balance_needed'],8)
                  pagto.status = 'accepted'
                  pagto.save
                end
                puts @messages
                render 'msg', status: 211
                return
            end
              @messages = ""
              @messages = "Valor transferido, identificador único: " + String(hash["data"]["txid"])
              pgto.txid_blockchain = hash['data']['txid']
              pgto.save
              puts @messages
              render 'msg', status: 210
          end
          if (pgto.status.to_s == 'incompleta' and pgto.produtos == 'ltc')
                pgto.status = 'pago'
                url = 'https://block.io/api/v2/withdraw_from_addresses/?api_key=' + @ltc_pin + '&pin=' + @pin + '&from_addresses=' + @ltc_address + '&to_addresses=' + pgto.address + '&amounts=' + pgto.volume.to_s
                uri = URI(url)
                response = Net::HTTP.get(uri) 
                hash = JSON.parse(response)
                puts hash
            if hash["data"]["error_message"] != nil
                @messages =  hash["data"]["error_message"]
                if BigDecimal(hash['data']['available_balance'],8) <= BigDecimal(hash['data']['minimum_balance_needed'],8)
                  pagto.status = 'accepted'
                  pagto.save
                end
                puts @messages
                render 'msg', status: 211
                return
            end
              @messages = ""
              @messages = "Valor transferido, identificador único: " + String(hash["data"]["txid"])
              pgto.txid_blockchain = hash['data']['txid']
              pgto.save
              puts @messages
              render 'msg', status: 210
          end
     else
          logger.error @payment.error.inspect
          if @payment.error.message == "The instrument presented was either declined by the processor or bank, or it can't be used for this payment."
            @messages = "<p>Sua compra não foi efetivada com sucesso. A opção de pagamento apresentada foi negada pelo processante ou o banco.<br> verifique se você selecionou uma quantidade mínima de volume aceita pelo seu cartão / banco.</p> <br>Você pode excluir o pagamento atual ou tentar realizar outro ou tentar fazer o mesmo pagamento novamente na sessão de <a href='/detalhes'>Transações</a>"
          end
     end
     
     return 205
    end
    
    def paypalnip
      puts params['mc_gross']
      status = params['payment_status']
      if status == 'Completed'
        puts 'Transação completa por NIP. Transferir bitcoins aqui? - notifications_controller#paypalnip'
      end
      return 200
    end
    
    def msg
      
    end 
    
    def bitcoin
      
      puts 'NOTIFICAÇÃO:'
      tipo = params["notification"]["type"]
      puts tipo
      if tipo == 'ping'
        puts 'Tipo PING, returna 203'
        return 203
      end
      endereco = params["data"]["address"]
      valor = params["data"]["amount_received"]
      green = params["data"]["is_green"] #pode gastar
      confirmations = params["data"]["confirmations"] #esperar ser pelo menos 3
      id = params["notification_id"]
      pgto = Pagamento.find_by_address(endereco)
      if green == 'true'
        if BigDecimal(valor,9) >= BigDecimal(pgto.volume,9)
          pgto.status = 'accepted'
          pgto.save
          puts 'Pagamento confirmado por notificação.'
          BlockIo.delete_notification :notification_id => id
          render '/'
          return 201
        end
      end
      if Integer(confirmations) >= 3
          pgto.status = 'accepted'
          pgto.save
          puts "Pagamento confirmado por notificação"
          BlockIo.delete_notification :notification_id => id
          render '/'
          return 202
      end
      render '/'
      return 202
    end
    
    def text
    end
    
    def pgseguro
    config_block
    transaction = PagSeguro::Transaction.find_by_notification_code(params[:notificationCode])
    puts transaction.reference

    if transaction.errors.empty?
     cod = params["notificationCode"]
     url1 = 'https://ws.pagseguro.uol.com.br/v3/transactions/notifications/' + cod + '?email=ricardo.malafaia1994@gmail.com&token=CEB2E4B937F8426A8BE9DB80D6DCCA8A'
     uri1 = URI(url1)
     response = Net::HTTP.get(uri1)
     @doc = Nokogiri::XML(response)
     status = @doc.xpath("//status")
     puts status
     permission = Integer(status.to_s.match(/\d/).to_s)
     if permission == 3
        pagto = Pagamento.find_by_postcode(transaction.reference)
        @doc.search('//item').each do |tag|
          description   = tag.at('description').text
          quantity      = tag.at('quantity').text
          amount        = tag.at('amount').text
          puts "Descrição: #{description}, Quantitade: #{quantity}, Preço por item #{amount}"
        end
        puts pagto.status
        # pagto.produtos é o tipo de moeda
        if (pagto.status.to_s == 'incompleta' and pagto.produtos == 'btc')
          pagto.status = 'pago'
          url = 'https://block.io/api/v2/withdraw_from_addresses/?api_key=' + @btc_pin + '&pin=' + @pin + '&from_addresses=' + @btc_address + '&to_addresses=' + pagto.address + '&amounts=' + pagto.volume.to_s
          uri = URI(url)
          response = Net::HTTP.get(uri) 
          hash = JSON.parse(response)
          puts hash
          if hash["data"]["error_message"] != nil
            @messages =  hash["data"]["error_message"]
            if BigDecimal(hash['data']['available_balance'],8) <= BigDecimal(hash['data']['minimum_balance_needed'],8)
              pagto.status = 'accepted'
              pagto.save
            end
            render nothing: true, status: 211
            second = false
            return
          end
          @messages = ""
          @messages = "Valor retirado e transferido, identificador único: " + String(hash["data"]["txid"])
          pagto.txid_blockchain = hash['data']['txid']
          pagto.save
          puts @messages
          render nothing: true, status: 210
          second = false
          #pagto.txid_blockchain = params["data"]['txid']
        end
        if (pagto.status.to_s == 'incompleta' and pagto.produtos == 'ltc')
          pagto.status = 'pago'
          url = 'https://block.io/api/v2/withdraw_from_addresses/?api_key=' + @ltc_pin + '&pin=' + @pin + '&from_addresses=' + @ltc_address + '&to_addresses=' + pagto.address + '&amounts=' + pagto.volume.to_s
          uri = URI(url)
          response = Net::HTTP.get(uri) 
          hash = JSON.parse(response)
          puts hash
          if hash["data"]["error_message"] != nil
            @messages =  hash["data"]["error_message"]
            if BigDecimal(hash['data']['available_balance'],8) <= BigDecimal(hash['data']['minimum_balance_needed'],8)
              pagto.status = 'accepted'
              pagto.save
            end
            render nothing: true, status: 211
            second = false
            return
          end
          @messages = ""
          @messages = "Valor retirado e transferido, identificador único: " + String(hash["data"]["txid"])
          pagto.txid_blockchain = hash['data']['txid']
          pagto.save
          puts @messages
          render nothing: true, status: 210
          second = false
          #pagto.txid_blockchain = params["data"]['txid']
        end
        puts "confirmação de pagamento repetida"
     end
    end
    if second != false
      render nothing: true, status: 200
    end
    end
end
