class AddSaldoToUsers < ActiveRecord::Migration
  def change
    add_column :usuarios, :saldo, :string
  end
end
