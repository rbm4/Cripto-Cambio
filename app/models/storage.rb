class Storage < ActiveRecord::Base
    def create_wallet(w)
        if w == "ltc"
            Bitcoin.network = :litecoin
        elsif w == "btc"
            Bitcoin.network = :bitcoin
        elsif w == "doge"
            Bitcoin.network = :dogecoin
        end
        keys = Bitcoin::Key.generate
        if keys.pub.size == 66 and keys.priv.size == 64
            self.pubkey = keys.pub
            self.privkey = keys.priv
            self.endereco = Bitcoin::pubkey_to_address(keys.pub)
            self.tipo = w
            self.role = "Storage principal de #{w.upcase}"
            if self.save
                return true
            else
                return false
            end
        end
        return false
    end
end
