class Transacao < ActiveRecord::Base
    def self.construir_transacao(tipo,moeda,inout,fee,paid,user,txid)
        self.tipo = tipo #saque_exchange / envio_loja / exchange_[PAR] / depositos #STRING
        self.moeda = moeda #btc,ltc,doge,tbtc,tltc,tdoge #STRING
        self.inout = inout # user1 > user2 (de/para) => apenas em transações de exchange de usuário para usuário #STRING
        self.fee = fee # taxa cobrada pela transação (aplicada de várias formas) #STRING
        self.paid = paid # esta transação já foi paga? #BOOLEAN
        self.user = user # usuário/entidade que originou a transação #String
        if moeda != "brl" 
            self.txid = txid
        else
            self.txid = nil
        end
        self.save!
    end
end
