class AddCoinbasebtcToUsuarios < ActiveRecord::Migration
  def change
    add_column :usuarios, :coinbasebtc, :boolean
    add_column :usuarios, :coinbaseeth, :boolean
    add_column :usuarios, :ethereum, :string
  end
end
