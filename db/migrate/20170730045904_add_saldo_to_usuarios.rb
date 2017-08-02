class AddSaldoToUsuarios < ActiveRecord::Migration
  def change
    add_column :usuarios, :saldo_encrypted, :string
  end
end
