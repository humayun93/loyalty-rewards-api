class CreateTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :transactions, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.string :currency, null: false, default: 'USD'
      t.boolean :foreign, null: false, default: false
      t.decimal :points_earned, precision: 10, scale: 2, null: false, default: 0
      t.timestamps
    end
  end
end
