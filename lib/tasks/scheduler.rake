require 'net/http'
require 'coinbase/wallet'
require 'date'

desc "This task is called by the Heroku scheduler add-on"
task :roll_lottery_btc => :environment do
    logr = "Script de loteria rodado no dia: "
    logr << Time.now.strftime("%d/%m/%y\n")
    string_premiados = ""
    array_carteiras = []
    array_qtd = []
    if data_sorteio = Time.now.strftime("%d") == "24"
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
        contador_xml = 0
        proporcoes_premios.each do |k|
            premiado = rand(0...total_sorteavel)
            client = Coinbase::Wallet::Client.new(api_key: "GqUS7XSpoyz5PCI0", api_secret: "G8yoJwK4yBCaQn6OTbFORuSume7r0B4V")
            primary_account = client.primary_account
            client.accounts.each do |account|
                balance = primary_account.balance
                if premiado != nil and account.name == piscina_tickets[premiado]
                    if piscina_tickets[premiado] != nil
                        j = Ticketbtc.all.where(:sorteavel => true,  :usuario => account.name).take
                        if  j.sorteavel == true
                            username = account.name.chomp("@cptcambio.com")
                            user_premiado = Usuario.find_by_username(username)
                            loterium.parabenizar_ganho(user_premiado, k * BigDecimal(String(balance),8), "nSylUdM6pXq78")
                            logr << "Enviado bitcoins aqui para o ganhador #{account.name}, no valor de #{k * BigDecimal(String(balance),8)}, para o endereço #{user_premiado.bitcoin}\n"
                            if user_premiado.username + '@cptcambio.com' == account.name
                                    @messages = primary_account.send( :to => user_premiado.bitcoin, :amount => (k * BigDecimal(String(balance),8)), :currency => 'BTC')
                                    print @messages
                            end
                            doc = File.open("./statistics/carteiras_premiacoes.xml", "r")
                            xml_str = String(doc.read)
                            doc = Nokogiri::XML(xml_str)
                            add = true
                            doc.xpath('//premiacao').each do |thing|
                                    if thing.at_xpath('carteira') != nil and thing.at_xpath('carteira').content == user_premiado.bitcoin
                                        puts "carteiras presentes no arquivo."
                                        calc = BigDecimal(thing.at_xpath('qtd').content,8) + (k * BigDecimal(String(balance),8))
                                        array_carteiras[contador_xml] = thing.at_xpath('carteira').content 
                                        array_qtd[contador_xml] = calc
                                        contador_xml = contador_xml + 1
                                        add = false
                                    end
                            end
                            if add == true
                                puts 'teste'
                                array_carteiras[contador_xml] = user_premiado.bitcoin
                                array_qtd[contador_xml] = (k * BigDecimal(String(balance),8))
                                contador_xml = contador_xml + 1
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
        
        logr << "Sorteio realizado, todos os tickets estão não sorteáveis, aplicar nova data de sorteio.\n"
        logr << "Concluindo log.\n-------------------------\n"
    else
        logr << "Data errada, não realizar sorteio.\n"
        logr << "Concluindo log.\n-------------------------\n"
    end
    loging = loterium.montar_xml(array_carteiras,array_qtd)
    arquivo_log = File.open("./statistics/loteria.log", "a") do |j|
        j << logr
    end
end