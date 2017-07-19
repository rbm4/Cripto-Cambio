class CreateStorage < ActiveRecord::Migration
  def change
    create_table :storages do |t|
      t.string :tipo
      t.string :endereco
      t.string :privkey
      t.string :pubkey
      t.string :role
    end
  end
end
