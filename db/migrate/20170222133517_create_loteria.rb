class CreateLoteria < ActiveRecord::Migration
  def change
    create_table :loteria do |t|

      t.timestamps null: false
    end
  end
end
