class AdminController < ApplicationController
    def home
        @count = 0
        @numeros = Pagamento.where(status: "accepted")
        @numeros.each do
            @count = @count + 1
        end
    end
    def orders
        @pagamentos = Pagamento.all 
    end
    def finish
         @pagamento = Pagamento.find_by(address: params[:id])
         @endereco = @pagamento.endereco
         @produtos = @pagamento.produtos
         @vol = @pagamento.volume
         @carteira = @pagamento.address
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
    end
end
