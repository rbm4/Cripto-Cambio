class Transacao < ActiveRecord::Base
    def self.construir_transacao(tipo,moeda,inout,fee,paid,user,txid)
        tx = Transacao.new
        tx.tipo = tipo #saque_exchange / envio_loja / exchange_[PAR] / depositos #STRING
        tx.moeda = moeda #btc,ltc,doge,tbtc,tltc,tdoge #STRING
        tx.inout = inout # user1 > user2 (de/para) => apenas em transações de exchange de usuário para usuário #STRING
        tx.fee = fee # taxa cobrada pela transação (aplicada de várias formas) #STRING
        tx.paid = paid # esta transação já foi paga? #BOOLEAN
        tx.user = user # usuário/entidade que originou a transação #String
        tx.txid = txid # quantidade solicitada pelo usuário
        if tx.save!
            return tx
        else
            return false
        end
        return 
    end
end
