class CreateMbtcs < ActiveRecord::Migration
  def change
    create_table :mbtcs do |t|

      t.timestamps null: false
    end
  end
end
