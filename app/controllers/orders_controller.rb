class OrdersController < ApplicationController
    before_action :require_login 
    def show
    end
    def destroy
        current_order.destroy
        session[:order_id] = nil
        redirect_to '/store', @messages => "Basket emptied successfully."
    end
    def checkout
        @order = Shoppe::Order.find(current_order.id)
        if request.patch?
             if @order.proceed_to_confirm(params[:order].permit(:first_name, :billing_address1, :billing_address2, :billing_address3, :billing_address4, :billing_postcode, :email_address))
                  redirect_to checkout_payment_path
             end
        end
    end
    def payment
        if request.post?
            redirect_to checkout_confirmation_path
        end
    end
    def checkoutpgseguro
        @order = Shoppe::Order.find(current_order.id)
        if request.patch?
            if @order.proceed_to_confirm(params[:order].permit(:first_name, :billing_address1, :billing_address2, :billing_address3, :billing_address4, :billing_postcode, :email_address))
                redirect_to '/'
            end
        end
    end
    def exchange_order_create
        #par: nil, tipo: nil, amount: nil, user: nil, has_execution: nil, price: nil, status: nil
        #validações
        current_user_saldo = eval(current_user.saldo_encrypted)
        session[:moeda1_compra] = nil
        session[:moeda2_compra] = nil
        session[:moeda1_venda] = nil
        session[:moeda2_venda] = nil
        order = Exchangeorder.new
        
        order.par = "#{params["moeda1"]}/#{params["moeda2"]}"
        
        if params["commit"] == "Comprar"
            type = "buy"
            discount_saldo = BigDecimal(params["qtd_moeda1#{type}"].gsub(/,/,"."),8) * BigDecimal(params["qtd_moeda2#{type}"].gsub(/,/,"."),8)
            if BigDecimal(current_user_saldo["#{params["moeda2"]}"],8) > discount_saldo
                current_user_saldo["#{params["moeda2"]}"] = (BigDecimal(current_user_saldo["#{params["moeda2"]}"],8) - discount_saldo).to_s
                current_user.saldo_encrypted = current_user_saldo
                current_user.save #saldo removido do usuário !!! >>>>> discount_saldo.to_s <<<<<<< foi o valor removido, implementar nota fiscal por email aqui 
                consulta_ordem_oposta = Exchangeorder.where("par = :str_par AND tipo = :tupe AND status = :stt", {str_par: order.par, tupe: "sell", stt: "open"}).order(price: :asc).limit(20)
            else
                p "sem saldo"
                @moeda_par1 = params["moeda1"]
                @moeda_par2 = params["moeda2"]
                @message_from_order_controller = "Você não tem saldo suficiente para iniciar esta negociação!"
                return
            end
        elsif params["commit"] == "vender"
            type = "sell"
            current_user_saldo["#{params["moeda1"]}"] = (BigDecimal(current_user_saldo["#{params["moeda1"]}"],8) - BigDecimal(params["qtd_moeda1#{type}"].gsub(/,/,"."),8)).to_s
            if BigDecimal(current_user_saldo["#{params["moeda1"]}"],8) > 0
                current_user.saldo_encrypted = current_user_saldo
                current_user.save 
                consulta_ordem_oposta = Exchangeorder.where("par = :str_par AND tipo = :tupe AND status = :stt", {str_par: order.par, tupe: "buy", stt: "open"}).order(price: :desc).limit(20)
            else
                p "sem saldo"
                @moeda_par1 = params["moeda1"]
                @moeda_par2 = params["moeda2"]
                @message_from_order_controller = "Você não tem saldo suficiente para iniciar esta negociação!"
                return
            end
        end
        order.tipo = type
        order.amount = params["qtd_moeda1#{type}"].gsub(/,/,".")
        order.price = params["qtd_moeda2#{type}"].gsub(/,/,".")
        order.user = current_user.username
        order.has_execution = false
        order.status = "open"
        inicial_amount = BigDecimal(order.amount,8)
        current_amount = inicial_amount
        #Verificar preço das outras ordens "opostas" e verificar se há ordens para preencher a ordem recém criada.
        #Verificação realizada, funcionalidades de compra / venda e salvar ordens realizada para todos os pares. 
        #    
        #
        if consulta_ordem_oposta.first != nil && order.tipo == "buy" && consulta_ordem_oposta.first.price <= order.price   #a primeira ordem consultada tem um "preço" maior do que a ordem criada? Se não, e caso for ordem de compra, realizar a troca de créditos
            consulta_ordem_oposta.each do |b|
                if BigDecimal(current_amount,8) > 0
                    if b.price <= order.price && BigDecimal(b.amount,8) >= BigDecimal(order.amount,8) #se o volume total da ordem do livro for maior, compeltar a ordem recém aberta totalmente e transferir fundos
                        p "ordem de compra que deve ser abatida com ordem de venda"
                        #media_prices = (b.price + order.price)/2
                        result_amount = BigDecimal(b.amount,8) - BigDecimal(order.amount,8)
                        order.status = "executora"
                        obj = Usuario.find_by_username(b.user) #vendedor, recebe moeda2
                        saldo = eval(obj.saldo_encrypted)
                        #saldo["#{params["moeda2"]}"].decrypt
                        p "adicionar saldo de #{((BigDecimal(b.price) * BigDecimal(order.amount,8)) * 0.995).to_s} '#{params["moeda2"]}' pro vendedor das #{b.amount} #{params["moeda1"]} - #{order.amount} #{params["moeda1"]}"
                        saldo["#{params["moeda2"]}"] = (BigDecimal(saldo["#{params["moeda2"]}"],8) + (BigDecimal(b.price) * BigDecimal(order.amount,8)) * 0.995).to_s #volume da ordem recém aberta multiplicado pelo preço da ordem do livro é o resultado do saldo do usuário descontado o fee 0,5%
                        obj.saldo_encrypted = saldo.to_s
                        obj.save #atualizar saldo do que vende as moedas
                        
                        if result_amount <= 0 #ordem completamente executada
                            b.status = "executada"
                            b.has_execution = true
                            b.save #salvar ordem antiga do livro com o saldo atual > 0 
                        else #caso a ordem seja parcialmente executada
                            b.amount = result_amount.to_s #resultante do montante das duas transações é o que sobra na transação do livro convertido em string
                            b.has_execution = true
                            b.save #ordem antiga é mantida no livro de negociações 
                            new = Exchangeorder.new
                            new.par = order.par
                            new.user = b.user
                            new.status = "executada"
                            new.price = b.price
                            new.amount = order.amount
                            new.tipo = "sell"
                            new.has_execution = true
                            new.save #ordem salva apenas para registro, pois o cálculo do saldo foi feito acima. essa ordem é uma ordem parcial e tem o montante executado o total da ordem recem aberta
                        end
                        
                        
                        user = Usuario.find_by_username(order.user) #encontrar usuário da ordem atual (Comprador, recebe moeda1)
                        saldo2 = eval(user.saldo_encrypted) #recuperar saldo do usuário
                        p "adicionar saldo de #{(inicial_amount*0.995).to_s} ao comprador por ter executado a ordem inteira de uma vez só"
                        saldo2["#{params["moeda1"]}"] = (BigDecimal(saldo2["#{params["moeda1"]}"],8) + (inicial_amount * 0.995 )).to_s#atualizar saldo do usuário com o preço da ordem atual descontado o fee 0,5%
                        user.saldo_encrypted = saldo2.to_s
                        user.save #atualizar saldo do usuário que comrpou as moedas
                        current_amount = 0
                        order.has_execution = true
                        order.save #ordem completamente finalizada e salva
                        p obj.saldo_encrypted
                        p user.saldo_encrypted 
                        @message_from_order_controller = "Ordem de compra abateu uma ordem de venda do livro de ofertas!"
                        @moeda_par1 = params["moeda1"]
                        @moeda_par2 = params["moeda2"]
                        
                        #obj = User.find_by_username(order.user)
                        #saldo = obj.encrypted_saldos.to_hash
                        #obj.encrypted_saldo = encrypt(saldo["#{params["moeda2"}" = ])
                    elsif b.price <= order.price && BigDecimal(b.amount,8) <= BigDecimal(order.amount,8)
                        p "ordem de compra que deve ser abatida parcialmente com ordem de vendas"
                        #media_prices = (b.price + order.price)/2
                        result_amount = BigDecimal(order.amount,8) - BigDecimal(b.amount,8)
                        order.status = "open"
                        order.has_execution = true
                        obj = Usuario.find_by_username(b.user) #vendedor, recebe moeda2 da ordem aberta
                        saldo = eval(obj.saldo_encrypted)
                        #saldo["#{params["moeda2"]}"].decrypt
                        p "adicionar saldo de #{((BigDecimal(b.price) * BigDecimal(b.amount,8)) * 0.995).to_s} '#{params["moeda2"]}' pro vendedor das #{b.amount} #{params["moeda1"]} - #{order.amount} #{params["moeda1"]}"
                        saldo["#{params["moeda2"]}"] = (BigDecimal(saldo["#{params["moeda2"]}"],8) + ((BigDecimal(b.price) * BigDecimal(b.amount,8)) * 0.995)).to_s #volume da ordem recém aberta multiplicado pelo preço da ordem do livro é o resultado do saldo do usuário descontado o fee 0,5%
                        obj.saldo_encrypted = saldo.to_s
                        obj.save #atualizar saldo do que vende as moedas
                         #resultante do montante das duas transações é o que sobra na transação do livro convertido em string
                        b.status = "executada" 
                        b.has_execution = true
                        b.save #salvar ordem antiga de venda no livro como "executada"
                        new = Exchangeorder.new
                        new.par = order.par
                        new.user = order.user
                        new.status = "executora"
                        new.price = order.price
                        new.amount = b.amount
                        new.tipo = "buy"
                        new.has_execution = true
                        new.save #ordem salva apenas para registro da ordem executada parcialmente com o valor(amount) da ordem que estava aberta, pois o cálculo do saldo foi feito acima.
                        
                        user = Usuario.find_by_username(order.user) #encontrar usuário da ordem atual (Comprador, recebe moeda1)
                        saldo2 = eval(user.saldo_encrypted) #recuperar saldo do usuário
                        p "adicionar saldo de #{(BigDecimal(b.amount,8) * 0.995).to_s} ao comprador por ter executado a ordem parcialmente"
                        saldo2["#{params["moeda1"]}"] = (BigDecimal(saldo2["#{params["moeda1"]}"],8) + (BigDecimal(b.amount,8) * 0.995 )).to_s#atualizar saldo do usuário com o preço da ordem atual descontado o fee 0,5%
                        user.saldo_encrypted = saldo2.to_s
                        user.save #atualizar saldo do usuário que comrpou as moedas
                        current_amount = BigDecimal(order.amount,8) - BigDecimal(b.amount,8)
                        order.amount = current_amount.to_s
                        order.has_execution = true
                        order.save #ordem parcialmente finalizada e salva com o "value" atual
                        p obj.saldo_encrypted
                        p user.saldo_encrypted 
                        @message_from_order_controller = "Ordem de compra abatida parcialmente por uma ou mais ordens de venda!"
                        @moeda_par1 = params["moeda1"]
                        @moeda_par2 = params["moeda2"]
                    end
                end
            end
            return
        elsif consulta_ordem_oposta.first != nil && order.tipo == "sell" and consulta_ordem_oposta.first.price >= order.price
            p "abater ordem de venda com ordem de compra"
            consulta_ordem_oposta.each do |b|
                p current_amount
                if BigDecimal(current_amount,8) > 0
                    if b.price >= order.price && BigDecimal(b.amount,8) >= BigDecimal(order.amount,8) #se o volume total da ordem do livro for maior, compeltar a ordem recém aberta totalmente e transferir fundos
                        p "ordem de venda que deve ser abatida com ordem de compra"
                        #media_prices = (b.price + order.price)/2
                        result_amount = BigDecimal(b.amount,8) - BigDecimal(order.amount,8)
                        order.status = "executora"
                        obj = Usuario.find_by_username(b.user) #vendedor, recebe moeda1
                        saldo = eval(obj.saldo_encrypted)
                        #saldo["#{params["moeda2"]}"].decrypt
                        p "adicionar saldo de #{(BigDecimal(order.amount,8) * 0.995).to_s} '#{params["moeda1"]}' pro comprador das #{b.amount} #{params["moeda1"]} - #{order.amount} #{params["moeda1"]}"
                        saldo["#{params["moeda1"]}"] = (BigDecimal(saldo["#{params["moeda1"]}"],8) + (BigDecimal(order.amount,8)) * 0.995).to_s #volume da ordem recém aberta multiplicado pelo preço da ordem do livro é o resultado do saldo do usuário descontado o fee 0,5%
                        obj.saldo_encrypted = saldo.to_s
                        obj.save #atualizar saldo do que vende as moedas
                        
                        if result_amount <= 0 #ordem completamente executada
                            b.status = "executada"
                            b.has_execution = true
                            b.save #salvar ordem antiga do livro com o saldo atual > 0 
                        else #caso a ordem seja parcialmente executada
                            b.amount = result_amount.to_s #resultante do montante das duas transações é o que sobra na transação do livro convertido em string
                            b.has_execution = true
                            b.save #ordem antiga é mantida no livro de negociações 
                            new = Exchangeorder.new
                            new.par = order.par
                            new.user = b.user
                            new.status = "executada"
                            new.price = b.price
                            new.amount = order.amount
                            new.tipo = "buy"
                            new.has_execution = true
                            new.save #ordem salva apenas para registro, pois o cálculo do saldo foi feito acima. essa ordem é uma ordem parcial e tem o montante executado o total da ordem recem aberta
                        end
                        
                        
                        user = Usuario.find_by_username(order.user) #encontrar usuário da ordem atual (Comprador, recebe moeda1)
                        saldo2 = eval(user.saldo_encrypted) #recuperar saldo do usuário
                        p "adicionar saldo de #{((inicial_amount * BigDecimal(b.price))*0.995).to_s} #{params["moeda2"]} pra quem vendeu as bitcoins"
                        saldo2["#{params["moeda2"]}"] = (BigDecimal(saldo2["#{params["moeda2"]}"],8) + ((inicial_amount * BigDecimal(b.price))*0.995)).to_s#atualizar saldo do usuário com o preço da ordem atual descontado o fee 0,5%
                        user.saldo_encrypted = saldo2.to_s
                        user.save #atualizar saldo do usuário que comrpou as moedas
                        current_amount = 0
                        
                        order.has_execution = true
                        order.save #ordem completamente finalizada e salva
                        p obj.saldo_encrypted
                        p user.saldo_encrypted 
                        @message_from_order_controller = "Ordem de compra abateu uma ordem de venda do livro de ofertas!"
                        @moeda_par1 = params["moeda1"]
                        @moeda_par2 = params["moeda2"]
                        
                        #obj = User.find_by_username(order.user)
                        #saldo = obj.encrypted_saldos.to_hash
                        #obj.encrypted_saldo = encrypt(saldo["#{params["moeda2"}" = ])
                    elsif b.price >= order.price && BigDecimal(b.amount,8) <= BigDecimal(order.amount,8)
                        p "ordem de compra do livro que deve ser abatida parcialmente com ordem de venda aberta"
                        #media_prices = (b.price + order.price)/2
                        result_amount = BigDecimal(order.amount,8) - BigDecimal(b.amount,8)
                        order.status = "open"
                        order.has_execution = true
                        obj = Usuario.find_by_username(b.user) #vendedor, recebe moeda2 da ordem aberta
                        saldo = eval(obj.saldo_encrypted)
                        #saldo["#{params["moeda2"]}"].decrypt
                        p "adicionar saldo de #{((BigDecimal(b.price) * BigDecimal(b.amount,8)) * 0.995).to_s} '#{params["moeda2"]}' pro vendedor das #{b.amount} #{params["moeda1"]} - #{order.amount} #{params["moeda1"]}"
                        saldo["#{params["moeda2"]}"] = (BigDecimal(saldo["#{params["moeda2"]}"],8) + ((BigDecimal(b.price) * BigDecimal(b.amount,8)) * 0.995)).to_s #volume da ordem recém aberta multiplicado pelo preço da ordem do livro é o resultado do saldo do usuário descontado o fee 0,5%
                        obj.saldo_encrypted = saldo.to_s
                        obj.save #atualizar saldo do que vende as moedas
                        #resultante do montante das duas transações é o que sobra na transação do livro convertido em string
                        
                        b.status = "executada" 
                        b.has_execution = true
                        b.save #salvar ordem antiga de venda no livro como "executada"
                        new = Exchangeorder.new
                        new.par = order.par
                        new.user = order.user
                        new.status = "executora"
                        new.price = order.price
                        new.amount = b.amount
                        new.tipo = "sell"
                        new.has_execution = true
                        new.save #ordem salva apenas para registro da ordem executada parcialmente com o valor(amount) da ordem que estava aberta, pois o cálculo do saldo foi feito acima.
                       
                        
                        
                        user = Usuario.find_by_username(order.user) #encontrar usuário da ordem atual (Comprador, recebe moeda1)
                        saldo2 = eval(user.saldo_encrypted) #recuperar saldo do usuário
                        p "adicionar saldo de #{(BigDecimal(b.amount,8) * 0.995).to_s} ao vendedor de moeda1 por ter executado a ordem parcialmente"
                        saldo2["#{params["moeda1"]}"] = (BigDecimal(saldo2["#{params["moeda1"]}"],8) + (BigDecimal(b.amount,8) * 0.995 )).to_s#atualizar saldo do usuário com o preço da ordem atual descontado o fee 0,5%
                        user.saldo_encrypted = saldo2.to_s
                        user.save #atualizar saldo do usuário que comrpou as moedas
                        current_amount = BigDecimal(order.amount,8) - BigDecimal(b.amount,8)
                        order.amount = current_amount.to_s
                        order.has_execution = true
                        order.save #ordem parcialmente finalizada e salva com o "value" atual
                        p obj.saldo_encrypted
                        p user.saldo_encrypted 
                        @message_from_order_controller = "Ordem de compra abatida parcialmente por uma ou mais ordens de venda!"
                        @moeda_par1 = params["moeda1"]
                        @moeda_par2 = params["moeda2"]
                    end
                end
            end
            return
        end
        if order.save #ordem pode ser de compra ou venda mas não atende nenhum requisito para fazer outras ordens, adicioná-la ao "livro de ordens"
            p "salvou ordem normalmente. "
            @message_from_order_controller = "Ordem adicionada ao livro de ofertas!"
            
        else
            @message_from_order_controller = "Houve algum erro. Por favor tente novamente."
        end
        
        @moeda_par1 = params["moeda1"]
        @moeda_par2 = params["moeda2"]
        #ordem criada e salva, após ser salva, verificar se há ordens existentes que executem esta.
    end
    def public_stats
        if session[:moeda1_par] == nil or session[:moeda2_par] == nil
            @moeda_par1 = "BTC"
            @moeda_par2 = "BRL"
        else
            @moeda_par1 = session[:moeda1_par]
            @moeda_par2 = session[:moeda2_par]
        end
        string_par = "#{@moeda_par1 }/#{@moeda_par2}"
        g = 0
        f = 0
        o = 0
        @consulta_compra = Array.new
        @consulta_venda = Array.new
        @consulta_realizadas = Array.new
        consulta = Exchangeorder.where("par = :str_par AND tipo = :type AND status = :stt", {str_par: string_par, type: "buy", stt: "open"}).order(price: :desc).limit(20)
        consulta.each do |h|
            @consulta_compra[g] = h
            g += 1
        end
        consulta2 = Exchangeorder.where("par = :str_par AND tipo = :type AND status = :stt", {str_par: string_par, type: "sell", stt: "open"}).order(price: :asc).limit(20)
        consulta2.each do |a|
            @consulta_venda[f] = a
            f += 1
        end
        consulta3 = Exchangeorder.where("par = :str_par AND status = :stt", {str_par: string_par, stt: "executada"}).order(updated_at: :desc).limit(30)
        consulta3.each do |m|
            
            @consulta_realizadas[o] = m
            o += 1
        end
    end
end
