class AdminController < ApplicationController
    def home
       
    end
    def orders
        @pagamentos = Pagamento.all 
        puts @pagamentos
    end
end
