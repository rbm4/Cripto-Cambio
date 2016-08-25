class ProdutosController < ApplicationController
    #convert BRL to BTC https://blockchain.info/tobtc?currency=BRL&value=VALOR DO PRODUTO
    require 'net/http'
    before_action :require_user, only: [:show, :solicitar_pagamento]
    
    def show
        @invoice_id =  9001
        @all = Produto.all
    #    BlockIo.get_new_address
    #    puts(@endereco.address)
    #    puts(@endereco.label)
    end
    
    def solicitar_pagamento
        Faraday.post 'https://block.io/api/v2/get_new_address/?ddcf-3881-8c4e-7590'    
      # uri = URI.parse('/api/v2/get_new_address/')
      # http = Net::HTTP.new(uri.host, uri.port)
      # request = Net::HTTP::Post.new(uri.request_uri)
      # request.set_form_data({"api_key" => "ddcf-3881-8c4e-7590"})
      # response = http.request(request)
      # render :json => response.body
        #callback_url = 'https://bmarket-rbm4.c9users.io/payment/' + String(params[:invoice_id])
        #resp = Blockchain::V2.receive('xpub6CBYyFSnxZqqmW2q2oycEKhYDEFXf5bh3TB4DkJdRnLKA5NkerJMTfUq1nZnkvQHj5RgUKAh2goaYNJ2pwspvieemDHMsj1Dum3ab5PZPwq', callback_url, 'keydseste')
        #db.execute %{
        #    UPDATE pagamentos
        #    SET address = ?
        #    WHERE invoice_id = ?    }, resp.address, invoice_id
        #    JSON.dump({ input_address: resp.address })
        #@resp = Blockchain::V2::receive('xpub6CBYyFSnxZqqmW2q2oycEKhYDEFXf5bh3TB4DkJdRnLKA5NkerJMTfUq1nZnkvQHj5RgUKAh2goaYNJ2pwspvieemDHMsj1Dum3ab5PZPwq','https://bmarket-rbm4.c9users.io/blockcall','') #xpub / callback URL / apikey
    end
    def receber_pagamento
        address = params[:address]
        secret = params[:secret]
        confirmations = params[:confirmations].to_i
        tx_hash = params[:transaction_hash]
        value = params[:value].to_f / 100000000
        handle = db()
        my_address = handle.execute(%{
            SELECT address
            FROM pagamentos
            WHERE invoice_id = ?
            }, invoice_id)[0][0]
        return 400, 'Incorrect Receiving Address' unless my_address == address
        return 400, 'Invalid Secret' unless secret == Settings.secret
        if confirmations >= 4
            handle.execute %{
                INSERT INTO invoice_payments 
                (invoice_id, transaction_hash, value)
                VALUES (?, ?, ?)
                }, invoice_id, tx_hash, value
                handle.execute %{
        DELETE FROM pending_invoice_payments WHERE invoice_id = ?
        }, invoice_id
        return 200, '*ok*'
        else
            handle.execute %{
                INSERT INTO pending_invoice_payments
                (invoice_id, transaction_hash, value)
                VALUES (?, ?, ?)
                }, invoice_id, tx_hash, value
                return 200, 'Waiting for confirmations'
        end    # shouldn't ever reach this
        return 500, 'something went wrong'
    end
end
