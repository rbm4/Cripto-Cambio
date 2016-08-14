class CreateTemp3s < ActiveRecord::Migration
  def change
    create_table :temp3s do |t|
      t.integer :valor

      t.timestamps null: false
    end
  end
end
