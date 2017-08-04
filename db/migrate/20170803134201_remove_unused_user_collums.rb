class RemoveUnusedUserCollums < ActiveRecord::Migration
  def change
    remove_column :usuarios, :pubkeybtc, :string
    remove_column :usuarios, :pubkeyltc, :string
    remove_column :usuarios, :pubkeydoge, :string
    remove_column :usuarios, :ethereum, :string
    remove_column :usuarios, :privkeybtc, :string
    remove_column :usuarios, :privkeyltc, :string
    remove_column :usuarios, :privkeydoge, :string
    add_column    :usuarios, :dogecoin, :string
  end
end
