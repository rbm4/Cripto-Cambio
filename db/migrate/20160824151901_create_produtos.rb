class CreateProdutos < ActiveRecord::Migration
  def change
    create_table :produtos do |t|
      t.string :foto
      t.string :tipo
      t.string :preco
      t.string :detalhes
      t.string :nome

      t.timestamps null: false
    end
  end
end
