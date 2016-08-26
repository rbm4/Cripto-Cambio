class CreatePagamentos < ActiveRecord::Migration
  def change
    create_table :pagamentos do |t|
      t.string :user_id
      t.string :address
      t.string :status
      t.string :label
      t.string :usuario
      t.string :endereco
      t.string :volume
      t.string :network

      t.timestamps null: false
    end
  end
end
