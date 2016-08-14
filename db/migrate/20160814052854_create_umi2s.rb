class CreateUmi2s < ActiveRecord::Migration
  def change
    create_table :umi2s do |t|
      t.integer :valor

      t.timestamps null: false
    end
  end
end
