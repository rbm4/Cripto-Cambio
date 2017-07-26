class Storage < ActiveRecord::Base
    def create_wallet(type,address)
            self.endereco = address
            self.role = "Storage principal de #{type.upcase}"
            self.tipo = type
            if self.save
                return true
            else
                return false
            end
    end
    def self.key_push(moeda)
        if moeda == "tbtc"
            return ENV["BLOCK_IO_TBTC"]
        elsif moeda == "tltc"
            return ENV["BLOCK_IO_TLTC"]
        elsif moeda == "tdoge"
            return ENV["BLOCK_IO_TDOGE"]
        elsif moeda == "btc"
            return ENV["BLOCK_IO_BTC"]
        elsif moeda == "ltc"
            return ENV["BLOCK_IO_LTC"]
        elsif moeda == "doge"
            return ENV["BLOCK_IO_DOGE"]
        end
    end
    # depreciated
    def create_wallet_antiga(w)
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
