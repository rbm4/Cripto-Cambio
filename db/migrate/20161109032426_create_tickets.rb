class CreateTickets < ActiveRecord::Migration
  def change
    create_table :tickets do |t|
      t.string :user
      t.string :title
      t.string :conteudo
      t.string :email

      t.timestamps null: false
    end
  end
end
