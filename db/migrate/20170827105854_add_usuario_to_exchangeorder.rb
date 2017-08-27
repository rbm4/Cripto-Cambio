class AddUsuarioToExchangeorder < ActiveRecord::Migration
  def change
    add_column :exchangeorders, :usuario_id, :string
  end
end
