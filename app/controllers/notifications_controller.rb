class NotificationsController < ApplicationController
    require 'net/http'
    require 'paypal-sdk-rest'
    include PayPal::SDK::REST
    include PayPal::SDK::Core::Logging
    skip_before_action :verify_authenticity_token, :only => [:bitcoin, :pgseguro, :paypal, :paypalnip]
    
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
    transaction = PagSeguro::Transaction.find_by_notification_code(params[:notificationCode])
    puts transaction.reference

    if transaction.errors.empty?
     cod = params["notificationCode"]
     url1 = 'https://ws.sandbox.pagseguro.uol.com.br/v3/transactions/notifications/' + cod + '?email=ricardo.malafaia1994@gmail.com&token=CEB2E4B937F8426A8BE9DB80D6DCCA8A'
     uri1 = URI(url1)
     response = Net::HTTP.get(uri1)
     @doc = Nokogiri::XML(response)
     status = @doc.xpath("//status")
     permission = Integer(status.to_s.match(/\d/).to_s)
     if permission == 3
        pagto = Pagamento.find_by_pagseguro(transaction.reference)
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
