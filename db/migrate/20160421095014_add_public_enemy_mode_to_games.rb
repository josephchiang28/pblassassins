class AddPublicEnemyModeToGames < ActiveRecord::Migration
  def change
    add_column :games, :public_enemy_mode, :boolean, null: false, default: false
  end
end
