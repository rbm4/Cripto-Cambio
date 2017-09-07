class ExchangeController < ApplicationController
    require 'mercadopago.rb'
    skip_before_action :verify_authenticity_token, :only => [:formulario_dinamico]
    def open_order_show
        @open_tipo = ""
        @open_qtd = ""
        @open_price = ""
        @open_value = ""
        @open_cancel = ""
        if session[:moeda1_par] == nil and session[:moeda2_par] == nil
                @par = "BTC/BRL"
                j = Exchangeorder.where("par = :str_par AND status = :stt AND usuario_id = :users", {str_par: @par.upcase, stt: "open", users: current_user.username}).order(:created_at)
                if j.any?
                    @orders = j
                else
                    @open_tipo << "Não há ordens abertas."
                end
        else
                @par = "#{session[:moeda1_par]}/#{session[:moeda2_par]}"
                j = Exchangeorder.where("par = :str_par AND status = :stt AND usuario_id = :usuario_id", {str_par: @par.upcase, stt: "open", usuario_id: current_user.username}).order(:created_at)
                if j.any?
                    @orders = j
                else
                    @open_tipo << "Não há ordens abertas."
                end
        end
    end
    def order_show_form
        if params[:commit] == "Esconder"
            @esconder = true
            @moeda_par1 = nil
            @moeda_par2 = nil
        end
        session[:moeda1_compra] = nil
        session[:moeda2_compra] = nil
        session[:moeda1_venda] = nil
        session[:moeda2_venda] = nil
        if session[:moeda1_par] == nil and session[:moeda2_par] == nil
            @moeda_par1 = "BTC"
            @moeda_par2 = "BRL"
        else
            @moeda_par1 = session[:moeda1_par]
            @moeda_par2 = session[:moeda2_par]
        end
    end
    def pair
        par_moedas = params["commit"].split("/")
        par_moedas[0].gsub!("[","")
        par_moedas[1].gsub!("]","")
        session[:moeda1_compra] = nil
        session[:moeda2_compra] = nil
        session[:moeda1_venda] = nil
        session[:moeda2_venda] = nil
        session[:moeda1_par] = par_moedas[0]
        session[:moeda2_par] = par_moedas[1]
        @moeda_par1 = session[:moeda1_par]
        @moeda_par2 = session[:moeda2_par]
        if session[:form_tipo] == "buy"
            @tipo = 'compra'
        elsif session[:form_tipo] == "sell"
            @tipo = 'venda'
        end
        
        
        render 'order_show_form'
    end
    def overview
        session[:moeda1_compra] = nil
        session[:moeda2_compra] = nil
        session[:moeda1_venda] = nil
        session[:moeda2_venda] = nil
        @moeda_par1 = "BTC"
        @moeda_par2 = "BRL"
        @valor_buy = 8932.32 #verificar preço da última venda das Order.all.last if Order.type == "buy"
        @valor_sell = 8876.22 #verificar preço da última compra das Order.all.last if Order.type == "sell"
        #Par de moedas inicial: [BRL/BTC]
    end
    def calc_tax
        if params["qtd_moeda1buy"] != nil
            session[:moeda1_compra] = params["qtd_moeda1buy"].gsub(/,/,".")
        end
        if params["qtd_moeda2buy"] != nil
            session[:moeda2_compra] = params["qtd_moeda2buy"].gsub(/,/,".")
        end
        if (session[:moeda1_compra] != nil) and (session[:moeda2_compra] != nil)
            qtdb1, qtdb2 = BigDecimal(session[:moeda1_compra],8), BigDecimal(session[:moeda2_compra],8)
            @total_buy = (qtdb1 * qtdb2)
            @comission_buy = qtdb1 * 0.005
            @liquid_buy = qtdb1 - @comission_buy
            @calculo_feito_compra = true
        end
        if params["qtd_moeda1sell"] != nil
            session[:moeda1_venda] = params["qtd_moeda1sell"].gsub(/,/,".")
        end
        if params["qtd_moeda2sell"] != nil
            session[:moeda2_venda] = params["qtd_moeda2sell"].gsub(/,/,".")
        end
        if (session[:moeda1_venda] != nil) and (session[:moeda2_venda] != nil)
            qtds1, qtds2 = BigDecimal(session[:moeda1_venda],8), BigDecimal(session[:moeda2_venda],8)
            @total_sell = (qtds1 * qtds2)
            @comission_sell = @total_sell * 0.005
            @liquid_sell = @total_sell - @comission_sell
            @calculo_feito_venda = true
        end
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
        elsif params['currency'] == '[DOGE] Dogecoin'
            @amountf = "amountfdoge"
            @curr = "DOGE"
        end
    end

    def credit_tax_calc
        if params['commit'] == "Continuar"
            moeda = params["currency"].split(" ")[0].gsub("]","")
            moeda = moeda.gsub("[","")
            quantidade_solicitado = BigDecimal(params["amountf#{moeda.downcase}"],8)
            #digest = "#{current_user.username}/#{params["amountf#{moeda.downcase}"]}" # usuario/quantidade solicitada
            
            @public_payment_key = "#{ENV["DEPOSIT_KEY_DIGEST"]}|#{quantidade_solicitado}|#{current_user.username}" #nome do item a ser recuperado no controlador de notificações
            
            
            
            
            certo = params["amountf#{moeda.downcase}"].gsub(",",".")
            @valor = BigDecimal(certo,9).to_f
            if @valor < min("#{moeda}")
                @valid = false
            else
                @valid = true
            end
            @taxa_cripto = (@valor - (@valor * 0.012).round(8) - fee("#{moeda}")).round(8)
            
            fee = (((@valor * 0.012).round(8) - fee("DOGE")) * -1 ).round(8)
            if transacao = Transacao.construir_transacao("coinpayments/#{moeda.downcase}",moeda,"#{current_user.username} > Cpt Cambio",fee,false, current_user.username, "#{quantidade_solicitado}")#(tipo,moeda,inout,fee,paid,user,txid)
                @moeda = moeda
                @valor = BigDecimal(certo,9).to_f
                transacao_coinpay = Coinpayments.create_transaction(@valor, "#{moeda}", "#{moeda}", options = {buyer_email: current_user.email, buyer_name: current_user.username, item_name: "#{@public_payment_key}|#{transacao.id}", item_number: 1, ipn_url: "#{ENV['COINPAY_IPN_URL']}/exchange_deposit"})
                @address = transacao_coinpay.address
                p "endereço para ser pago : #{@address}"
                p "qtd de #{moeda} a ser pago: #{@valor}"
                @qr = RQRCode::QRCode.new("bitcoin:#{@address}")
            else
                @valid = false
            end
        end
        
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
        elsif params['amountfdoge'] != nil
            @method = "cripto"
            certo = params['amountfdoge'].gsub(",",".")
            @valor = BigDecimal(certo,9).to_f
            if @valor < min("DOGE")
                @valid = false
            else
                @valid = true
            end
            @taxa_cripto = (@valor - (@valor * 0.012).round(8) - fee("DOGE")).round(8)
            @moeda = "DOGE"
        end
        if params['reais'] != nil
            valor = BigDecimal(params['reais'])
            @desconto = String(valor * 0.012)
            @total_brl = valor - (valor * 0.012)
            @method = "deposit"
        end
    end
    
    def min(x)
        if x == "BTC"
            return 0.0002
        elsif x == "LTC"
            return 0.003
        elsif x == "DOGE"
            return 3
        elsif x == "BRL"
            return 50
        end
    end
    
    def fee(moeda)
        if moeda == "BTC"
            return 0.00008
        elsif moeda == "LTC"
            return 0.003
        elsif moeda == "DOGE"
            return 3
        else
            return "(0.00008 BTC)/(0.002 LTC)/(2 DOGE)*<br>*Taxa fixa referente à cobrança das transações na rede."
        end
    end
    
    def formulario_dinamico
        @tax_percentage = "1,2%"
        @formulario = ""
        if params['tipo_pgto'] == "[BRL] Deposito Bancario"
            @formulario = "MercadoPago"
            @tipos_pgto = "<option>Selecionar</option><option>Cartão</option><option>Boleto</option>"
            @type = "deposito"
        elsif params['tipo_pgto'] == "[Cripto] CoinPayments"
            @formulario = "CoinPayments"
            @moedas = "<option>Selecione a moeda</option><option>[BTC] Bitcoin</option><option>[LTC] Litecoin</option><option>[DOGE] Dogecoin</option>"
            @type = "coinpayments"
        end
        respond_to do |format|
            format.js
        end
        render do |page|
        #page.html {}
            page.js {}
        end
    end
    def credit_save
        p params
    end
    def withdrawal 
        @opcoes = "<option>Selecione</option><option>[BRL] Real</option><option>[LTC] Litecoin</option><option>[BTC] Bitcoin</option><option>[DOGE] Dogecoin</option>"
    end
    def withdrawal_js
        p params
    end
    def form_js
        session[:moeda1_compra] = nil
        session[:moeda2_compra] = nil
        session[:moeda1_venda] = nil
        session[:moeda2_venda] = nil
        if session[:moeda1_par] == nil and session[:moeda2_par] == nil
            @moeda_par1 = "BTC"
            @moeda_par2 = "BRL"
        else
            @moeda_par1 = session[:moeda1_par]
            @moeda_par2 = session[:moeda2_par]
        end
        if params["commit"] == "Comprar"
            @tipo = 'compra'
            session[:form_tipo] = "buy"
        elsif params["commit"] == "Vender"
            @tipo = 'venda'
            session[:form_tipo] = "sell"
        end
    end
end

