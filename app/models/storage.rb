class Storage < ActiveRecord::Base
    def create_wallet(w)
        if w == "ltc"
            Bitcoin.network = :litecoin
        elsif w == "btc"
            Bitcoin.network = :bitcoin
        elsif w == "doge"
            Bitcoin.network = :dogecoin
        end
        keys = Bitcoin::generate_key
        self.pubkey = keys[1]
        self.privkey = keys[0]
        self.endereco = Bitcoin::pubkey_to_address(keys[1])
        self.tipo = w
        self.role = "Storage principal de #{w.upcase}"
        if self.save
            return true
        else
            return false
        end
    end
end
