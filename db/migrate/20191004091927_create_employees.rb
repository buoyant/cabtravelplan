class CreateEmployees < ActiveRecord::Migration[6.0]
  def change
    create_table :employees do |t|
      t.string :empid
      t.string :empname
      t.string :address
      t.string :lat
      t.string :lon
      t.float :distance

      t.timestamps
    end
  end
end
