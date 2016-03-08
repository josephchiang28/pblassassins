class CreateCommittees < ActiveRecord::Migration
  def change
    create_table :committees do |t|
      t.string :name, null: false

      t.timestamps null: false
    end

    add_index :committees, :name, unique: true
  end
end
