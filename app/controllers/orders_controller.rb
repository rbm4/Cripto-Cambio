class OrdersController < ApplicationController
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
        session[:moeda1_compra] = nil
        session[:moeda2_compra] = nil
        session[:moeda1_venda] = nil
        session[:moeda2_venda] = nil
        order = Exchangeorder.new
        order.par = "#{params["moeda1"]}/#{params["moeda2"]}"
        if params["commit"] == "Comprar"
            type = "buy"
            consulta_ordem_oposta = Exchangeorder.where("par = :str_par AND tipo = :type AND status = :stt", {str_par: string_par, type: "sell", stt: "open"}).order(price: :asc).limit(20)
        elsif params["commit"] == "vender"
            type = "sell"
            consulta_ordem_oposta = Exchangeorder.where("par = :str_par AND tipo = :type AND status = :stt", {str_par: string_par, type: "buy", stt: "open"}).order(price: :desc).limit(20)
        end
        order.tipo = type
        order.amount = params["qtd_moeda1#{type}"].gsub(/,/,".")
        order.user = current_user.username
        order.has_execution = false
        order.status = "open"
        order.price = params["qtd_moeda2#{type}"].gsub(/,/,".")
        #Verificar preço das outras ordens "opostas" e verificar se há ordens para preencher a ordem recém criada.
        if consulta_ordem_oposta.first.price >= order.price #a primeira ordem consultada tem um "preço" maior do que a ordem criada? Se não, e caso for ordem de compra, realizar a troca de créditos
            
        end
        if order.save
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
            @moeda_par1 = "btc"
            @moeda_par2 = "brl"
        else
            @moeda_par1 = session[:moeda1_par]
            @moeda_par2 = session[:moeda2_par]
        end
        string_par = "#{@moeda_par1 }/#{@moeda_par2}"
        g = 0
        f = 0
        @consulta_compra = Array.new
        @consulta_venda = Array.new
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
