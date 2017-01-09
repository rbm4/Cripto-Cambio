class AddWalletsToUsuarios < ActiveRecord::Migration
  def change
    add_column :usuarios, :bitcoin, :string
    add_column :usuarios, :litecoin, :string
  end
end
