class CreateExchangeorders < ActiveRecord::Migration
  def change
    create_table :exchangeorders do |t|
      t.string :par
      t.string :tipo
      t.string :amount
      t.string :user
      t.boolean :has_execution
      t.string :price
      t.string :status

      t.timestamps null: false
    end
  end
end
