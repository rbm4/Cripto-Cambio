class CreateUmi1s < ActiveRecord::Migration
  def change
    create_table :umi1s do |t|
      t.string :valor

      t.timestamps null: false
    end
  end
end
