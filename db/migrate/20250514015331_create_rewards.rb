class CreateRewards < ActiveRecord::Migration[8.0]
  def change
    create_table :rewards do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :client, null: false, foreign_key: true, type: :uuid
      t.string :reward_type, null: false
      t.datetime :issued_at, null: false
      t.datetime :expires_at
      t.string :status, null: false, default: 'active'
      t.string :description

      t.timestamps
    end

    add_index :rewards, [ :user_id, :reward_type, :status ]
  end
end
