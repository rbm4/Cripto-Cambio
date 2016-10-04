class NotificationsController < ApplicationController
    require 'net/http'
    skip_before_action :verify_authenticity_token, :only => [:bitcoin, :pgseguro]
    
    def balance_change url_string, xml_string
      uri = URI.parse url_string
      request = Net::HTTP::Post.new uri.path
      request.body = xml_string
      request.content_type = 'text/xml'
      response = Net::HTTP.new(uri.host, uri.port).start { |http| http.request request }
      response.body
      return 201
    end
    def msgall
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
        if pagto.status == 'incompleta'
          pagto.status = 'pago'
          #BlockIo.withdraw_from_addresses :amounts => BigDecimal(brl_btc(pagto.volume.to_s)), :from_addresses => '2MxtY8jatyCQsXvthjy49GyQoeomtvBoTav', :to_addresses => pagto.address, :pin => 'ignezconha'
          puts brl_btc(pagto.volume.to_s)
          pagto.save
          render nothing: true, status: 210
          second = false
        end
        puts "confirmação de pagamento repetida"
     end
    end
    if second != false
      render nothing: true, status: 200
    end
  end
end
