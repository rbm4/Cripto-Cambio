class Usermailer < ApplicationMailer
	default :from => "admin@cptcambio.com"

 	def registration_confirmation(usuario)
    	@user = usuario
    	mail(:to => "#{@user.username} <#{@user.email}>", :subject => "Confirmação de registro Cripto Câmbio")
 	end
end
