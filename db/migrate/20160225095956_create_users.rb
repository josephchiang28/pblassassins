class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :name
      t.string :provider
      t.string :uid

      t.timestamps null: false
    end

    add_index :users, :email, unique: true
    add_index :users, [:provider, :uid], unique: true
  end
end
