class AddIndexToApiTokens < ActiveRecord::Migration[5.0]
  def change
    add_index :api_tokens, [:token]
  end
end
