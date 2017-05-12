class NegociacoesController < ApplicationController
    
    
    def notifications
        convert_url = 'https://www.mercadobitcoin.net/api/ticker/'
        convert_uri = URI(convert_url)
        response_convert = Net::HTTP.get(convert_uri)
        hash = JSON.parse(response_convert)
        @messages = "Preço de venda do bitcoin #{hash['ticker']['sell']} no Mercado Bitcoin"
        render 'sessions/loginerror'
    end
    def consultar_ticker
        tapi_id = ENV['TAPI_ID_MERCADO_BTC']
        tapi_secret = ENV['TAPI_KEY_MERCADO_BTC']
        host = 'www.mercadobitcoin.com.br'
        request_path = '/tapi/v3/'
        tapi_nonce = 1
        params = {
            'tapi_method': 'get_account_info',
            'tapi_nonce': tapi_nonce, 

        }
        params = URI.encode_www_form(params)
        params_string = request_path + '?' + params
        #parâmetros gerados, http feito
        
        #gerar hmac
        h = OpenSSL::HMAC.new(tapi_secret, OpenSSL::Digest.new('sha512'))
        h.update(params_string)
        tapi_mac = h.hexdigest()
        
        
        # Gerar cabeçalho da requisição
        headers = {
            'Content-type': 'application/x-www-form-urlencoded',
            'TAPI-ID': tapi_id,
            'TAPI-MAC': tapi_mac
        }
        
       
        #uri = URI.parse(host)
        #http.use_ssl = true
        res = Net::HTTP.start('www.mercadobitcoin.com.br') do |http|
            req = Net::HTTP::Post.new('/tapi/v3/?tapi_method=list_order')
            req['Content-Type'] = 'application/x-www-form-urlencoded'
            req['TAPI-ID'] = tapi_id
            req['TAPI-MAC'] = tapi_mac
            puts req['Content-type']
            http.request(req)
        end
        @messages = res.code
        puts res.to_json
        render 'sessions/loginerror'
    end
end
