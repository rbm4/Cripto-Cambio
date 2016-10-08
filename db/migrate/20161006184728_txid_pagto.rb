class TxidPagto < ActiveRecord::Migration
  def change
     add_column :pagamentos, :txid_blockchain, :string
  end
end
