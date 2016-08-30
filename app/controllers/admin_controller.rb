class AdminController < ApplicationController
    def home
       
    end
    def orders
        @pagamentos = Pagamento.all 
        puts @pagamentos
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
        puts @pagamento
    end
end
