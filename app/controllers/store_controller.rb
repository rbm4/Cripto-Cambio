class StoreController < ApplicationController
    
    def store
        
       # bugfix = Produto.new(:foto => "Teste2", :tipo => "hash", :preco=>"30 BRL", :detalhes => " Detalhes do produto", :nome => "Hash standard")
        #bugfix.save
        @products = Shoppe::Product.root.ordered.includes(:product_categories, :variants)
        @products = @products.group_by(&:product_category)
    end

    def show
        puts 'a'
        puts params[:permalink]
        puts 'b'
        @product = Shoppe::Product.root.find_by_permalink(params[:permalink])
    end
    def buy
        # @product = Produto.find_by(params[:id])
        puts params[:permalink]
        puts 'AQUI EXECUTA A FUNÇÃO DE SALVAR ITEM NA ONDA'
         @product = Shoppe::Product.root.find_by_permalink!(params[:permalink])
         current_order.order_items.add_item(@product, 1)
         @messages = "Product has been added successfuly!"
         redirect_to product_path(@product.permalink)
    end
end
