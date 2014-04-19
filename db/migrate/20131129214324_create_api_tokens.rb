class CreateApiTokens < ActiveRecord::Migration
  def change
    create_table :api_tokens do |t|
      t.references :person, index: true
      t.references :credential, index: true, polymorphic: true
      
      t.string :token

      t.timestamps
    end
  end
end
