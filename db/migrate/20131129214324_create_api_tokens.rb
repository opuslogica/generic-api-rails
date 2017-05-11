class CreateApiTokens < ActiveRecord::Migration[5.0]
  def change
    create_table :api_tokens do |t|
      t.references :person, index: true
      t.string     :credential_type, limit: 64
      t.integer    :credential_id
      t.string     :token, limit: 64
      t.timestamps
    end
    add_index :api_tokens, [:credential_id, :credential_type]
  end
end
