class CreateTicketbtcs < ActiveRecord::Migration
  def change
    create_table :ticketbtcs do |t|
      t.string :proporcao
      t.string :usuario
      t.boolean :sorteavel

      t.timestamps null: false
    end
  end
end
