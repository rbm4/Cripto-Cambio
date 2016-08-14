class CreateTemp2s < ActiveRecord::Migration
  def change
    create_table :temp2s do |t|
      t.string :valor

      t.timestamps null: false
    end
  end
end
