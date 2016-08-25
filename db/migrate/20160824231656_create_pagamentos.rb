class CreatePagamentos < ActiveRecord::Migration
  def change
    create_table :pagamentos do |t|
      t.string :invoice_id
      t.string :address
      t.string :endereco_real
      t.string :price_in_brl
      t.string :price_in_btc
      t.string :product_url
      
      t.timestamps null: false
    end
  end
end
