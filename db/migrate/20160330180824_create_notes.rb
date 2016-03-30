class CreateNotes < ActiveRecord::Migration
  def change
    create_table :notes do |t|
      t.integer :game_id, null: false
      t.text :content, null: false

      t.timestamps null: false
    end
  end
end
