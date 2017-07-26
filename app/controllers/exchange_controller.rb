class ExchangeController < ApplicationController
    require 'mercadopago.rb'
    
    def overview
        #formulário
    end
    
    def credit_form
       @opcoes = "<option>Selecionar</option><option>[BRL] Deposito Bancario</option><option>[Cripto] CoinPayments</option>"
    end
    
    def credit_execute_mercadopago
        # https://www.mercadopago.com.br/developers/pt/tools/sdk/server/ruby/
        # 
        p params
        
        mp = MercadoPago.new('2040040393943432','iS4d0jLYRo2YtOPJZAxpWNZ9ZSos3wlI')
        reais = params['reais']
        reais.gsub!(",",".")
        p reais
        p reais.inspect
        preference_data = {
            "items": [
                {
                    "title": "#{params['reais']} BRL - ", 
                    "quantity": 1, 
                    "unit_price": Float(reais), 
                    "currency_id": "BRL",
                    "description": "Compra de créditos na CriptoCambio Exchange",
                    "email": current_user.email
                }
            ],
            "back_urls": [
                {
                "success" => "",
                "pending" => "",
                "failure" => ""
            }
            ]
        }
        preference = mp.create_preference(preference_data)
        @point = preference['response']['init_point']
        
        p preference
        sleep(1)
        redirect_to @point
    end
    
    def credit_execute
        
    end
    def formulario_dinamico_cripto
        if params['currency'] == '[BTC] Bitcoin'
            @amountf = "amountfbtc"
            @curr = "BTC"
        elsif params['currency'] == '[LTC] Litecoin'
            @amountf = "amountfltc"
            @curr = "LTC"
        elsif params['currency'] == '[ETH] Ethereum'
            @amountf = "amountfeth"
            @curr = "ETH"
        end
    end

    def credit_tax_calc
        if params['commit'] == "Continuar"
            puts "Salvar depósito do usuário aqui"
        end
        @public_payment_key = String(DateTime.now)
        private_payment_key = Digest::SHA256.digest(@public_payment_key)
        if params['amountfbtc'] != nil
            @method = "cripto"
            certo = params['amountfbtc'].gsub(",",".")
            @valor = BigDecimal(certo,9).to_f
            if @valor < min("BTC")
                @valid = false
            else
                @valid = true
            end
            @taxa_cripto = (@valor - (@valor * 0.012).round(8) - fee("BTC")).round(8)
            @moeda = "BTC"
        elsif params['amountfltc'] != nil
            @method = "cripto"
            certo = params['amountfltc'].gsub(",",".")
            @valor = BigDecimal(certo,9).to_f
            if @valor < min("LTC")
                @valid = false
            else
                @valid = true
            end
            @taxa_cripto = (@valor - (@valor * 0.012).round(8) - fee("LTC")).round(8)
            @moeda = "LTC"
        elsif params['amountfeth'] != nil
            @method = "cripto"
            certo = params['amountfeth'].gsub(",",".")
            @valor = BigDecimal(certo,9).to_f
            if @valor < min("ETH")
                @valid = false
            else
                @valid = true
            end
            @taxa_cripto = (@valor - (@valor * 0.012).round(8) - fee("ETH")).round(8)
            @moeda = "LTC"
        end
        if params['reais'] != nil
            valor = BigDecimal(params['reais'])
            @taxa_card = String(valor - (valor * 0.065))
            @taxa_boleto = valor - (valor * 0.02)
            @method = "deposit"
        end
    end
    
    def min(x)
        if x == "BTC"
            return 0.001
        elsif x == "LTC"
            return 0.03
        elsif x == "ETH"
            return 0.001
        elsif x == "BRL"
            return 50
        end
    end
    
    def fee(moeda)
        if moeda == "BTC"
            return 0.0008
        elsif moeda == "LTC"
            return 0.02
        elsif moeda == "ETH"
            return 0.0005
        else
            return "(0.0008 BTC)/(0.002 LTC)/(2 DOGE)*<br>*Taxa fixa referente à cobrança das transações na rede."
        end
    end
    
    def formulario_dinamico
        
        @formulario = ""
        if params['tipo_pgto'] == "[BRL] Deposito Bancario"
            @formulario = "MercadoPago"
            @tipos_pgto = "<option>Selecionar</option><option>Cartão</option><option>Boleto</option>"
            @type = "deposito"
        elsif params['tipo_pgto'] == "[Cripto] CoinPayments"
            @formulario = "CoinPayments"
            @moedas = "<option>Selecione a moeda</option><option>[BTC] Bitcoin</option><option>[LTC] Litecoin</option><option>[ETH] Ethereum</option>"
            @type = "coinpayments"
        end
        
    end
    def credit_save
        p params
    end
end
