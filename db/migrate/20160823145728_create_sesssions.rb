class CreateSesssions < ActiveRecord::Migration
  def change
    create_table :sesssions do |t|

      t.timestamps null: false
    end
  end
end
