class CreateApiErrors < ActiveRecord::Migration[5.1][5.0]
  def change
    create_table :api_errors do |t|
      t.integer :code
      t.string :description
      t.integer :status_code

      t.timestamps
    end
    ApiError.make_standard_errors rescue nil
  end
end
