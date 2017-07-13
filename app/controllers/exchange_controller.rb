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
    
    def credit_tax_calc
        if params['amountf'] == nil
            valor = BigDecimal(params['reais'])
            @taxa_card = String(valor - (valor * 0.065))
            @taxa_boleto = valor - (valor * 0.02)
            @method = "deposit"
        elsif params['amountf'] != nil
            @public_payment_key = ""
            @moeda = ""
            @valor = BigDecimal(params['amountf'],8)
            if params['currency'] == nil
                @method = "cripto"
                @taxa_cripto = String(BigDecimal((@valor - (@valor * 0.012)),8))
            elsif params['currency'] != nil
                @public_payment_key = String(DateTime.now)
                private_payment_key = Digest::SHA256.digest(@public_payment_key)
                @taxa_cripto = String(BigDecimal((@valor - (@valor * 0.012)),8))
                @method = "cripto"
                @moeda = (params['currency'].split(" "))[0].delete("[").delete("]")
                p @moeda
            end
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
            @moedas = "<option>[BTC] Bitcoin</option><option>[LTC] Litecoin</option><option>[ETH] Ethereum</option>"
            @type = "coinpayments"
        end
        
    end
    def credit_save
        p params
    end
end
