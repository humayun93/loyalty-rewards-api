class CreateClients < ActiveRecord::Migration[8.0]
  def change
    create_table :clients, id: :uuid do |t|
      t.string :name
      t.string :subdomain
      t.string :api_token

      t.timestamps
    end

    add_index :clients, :api_token, unique: true
  end
end
