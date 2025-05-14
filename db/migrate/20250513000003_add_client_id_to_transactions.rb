class AddClientIdToTransactions < ActiveRecord::Migration[8.0]
  def change
    add_reference :transactions, :client, null: false, foreign_key: true, type: :uuid
  end
end
