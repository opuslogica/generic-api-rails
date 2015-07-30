class AddIndexToApiTokens < ActiveRecord::Migration
  def change
    add_index :api_tokens, [:token]
  end
end
