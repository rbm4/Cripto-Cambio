class ApostasController < ApplicationController
    def index
    end
    def btc_lotery_form
        
        
        @tickets_totais = Integer(premiacoes_btc)
        h = Ticketbtc.all.where(:usuario => (String(current_user.username + "@cptcambio.com")), :sorteavel => true).take
        if  h != nil 
            a = BigDecimal(h.proporcao,8)
            b = BigDecimal(@tickets_totais,8)
            @tickets = h.proporcao 
            @chances = String((a.div(b,8)).mult(100,8)) + " %"
        else
            @tickets = "0"
            @chances = "0"
        end
    end
    def buy_btc_ticket
        premiacoes_btc
        if params['ticketbtcs']['preco'].match(/[a-zA-Z]/) or Integer(params['ticketbtcs']['preco']) < 0
            @messages = "Número inválido. Tente novamente"
            render "/apostas/btc_lotery_form"
            return
        end
        preço = 0.0003
        decimal_params = BigDecimal(params['ticketbtcs']['preco'],1)
        preço_final = decimal_params.mult(preço,8)
        client = Coinbase::Wallet::Client.new(api_key: ENV["COINBASE_KEY"], api_secret: ENV["COINBASE_SECRET"])
        primary_account = client.primary_account
        puts primary_account.id
        client.accounts.each do |account|
            balance = account.balance
            #puts "#{account.name}: #{balance.amount} #{balance.currency}"
            #puts account.transactions
            if account.name == current_user.username + '@cptcambio.com'
                if BigDecimal(balance.amount,8) >= preço_final
                    #tx = account.send({:to => '1PwgjmKHv7LpAEJYwfS5FmLMfGACUk2eRV',:amount => preço_final,:currency => 'BTC'})
                    #puts tx
                    t = Ticketbtc.find_by_usuario(current_user.email)
                    if t == nil
                        t = Ticketbtc.new
                        t.usuario = current_user.email
                        t.proporcao = params['ticketbtcs']['preco']
                        t.sorteavel = true
                        t.save
                        @messages = "Você agora está concorrendo ao sorteio de bitcoins! Verifique abaixo detalhes do andamento do sorteio atual."
                        render '/apostas/btc_lotery_form'
                    else
                        if params['ticketbtcs']['preco'] = "0"
                            @messages = "Valor de compra 0, nada foi feito."
                            render '/apostas/btc_lotery_form'
                            return
                        else
                            @messages = "Compra realizada."
                            t.proporcao = Integer(t.proporcao) + Integer(params['ticketbtcs']['preco'])
                            t.save
                        end
                        render '/apostas/btc_lotery_form'
                    end
                else
                    @messages = "Você não tem saldo suficiente para realizar esta operação. Por favor, utilize o menu '<a href='/store'>Loja</a>' para comprar bitcoins, ou então envie bitcoins para o seu endereço assossiado."
                    puts @messages
                    render '/apostas/btc_lotery_form'
                end
            end
        end
    end
    def dynamic
        decimal_params = BigDecimal(params['ticket']['numero_tck'],1)
        preco = BigDecimal(0.0003,8)
        @valor = decimal_params.mult(preco,8)
        puts @valor
        @qtd = params['ticket']['numero_tck']
        @valor
    end
    def premiacoes_btc
        @premiacoes = Array.new
        j = Ticketbtc.all.where(:sorteavel => true)
        total_sorteavel = 0
        j.each do |h|
            total_sorteavel = Integer(total_sortteavel) + Integer(h.proporcao)
        end
        decimal_sorteavel = BigDecimal(total_sorteavel,8)
        decimal_preco = BigDecimal(0.0003,8)
        decimal_desconto = BigDecimal(0.92,2)
        valor_total = (decimal_sorteavel.mult(decimal_preco,8)).mult(decimal_desconto,8)
        @premiacoes[0] = BigDecimal(valor_total,8).mult(0.4,8)
        @premiacoes[1] = BigDecimal(valor_total,8).mult(0.2,8)
        @premiacoes[2] = BigDecimal(valor_total,8).mult(0.11,8)
        @premiacoes[3] = BigDecimal(valor_total,8).mult(0.09,8)
        @premiacoes[4] = BigDecimal(valor_total,8).mult(0.07,8)
        @premiacoes[5] = BigDecimal(valor_total,8).mult(0.05,8)
        @premiacoes[6] = BigDecimal(valor_total,8).mult(0.04,8)
        @premiacoes[7] = BigDecimal(valor_total,8).mult(0.03,8)
        @premiacoes[8] = BigDecimal(valor_total,8).mult(0.015,8)
        @premiacoes[9] = BigDecimal(valor_total,8).mult(0.005,8)
        return decimal_sorteavel
    end
    def sorteio
        tickets = Ticketbtc.all.where(:sorteavel => true)
        total_sorteavel = 0
        usuarios = []
        contador = 0
        piscina_tickets = Array.new
        tickets.each do |h|
            usuarios[contador] = h.usuario
            Integer(h.proporcao).times do
                piscina_tickets << h.usuario
            end
            total_sorteavel = Integer(total_sorteavel) + Integer(h.proporcao)
            contador = contador + 1
        end
        
        proporcoes_premios = [40,20,11,9,7,5,4,3,1.5,0.5].to_a
        
        proporcoes_premios.each do |k|
            premiado = rand(0...total_sorteavel)
            puts "premiado"
            puts premiado
            puts "premiado"
            client = Coinbase::Wallet::Client.new(api_key: ENV["COINBASE_KEY"], api_secret: ENV["COINBASE_SECRET"])
            primary_account = client.primary_account
            client.accounts.each do |account|
                #balance = account.balance
                #puts "#{account.name}: #{balance.amount} #{balance.currency}"
                #puts account.transactions
                balance = primary_account.balance
                if premiado != nil and account.name == piscina_tickets[premiado]
                    if piscina_tickets[premiado] != nil
                        j = Ticketbtc.all.where(:sorteavel => true,  :usuario => account.name).take
                        puts 'jota'
                        puts j
                        puts 'jota'
                        if  j.sorteavel == true
                            puts "Enviar bitcoins aqui para o ganhador #{account.name}, no valor de #{k * BigDecimal(String(balance),8)}" 
                            j.sorteavel = false
                            j.save
                            total_sorteavel = Integer(total_sorteavel) - Integer(j.proporcao)
                            piscina_tickets.reject! { |n| n == j.usuario }
                            puts piscina_tickets
                            puts total_sorteavel
                        else
                            puts "usuário já premiado, fazer algo"
                        end
                    else
                        puts "sem usuários para serem sorteados"
                    end
                end
            end
        end
        @messages = "Sorteio realizado"
        render '/sessions/loginerror'
    end
end
