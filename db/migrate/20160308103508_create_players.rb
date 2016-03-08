class CreatePlayers < ActiveRecord::Migration
  def change
    create_table :players do |t|
      t.integer :user_id, null: false
      t.integer :game_id, null: false
      t.integer :committee_id, null: false
      t.string  :role, null: false
      t.boolean :alive, null: false
      t.string  :killcode
      t.integer :points, null: false, default: 0

      t.timestamps null: false
    end

    add_index :players, :user_id
    add_index :players, :game_id
  end
end
