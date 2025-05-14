class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users, id: :uuid do |t|
      t.string :user_id, null: false
      t.datetime :joining_date, null: true
      t.datetime :birth_date, null: true
      t.decimal :points, default: 0, null: false, precision: 10, scale: 2

      t.references :client, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end

    # Add indexes to speed up queries
    add_index :users, [ :client_id, :user_id ], unique: true
  end
end
