class AddEmailConfirmColumnToUsuarios < ActiveRecord::Migration
  def change
    add_column :usuarios, :email_confirmed, :boolean, :default => false
    add_column :usuarios, :confirm_token, :string
  end
end
