class DeleteUserFromExchangeorder < ActiveRecord::Migration
  def change
    remove_column :exchangeorders, :user
  end
end
