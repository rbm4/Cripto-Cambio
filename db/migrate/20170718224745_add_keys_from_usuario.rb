class AddKeysFromUsuario < ActiveRecord::Migration
  def change
    add_column :usuarios, :pubkeybtc, :string
    add_column :usuarios, :privkeybtc, :string
    add_column :usuarios, :pubkeyltc, :string
    add_column :usuarios, :pubkeydoge, :string
    add_column :usuarios, :privkeyltc, :string
    add_column :usuarios, :privkeydoge, :string
  end
end
