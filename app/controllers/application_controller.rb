class ApplicationController < ActionController::Base
  require 'rest-client'
  require 'blockchain'
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  helper_method :bitcoinpay
  protect_from_forgery with: :exception
  attr_accessor :viewname
  helper_method :useremail
  helper_method :current_user
  helper_method :current_order
  helper_method :has_order?
  helper_method :username
  helper_method :receber_pagamento
  helper_method :moeda
  helper_method :buy
  helper_method :convert_bitcoin
  helper_method :is_admin?
  helper_method :archive_wallet
  helper_method :itens_string
  helper_method :params_post
  helper_method :userphone
  after_filter :cors_set_access_control_headers
  helper_method :wich_status
  helper_method :brl_btc
  helper_method :bitcoin_para_real
  helper_method :type
  helper_method :standard_conversion
  helper_method :litecoin_para_bitcoin
  
  def calcular_metodos
    puts 'PRODUÇÃO'
    
    @product = Shoppe::Product.root.find_by_permalink(params['calculo']['permalink'])
    puts params['calculo']['moeda']
    if params['calculo']['moeda'] == 'btc'
      a = Bitcoin.valid_address? params['calculo']['address']
      if  a == false
        @warning = false
      elsif a == true
        @warning = true
      end
      @preco_pagseguro = String(bitcoin_para_real(params['calculo']['volume'])) + ' BRL'
      @carteira = params['calculo']['address']
      @desejado = params['calculo']['volume']
      puts 'render'
      @render = true
      #render 'store/show'
      respond_to do | format |  
        format.js {render :layout => false}  
      end
    end
    if params['calculo']['moeda'] == 'ltc' #ofertas de pgto para LITECOINS
      
      a = params['calculo']['address'].match(/^L[a-km-zA-HJ-NP-Z1-9]{26,33}$/)
      if  a == nil
        @warning = false
      elsif a != nil
        @warning = true
      end
      ltc_real = litecoin_para_real
      decimal = BigDecimal(params['calculo']['volume'],5)
      x_real = BigDecimal(ltc_real,5).mult(decimal,5)
      @preco_pagseguro = String(x_real) + ' BRL'
      btc_ltc = litecoin_para_bitcoin
      x_btc = BigDecimal(btc_ltc,7).mult(decimal,7)
      @preco_bitcoin = String(x_btc) + ' BTC'
      @carteira = params['calculo']['address']
      @desejado = params['calculo']['volume']
      puts 'render'
      @render = true
      #render 'store/show'
      respond_to do | format |  
        format.js {render :layout => false}  
      end
    end
  end
  
  def brl_btc(value)
    convert_url = 'https://blockchain.info/tobtc?currency=BRL&value=' + value.to_s
    convert_uri = URI(convert_url)
    response_convert = Net::HTTP.get(convert_uri)
    puts response_convert
    result = BigDecimal(response_convert).mult(0.75,7) 
    puts result
    result
  end
  def bitcoin_para_real(value)
    
    convert_url = 'https://blockchain.info/ticker'
    convert_uri = URI(convert_url)
    response_convert = Net::HTTP.get(convert_uri)
    hash = JSON.parse(response_convert)
    conversao = hash['BRL']['last'] # 1 BTC
    puts String(value) + '/' + String(conversao)
    if value == nil 
      result = BidDecimal(params['dynamic']).mult(conversao,2)
      @preco_pagseguro = result
      render 'calculos'
    end
    result = BigDecimal(value,7).mult(conversao,2)
    result = result.mult(1.3,2) #valor em real
    result
  end
  def litecoin_para_bitcoin
    convert_url = 'https://shapeshift.io/marketinfo/ltc_btc'
    convert_uri = URI(convert_url)
    response_convert = Net::HTTP.get(convert_uri)
    hash = JSON.parse(response_convert)
    conversao = hash['rate'] # 1 ltc em btc
    resultado = BigDecimal(conversao,5).mult(1.3,5)
    resultado
  end
  def bitcoin_para_litecoin
    convert_url = 'https://shapeshift.io/marketinfo/btc_ltc'
    convert_uri = URI(convert_url)
    response_convert = Net::HTTP.get(convert_uri)
    hash = JSON.parse(response_convert)
    conversao = hash['rate'] # 1 btc em ltc
    resultado = BigDecimal(conversao,5).mult(1.3,5)
    resultado
  end
  def litecoin_para_real
    convert_url = 'https://www.mercadobitcoin.com.br/api/ticker_litecoin/'
    convert_uri = URI(convert_url)
    response_convert = Net::HTTP.get(convert_uri)
    hash = JSON.parse(response_convert)
    conversao = hash['ticker']['high'] # 1 ltc em real
    resultado = BigDecimal(conversao,2).mult(1.3,2)
    resultado
  end
  def standard_conversion(currency)
    tags = ''
    if currency == 'btc'
      
      tags << '<select multiple class="form-control"style="width:260px;line-height:60px;margin-left:25%;margin-top:-5%">'
      tags << '<option>'
      tags << 'BRL: ' + String(bitcoin_para_real(1))
      tags << '</option>'
      tags << '<option>'
      tags << 'LTC: ' + String(bitcoin_para_litecoin)
      tags << '</option>'
      tags << '</select>'
      return tags
    end
    if currency == 'ltc'
      tags << '<select multiple class="form-control" style="width:260px;line-height:60px;margin-left:25%;margin-top:-5%">'
      tags << '<option>'
      tags << 'BTC: ' + String(litecoin_para_bitcoin)
      tags << '</option>'
      tags << '<option>'
      tags << 'BRL: ' + String(litecoin_para_real)
      tags << '</option>'
      tags << '</select>'
      return tags
    end
    
  end
  def type(commit, tipo_moeda, valor_moeda)
        string = ""
        fim = false
        sum = false
        commit.each_char do |h|
            if h == '"' and fim == false
                sum = true
            end
            if sum == true and h != '"' and h != "="
                string << h
                fim = true
            end
            
            if h == '=' and fim == true
                
                sum = false
            end
        end
        dados = Array.new
        if string == 'pagseguro'
            moeda = 'BRL'
            dados[0] = moeda
            
            if tipo_moeda == 'btc'
              dados[1] = bitcoin_para_real(valor_moeda) #quanto devo pagar em real
            end
            if tipo_moeda == 'ltc'
              b = litecoin_para_real
              decimal = BigDecimal(params['pagamento']['volume'],5)
              x_real = BigDecimal(b,5).mult(decimal,5)
              dados[1] = x_real
            end
        end
        if string == 'bitcoin'
          moeda = 'BTC'
          dados[0] = moeda
          if tipo_moeda == 'ltc'
            puts 'compra de litecoins com bitcoin'
          end
        end
        if string == 'litecoin'
          moeda = 'LTC'
          dados['moeda'] = moeda
        end
        dados
  end
  def wich_status(x)
    if x == '1'
      # 	Aguardando pagamento: o comprador iniciou a transação, mas até o momento o PagSeguro não recebeu nenhuma informação sobre o pagamento.
    end
    if x == '2'
      # Em análise: o comprador optou por pagar com um cartão de crédito e o PagSeguro está analisando o risco da transação. 
    end
    if x == '3'
      # Paga: a transação foi paga pelo comprador e o PagSeguro já recebeu uma confirmação da instituição financeira responsável pelo processamento. 
      return '3'
    end
    if x == '4'
      # Disponível: a transação foi paga e chegou ao final de seu prazo de liberação sem ter sido retornada e sem que haja nenhuma disputa aberta. 
    end
    if x == '5'
      # Em disputa: o comprador, dentro do prazo de liberação da transação, abriu uma disputa. 
    end
    if x == '6'
      # Devolvida: o valor da transação foi devolvido para o comprador. 
    end
    if x == '7'
      # Cancelada: a transação foi cancelada sem ter sido finalizada. 
    end
    if x == '8'
      # Debitado: o valor da transação foi devolvido para o comprador. 
    end
    if x == '9'
      # Retenção temporária: o comprador contestou o pagamento junto à operadora do cartão de crédito ou abriu uma demanda judicial ou administrativa (Procon). 
    end
    
    
  end
  def cors_set_access_control_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'POST'
    headers['Access-Control-Allow-Headers'] = '*'
    headers['Access-Control-Request-Method'] = 'pgseguro'
    headers['Access-Control-Max-Age'] = "1728000"
  end
  def params_post
    result = "'email' => 'ricardo.malafaia1994@gmail.com', 'token' => '95112EE828D94278BD394E91C4388F20', "
    itens = ""
    order = Shoppe::Order.find(current_order.id)
    order.order_items.each do |item|
      id = id + 1
      itens = itens + '"itemId' + id.to_s + '" => "' + id.to_s + '", ' + '"itemDescription"' + id.to_s + '" => "' + (item.ordered_item.full_name).to_s + '", ' + '"itemAmount' + id.to_s + '" => "' + (item.sub_total).to_s + '", '  + '"itemQuantity' + id.to_s + '" => "' + (item.quantity).to_s + '", '
    end
    result = result + itens + "'reference' => 'REF1234', 'senderName' => '" + username.to_s + "', 'senderEmail' => '" + useremail.to_s + "', 'shippingAddressStreet' =>  '" + params["pagamento"]["rua"].to_s + "',  'shippingAddressNumber' =>  '" + params["pagamento"]["numero"] + "' , 'shippingAddressComplement' => '" + params["pagamento"]["complemento"] + "', 'shippingAddressDistrict' => '" + params["pagamento"]["bairro"] + "', 'shippingAddressPostalCode' => '"+ params["pagamento"]["postcode"] + "', 'shippingAddressCity' => '" + params["pagamento"]["cidade"] + "', 'shippingAddressState' => '" + params["pagamento"]["estado"] +"', 'shippingAddressCountry' => '" + params["pagamento"]["pais"] + "'"
    puts result
    result
  end
  def itens_string
    id = 0
    string = ""
    order = Shoppe::Order.find(current_order.id)
    order.order_items.each do |item|
      id = id + 1
      string = string + '\&itemId' + id.to_s + '=' + id.to_s + '\&itemDescription' + id.to_s + '=' + (item.ordered_item.full_name).to_s + '&itemAmount' + id.to_s + '=' + (item.sub_total).to_s + '\&itemQuantity' + id.to_s + '=' + (item.quantity).to_s 
    end
    string
  end
  def current_user 
    @current_user ||= Usuario.find(session[:user_id]) if session[:user_id] 
  end
  def require_user 
    redirect_to '/login' unless current_user 
  end
  
  def require_logout
    redirect_to '/' if current_user
  end
  def useremail
    if @current_user == nil
      current_user
      @current_user.email
    else
      @current_user.email
    end
  end
  def username
    if @current_user == nil
      current_user
      @current_user.username
    else
      @current_user.username
    end
  end
  def moeda(string)
    if string == "BTCTEST"
      return "฿T"
    end
    if string == "LTCTEST"
      return " ŁT"
    end
    if string == "BTC"
      return " ฿"
    end
    if string == "LTC"
      return " Ł"
    end
  end
  private
  def current_order
    @current_order ||= begin
      if has_order?
        @current_order
      else
        order = Shoppe::Order.create(:ip_address => request.ip)
        session[:order_id] = order.id
        order
      end
    end
  end
  def is_admin?
    user = current_user
    if user.salt == 'admin'
      true
    else
      false
    end
  end
  def has_order?
    !!(
      session[:order_id] &&
      @current_order = Shoppe::Order.includes(:order_items => :ordered_item).find_by_id(session[:order_id])
    )
  end
  def convert_bitcoin(valor)
    string = 'https://blockchain.info/tobtc?currency=BRL&value=' + valor.to_s
    uri = URI(string)
    response = Net::HTTP.get(uri)
    response
  end
  def archive_wallet(address)
    url = 'https://block.io/api/v2/archive_addresses/?api_key=ac35-6ff5-e103-d1c3&addresses=' + address
    uri = URI(url)
    response = Net::HTTP.get(uri)
    hash = JSON.parse(response)
    puts hash
  end
  def bitcoinpay
    

    values = '{
  "settled_currency": "BTC",
  "return_url": "http://bmarket-rbm4.c9users.io",
  "notify_url": "bmarket-rbm4.c9users.io/blckrntf",
  "notify_email": "ricardo.malafaia1994@gmail.com",
  "price": 0.009,
  "currency": "BTC",
  "reference": {
    "customer_name": "Customer Name",
    "order_number": 1,
    "customer_email": "customer@example.com"
  },
  "item": "Order #1",
  "description": "Oder #1 description"
  }'

headers = {
  :content_type => 'application/json',
  :authorization => 'Token EbJxAGwqAK24uamGI9dS9L70'
}
url = 'https://www.bitcoinpay.com/api/v1/payment/btc'
response = RestClient.post url, values, headers
puts response
  end
end
