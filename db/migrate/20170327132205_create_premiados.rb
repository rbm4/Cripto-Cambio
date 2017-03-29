class CreatePremiados < ActiveRecord::Migration
  def change
    create_table :premiados do |t|
      t.string :endereco
      t.string :qtd_btc
      t.string :qtd_eth

      t.timestamps null: false
    end
  end
end
