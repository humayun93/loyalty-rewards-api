class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :user_id, null: false
      t.datetime :joining_date, null: true
      t.datetime :birth_date, null: true
      t.integer :points, default: 0, null: false

      t.references :client, null: false, foreign_key: true

      t.timestamps
    end

    # Add indexes to speed up queries
    add_index :users, [ :client_id, :user_id ], unique: true
  end
end
