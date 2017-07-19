class RemoveCoinbaseFromUsuario < ActiveRecord::Migration
  def change
    remove_column :usuarios, :coinbasebtc, :boolean
    remove_column :usuarios, :coinbaseeth, :boolean
  end
end
