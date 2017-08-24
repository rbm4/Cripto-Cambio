class AdminController < ApplicationController
    
    helper_method :cpt_transaction_user
    before_action :require_admin
    
    def cpt_transaction_user(user,id,username,email)
        url = URI.parse('https://cpttransactions.herokuapp.com/add_users')
        req = Net::HTTP::Post.new(url.request_uri)
        req.set_form_data({'username'=> username, 'email'=> email, 'id_original'=> id, 'name'=> user})
        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = (url.scheme == "https")
        response = http.request(req)
        response
    end
    
    def export_users
        a = Usuario.all
        a.each do |m|
            if m.email_confirmed == true
               p (cpt_transaction_user("#{m.first_name} #{m.last_name}",m.id,m.username,m.email)).body
            end
            sleep 1
        end
        @messages = "operação de exportação realizada"
        render 'sessions/loginerror'
    end
    
    def generate_storage #Gerar endereços de armazenamento principal
        if validate_operation(ENV["CPTOP"]) == true #validar a operação de acordo com o local onde ela está sendo executada
            store_obj = Storage.new #criar objeto de armazenamento
            if store_obj.create_wallet(params["storage"],params["storage_address"]) == true #criar carteira e armazená-la a partir da moeda desejada
                @messages = "Storage de #{params["storage"].upcase} criado com sucesso."
            else
                @messages = "Storage não foi criado."
            end
        else
            @messages = "operação não validada"
        end
        render 'sessions/loginerror'
    end
    
    def withdrawal #retirada de fundos do storage do block.io
        value = params["valor"].gsub(",",".")
        from_addr = params["endereco"]
        to_addr = params["destino"]
        BlockIo.set_options :api_key=> Storage.key_push(params["moeda"]), :pin => ENV["BLOCK_IO_PIN"], :version => 2
        a = BlockIo.withdraw_from_addresses :amounts => value, :from_addresses => from_addr, :to_addresses => to_addr, :nonce => params["nonce"]
        if a["status"] == "success"
            @messages = "Segue os dados Da transação: <br>Rede: #{a["data"]["network"]}<br>ID: #{a["data"]["txid"]}<br>Total retirado: #{a["data"]["amount_withdrawn"]}<br>Total enviado: #{a["data"]["amount_sent"]}"
            Transacao.construir_transacao("saque_exchange", a["data"]["network"], "[Cpt_cambio > #{current_user.username}]",a["data"]["network_fee"], true, current_user.username, a["data"]["txid"])
            #(tipo,moeda,inout,fee,paid,user,txid)
            #moedas enviadas, transação registrada
        end
        render 'sessions/loginerror'
    end
    def home
        @total_saldo = total_usuario_saldo
        @count = 0
        @numeros = Pagamento.where(status: "accepted")
        @numeros.each do
            @count = @count + 1
        end
        @opened = 0
        @tickets = Ticket.where(status: "aberto")
        @tickets.each do
            @opened = @opened + 1
        end
    end
    def mbtc_log
        render 'negociacoes.log'
    end
    def resposta
        @ticket = Ticket.find(params['message']['id'])
        @texto = @ticket.conteudo
        @ticket.conteudo << "\n"
        @ticket.conteudo << '------------------------------------------------------------------------------------------------------'
        @ticket.conteudo << "\n"
        @ticket.conteudo << 'Ticket respondido pelo admin: ' + params['message']['admin_name']
        @ticket.conteudo << "\n"
        @ticket.conteudo << params['message']['resposta']
        @ticket.conteudo << "\n"
        @ticket.conteudo << "------------------------------------------------------------------------------------------------------\n"
        @ticket.status = "respondido"
        if @ticket.save
            @messages = "Resposta salva e enviada ao usuário."
            render 'sessions/loginerror'
        else
            @messages = "Ocorreu algum erro. Tente novamente."
            render 'sessions/loginerror'
        end
    end
    def orders
        @pagamentos = Pagamento.all 
    end
    def all_tickets
        @tickets = Ticket.all
    end
    def open_tckt
        @ticket = Ticket.find(params[:id])
        @nome = @ticket.user
        @texto = @ticket.conteudo
        @titulo = @ticket.title
        @email = @ticket.email
        if @ticket.status == "aberto"
            @ticket.status = "aguardando resposta"
            @ticket.save
        end
    end
    def finish
         if params['type'] == 'pgseguro'
             @pagamento = Pagamento.find_by_pagseguro(params[:id])
         end
         if params['type'] == 'paypal'
             @pagamento = Pagamento.find_by_endereco(params[:id])
         end
         config_block
         @pagamento.status = 'pago'
         url = 'https://block.io/api/v2/withdraw_from_addresses/?api_key=' + @btc_pin + '&pin=' + @pin + '&from_addresses=' + @btc_address + '&to_addresses=' + @pagamento.address + '&amounts=' + @pagamento.volume.to_s
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
         @pagamento.txid_blockchain = hash['data']['txid']
         @pagamento.save
         puts @messages
         render nothing: true, status: 210
         second = false
    end
    def finalizar
        @pagamento = Pagamento.find_by(address: params[:pgto_address])
        @pagamento.endereco = params[:data]
        @pagamento.label = params[:cdgo_encomenda]
        @pagamento.user_id = params[:operador]
        @pagamento.status = 'send'
        @pagamento.save
        @messages = "Você deu baixa no pedido indicado na página anterior. O usuário será notificado desta operação."
    end
    def history
        @pagamentos = Pagamento.all
        
    end
    def take
        url = 'https://block.io/api/v2/withdraw_from_addresses/?api_key=ac35-6ff5-e103-d1c3&from_addresses=' + String(params[:address]) + '&to_addresses=2MxtY8jatyCQsXvthjy49GyQoeomtvBoTav' + '&amounts=' + String(params[:amount]) + '&pin=ignezconha'
        uri = URI(url)
        response = Net::HTTP.get(uri)
        hash = JSON.parse(response)
        puts hash
        if hash["data"]["error_message"] != nil
            @messages =  hash["data"]["error_message"]
        else
            @messages = "Valor retirado e transferido, parabéns, " + String(username)
            pagto = Pagamento.find_by_address(params[:address])
            pagto.status = "retirado"
            pagto.save
            archive_wallet(params[:address])
        end
        
    end
    def promo
    end
    def demo
        @users = Usuario.all
    end
end
