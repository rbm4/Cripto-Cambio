class ApostasController < ApplicationController
    skip_before_action :verify_authenticity_token, :only => [:sorteio]
    before_action :require_user, :only => [:btc_lotery_form, :buy_btc_ticket, :dynamic, :premiacoes_btc, :como_jogar, :detalhes]
    
    def index
    end
    def btc_lotery_form
        
        proporcao_total = 0
        @tickets_totais = Integer(premiacoes_btc)
        h = Ticketbtc.all.where(:usuario => (String(current_user.email)), :sorteavel => true)
        if  h != nil
            h.each do |m|
                proporcao_total = proporcao_total + Integer(m.proporcao)
            end
            a = BigDecimal(proporcao_total,8)
            b = BigDecimal(@tickets_totais,8)
            @tickets = proporcao_total
            @chances = String((a.div(b,8)).mult(100,8)) + " %"
        else
            @tickets = "0"
            @chances = "0 %"
        end
    end
    def buy_btc_ticket
        
        if params['ticketbtcs']['preco'].match(/[a-zA-Z]/) or Integer(params['ticketbtcs']['preco']) <= 0
            premiacoes_btc
            btc_lotery_form
            @messages = "Número inválido. Tente novamente"
            render "/apostas/btc_lotery_form"
            return
        end
        preço = 0.0001
        decimal_params = BigDecimal(params['ticketbtcs']['preco'],1)
        preço_final = decimal_params.mult(preço,8)
        client = Coinbase::Wallet::Client.new(api_key: ENV["COINBASE_KEY"], api_secret: ENV["COINBASE_SECRET"])
        primary_account = client.primary_account
        puts primary_account.id
        t = Ticketbtc.find_by_usuario(current_user.email)
        client.accounts.each do |account|
            #puts "#{account.name}: #{balance.amount} #{balance.currency}"
            #puts account.transactions
            if account.name == current_user.username + '@cptcambio.com'
                balance = account.balance
                if BigDecimal(balance.amount,8) >= preço_final
                    if t != nil and t.sorteavel == false #ticket existe, porém não faz parte do sorteio
                        if client.transfer(account.id, {:to => '6f067e3d-b3aa-574f-b92e-461eda70a37b', :amount => preço_final, :currency => 'BTC'}) 
                            @messages = "Você agora está concorrendo ao sorteio de bitcoins! Verifique abaixo detalhes do andamento do sorteio atual."
                        end
                        t = Ticketbtc.new
                        t.usuario = current_user.email
                        t.proporcao = params['ticketbtcs']['preco']
                        t.sorteavel = true
                        t.save
                        arquivo_log = File.open("./statistics/tickets_comprados.log", "r")
                        anterior = arquivo_log.read
                        arquivo_log = File.open("./statistics/tickets_comprados.log", "w")
                        atual = Integer(anterior) + Integer(params['ticketbtcs']['preco'])
                        arquivo_log << atual
                        arquivo_log.close
                        @messages = "Você agora está concorrendo ao sorteio de bitcoins! Verifique abaixo detalhes do andamento do sorteio atual."
                        premiacoes_btc
                        btc_lotery_form
                        render '/apostas/btc_lotery_form'
                        return
                    elsif params['ticketbtcs']['preco'] == "0"
                        @messages = "Valor de compra 0, nada foi feito."
                        render '/apostas/btc_lotery_form'
                        return
                    elsif t == nil #ticket não existe, criar novo
                        t = Ticketbtc.new
                        t.usuario = current_user.email
                        t.sorteavel = true
                        t.proporcao = params['ticketbtcs']['preco']
                        if account.send({:to => '1PwgjmKHv7LpAEJYwfS5FmLMfGACUk2eRV',:amount => preço_final,:currency => 'BTC'})
                            @messages = "Compra realizada."
                            arquivo_log = File.open("./statistics/tickets_comprados.log", "r")
                            anterior = arquivo_log.read
                            arquivo_log = File.open("./statistics/tickets_comprados.log", "w")
                            atual = Integer(anterior) + Integer(params['ticketbtcs']['preco'])
                            arquivo_log << atual
                            arquivo_log.close
                        end
                        t.save
                        premiacoes_btc
                        btc_lotery_form
                        render '/apostas/btc_lotery_form'
                        return
                    elsif t != nil and t.sorteavel == true #ticket existe, somar proporcao atual com nova
                        if account.send({:to => '1PwgjmKHv7LpAEJYwfS5FmLMfGACUk2eRV',:amount => preço_final,:currency => 'BTC'})
                            @messages = "Você adicionou #{params['ticketbtcs']['preco']} tickets a esta rodada!."
                            t.proporcao = Integer(t.proporcao) + Integer(params['ticketbtcs']['preco'])
                            arquivo_log = File.open("./statistics/tickets_comprados.log", "r")
                            anterior = arquivo_log.read
                            arquivo_log = File.open("./statistics/tickets_comprados.log", "w")
                            atual = Integer(anterior) + Integer(params['ticketbtcs']['preco'])
                            arquivo_log << atual
                            arquivo_log.close
                            t.save
                        end
                        premiacoes_btc
                        btc_lotery_form
                        render '/apostas/btc_lotery_form'
                        return
                    end
                    @messages = "passou por todas condicionais, nada aconteceu."
                    premiacoes_btc
                    btc_lotery_form
                    render '/apostas/btc_lotery_form'
                    return
                else
                    @messages = "Você não tem saldo suficiente para realizar esta operação. Por favor, utilize o menu '<a href='/store'>Loja</a>' para comprar bitcoins, ou então envie bitcoins para o seu endereço associado."
                    puts @messages
                    premiacoes_btc
                    btc_lotery_form
                    render '/apostas/btc_lotery_form'
                    return
                end
            end
        end
    end
    def dynamic
        decimal_params = BigDecimal(params['ticket']['numero_tck'],1)
        preco = BigDecimal(0.0001,8) 
        @valor = decimal_params.mult(preco,8)
        @valor = @valor + BigDecimal(0.00045,8)
        @qtd = params['ticket']['numero_tck']
        @valor
    end
    def premiacoes_btc
        @premiacoes = Array.new
        j = Ticketbtc.all.where(:sorteavel => true)
        total_sorteavel = 0
        j.each do |h|
            total_sorteavel = Integer(total_sorteavel) + Integer(h.proporcao)
        end
        decimal_sorteavel = BigDecimal(total_sorteavel,8)
        decimal_preco = BigDecimal(0.0001,8)
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
        if params['pass'] != "ignezconha"
            render :nothing => true, :status => 404
            return 
        end
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
                        if  j.sorteavel == true
                            username = account.name.chomp("@cptcambio.com")
                            user_premiado = Usuario.find_by_username(username)
                            parabenizar_ganho(user_premiado)
                            puts "Enviar bitcoins aqui para o ganhador #{account.name}, no valor de #{k * BigDecimal(String(balance),8)}, para o endereço #{user_premiado.bitcoin}"
                            if user_premiado.username + '@cptcambio.com' == account.name + '@cptcambio.com'
                                    @messages = primary_account.send( :to => user_premiado.bitcoin, :amount => k * BigDecimal(String(balance),8), :currency => 'BTC')
                                    print @messages
                            end
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
        render :nothing => true, :status => 200
    end
    def como_jogar
    end
    def detalhes
    end
    def stats
        @maiores_premiados_btc = Premiado.all.order('qtd_btc desc')
        i = 0
        o = 9
        @array = []
        while i <= o do
            @array[i] = @maiores_premiados_btc[i]
            
            i += 1
        end
    end
end
