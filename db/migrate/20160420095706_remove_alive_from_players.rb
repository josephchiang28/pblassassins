class RemoveAliveFromPlayers < ActiveRecord::Migration
  def change
    remove_column :players, :alive, :boolean
  end
end
