require 'net/http'
require 'coinbase/wallet'
require 'date'

desc "This task is called by the Heroku scheduler add-on"
task :roll_lottery_btc => :environment do
        loterium = Loterium.new
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
            client = Coinbase::Wallet::Client.new(api_key: "GqUS7XSpoyz5PCI0", api_secret: "G8yoJwK4yBCaQn6OTbFORuSume7r0B4V")
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
                            loterium.parabenizar_ganho(user_premiado, k * BigDecimal(String(balance),8), "nSylUdM6pXq78")
                            puts "Enviar bitcoins aqui para o ganhador #{account.name}, no valor de #{k * BigDecimal(String(balance),8)}, para o endereço #{user_premiado.bitcoin}"
                            if user_premiado.username + '@cptcambio.com' == account.name
                                    @messages = primary_account.send( :to => user_premiado.bitcoin, :amount => (k * BigDecimal(String(balance),8)), :currency => 'BTC')
                                    print @messages
                            end
                            j.sorteavel = false
                            j.save
                            total_sorteavel = Integer(total_sorteavel) - Integer(j.proporcao)
                            piscina_tickets.reject! { |n| n == j.usuario }
                        else
                            puts "usuário já premiado, fazer algo"
                        end
                    else
                        puts "sem usuários para serem sorteados"
                    end
                end
            end
        end
        j = Ticketbtc.all.where(:sorteavel => true)
        j.each do |g|
            g.sorteavel = false
            g.save
        end
        data_sorteio = Time.now.strftime("%d/%m/%Y")
        all = Loterium.all
        g = all[0]
        if g == nil
            f = Loterium.new
            f.data = data_sorteio
            f.save
        else
            a_date = Date.parse(g.data)
            b_date = a_date + 31
            g.data = b_date
            g.save
        end
        
        puts "Sorteio realizado, todos os tickets estão não sorteáveis, aplicar nova data de sorteio."
end