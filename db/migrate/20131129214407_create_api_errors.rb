class CreateApiErrors < ActiveRecord::Migration
  def change
    create_table :api_errors do |t|
      t.integer :code
      t.string :description
      t.integer :status_code

      t.timestamps
    end

    ApiError.make_standard_errors
  end
end
