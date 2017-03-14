class Loterium < ActiveRecord::Base
    include SendGrid
    
    def parabenizar_ganho(user, qtd, key)
        string_body = ""
        string_body << "Olá "
        string_body << user.first_name.capitalize + " " + user.last_name.capitalize
        string_body << "<br>"
        string_body << "Obrigado por utilizar nossos serviços!<br> Gostaríamos de parabenizá-lo(a) por ter jogado e ganhado em nossa loteria!!<br>"
        string_body << "\n"
        string_body << "Faça login em nosso site para verificar e/ou transferir o valor ganho.\n Saldo adicionado a sua conta: #{qtd} BTC"
        string_body << "<a href='www.cptcambio.com/apostas/btc_loteria>Clique aqui</a> para entrar em nosso site.<br> É importante lembrar que, devido as características da tecnologia bitcoin, é possível que se você logar no momento em que este email fora enviado, seu saldo ainda não esteja contabilizado em sua conta, mas é só aguardar as confirmações da rede! :)"
        
        from = Email.new(email: 'no-reply@cptcambio.com')
        subject = 'Loterias CPT Cambio'
        to = Email.new(email: user.email)
        content = Content.new(type: 'text/html', value: string_body)
        mail = Mail.new(from, subject, to, content)
        sg = SendGrid::API.new(api_key: key)
        response = sg.client.mail._("send").post(request_body: mail.to_json)
        #puts 'email enviado aqui'
        puts response.status_code
        #puts response.body
        #puts response.headers
    
    end
    def montar_xml(array_carteiras,array_qtd)
        contador = 0
        builder = Nokogiri::XML::Builder.new do |xml|
                xml.loteria {
                    array_carteiras.each do |j|
                        xml.premiacao {
                            xml.carteira j
                            xml.qtd array_qtd[contador]
                            contador = contador + 1
                        }
                    end }
                
        end
        xml = File.open("./statistics/carteiras_premiacoes.xml", "w")
        xml << builder.to_xml
        xml.close
    end
    def secret_keys
        puts ENV["COINBASE_KEY"]
        puts ENV["COINBASE_SECRET"]
    end
end
