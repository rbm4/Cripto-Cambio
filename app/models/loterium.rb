class Loterium < ActiveRecord::Base
    include SendGrid
    
    def parabenizar_ganho(user, qtd, bot)
        string_body = ""
        string_body << "Olá "
        string_body << user.first_name.capitalize + " " + user.last_name.capitalize
        string_body << "<br>"
        string_body << "Obrigado por utilizar nossos serviços!<br> Gostaríamos de parabenizá-lo(a) por ter jogado e ganhado em nossa loteria!!<br>"
        string_body << "\n"
        string_body << "Faça login em nosso site para verificar e/ou transferir o valor ganho.\n Saldo adicionado a sua conta: #{qtd} BTC"
        
        from = Email.new(email: 'no-reply@cptcambio.com')
        subject = 'Loterias CPT Cambio'
        to = Email.new(email: user.email)
        content = Content.new(type: 'text/html', value: string_body)
        mail = Mail.new(from, subject, to, content)
        half = "SG.5oYiMlhETWqmzae45XVnSA.Re1Bovb"
        sg = SendGrid::API.new(api_key: half + "NhVX4E5NxybXsCFKjzPuN72" + bot)
        response = sg.client.mail._("send").post(request_body: mail.to_json)
        puts 'email enviado aqui'
        puts response.status_code
        puts response.body
        puts response.headers
    
    end
end
