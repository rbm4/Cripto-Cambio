class CreateTransacaos < ActiveRecord::Migration
  def change
    create_table :transacaos do |t|
      t.string :user
      t.string :tipo
      t.string :moeda
      t.string :inout
      t.string :fee
      t.boolean :paid
      t.string :txid

      t.timestamps null: false
    end
  end
end
