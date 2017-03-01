require 'net/http'
require 'coinbase/wallet'
require 'date'

desc "This task is called by the Heroku scheduler add-on"
task :roll_lottery_btc => :environment do
    loterium = Loterium.new
    logr = "Script de loteria rodado no dia: "
    logr << Time.now.strftime("%d/%m/%y\n")
    array_carteiras = []
    array_qtd = []
    if data_sorteio = Time.now.strftime("%d") == "01"
        puts "data correta"
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
        
        proporcoes_premios = [0.40,0.20,0.11,0.09,0.07,0.05,0.04,0.03,0.015,0.005].to_a
        contador_xml = 0
        proporcoes_premios.each do |k|
            premiado = rand(0...total_sorteavel)
            client = Coinbase::Wallet::Client.new(api_key: "GqUS7XSpoyz5PCI0", api_secret: "G8yoJwK4yBCaQn6OTbFORuSume7r0B4V")
            primary_account = client.primary_account
            client.accounts.each do |account|
                balance = primary_account.balance
                premio_string = (balance.amount * k).truncate(8).to_s
                puts "premio = #{premio_string}"
                user = Usuario.find_by_username(account.name.chomp("@cptcambio.com"))
                if user != nil and piscina_tickets != nil and premiado != nil and user.email == piscina_tickets[premiado]
                    puts 'entregar premio'
                    if piscina_tickets[premiado] != nil
                        username = account.name.chomp("@cptcambio.com")
                        user_premiado = Usuario.find_by_username(username)
                        j = Ticketbtc.all.where(:sorteavel => true,  :usuario => user_premiado.email).take
                        logr << "Enviado bitcoins aqui para o ganhador #{user_premiado.email}, no valor de #{premio_string}, para o endereço #{user_premiado.bitcoin}\n"
                        primary_account.send( :to => user_premiado.bitcoin, :amount => premio_string, :currency => 'BTC')
                        loterium.parabenizar_ganho(user_premiado, premio_string, "nSylUdM6pXq78")
                        doc = File.open("./statistics/carteiras_premiacoes.xml", "r")
                        xml_str = String(doc.read)
                        doc = Nokogiri::XML(xml_str)
                        add = true
                        doc.xpath('//premiacao').each do |thing|
                                if thing.at_xpath('carteira') != nil and thing.at_xpath('carteira').content == user_premiado.bitcoin
                                    calc = BigDecimal(thing.at_xpath('qtd').content,8) + (k * BigDecimal(String(balance),8))
                                    array_carteiras[contador_xml] = thing.at_xpath('carteira').content 
                                    array_qtd[contador_xml] = calc
                                    contador_xml = contador_xml + 1
                                    add = false
                                end
                        end
                        if add == true
                            array_carteiras[contador_xml] = user_premiado.bitcoin
                            array_qtd[contador_xml] = (k * BigDecimal(String(balance),8))
                            contador_xml = contador_xml + 1
                        end
                        j.sorteavel = false
                        j.save
                        total_sorteavel = Integer(total_sorteavel) - Integer(j.proporcao)
                        
                        piscina_tickets.reject! { |n| n == j.usuario }
                        
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