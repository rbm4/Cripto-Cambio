class CreateConfirmados < ActiveRecord::Migration
  def change
    create_table :confirmados do |t|
      t.string :endereco
      t.string :produtos

      t.timestamps null: false
    end
  end
end
