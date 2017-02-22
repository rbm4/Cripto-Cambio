class AddDataToLoterium < ActiveRecord::Migration
  def change
    add_column :loteria, :data, :string
  end
end
