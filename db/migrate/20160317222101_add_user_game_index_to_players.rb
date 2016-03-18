class AddUserGameIndexToPlayers < ActiveRecord::Migration
  def change
    add_index :players, [:user_id, :game_id], unique: true
  end
end
