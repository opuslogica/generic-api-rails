class CreateApiTokens < ActiveRecord::Migration[5.0]
  def change
    create_table :api_tokens do |t|
      t.references :person, index: true
      t.references :credential, polymorphic: true
      t.string     :token, limit: 64
      t.timestamps
    end rescue nil
    add_index :api_tokens, [:credential_id, :credential_type] rescue nil
    add_index :api_tokens, [:token] rescue nil
  end
end
