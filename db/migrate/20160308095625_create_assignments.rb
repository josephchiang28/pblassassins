class CreateAssignments < ActiveRecord::Migration
  def change
    create_table :assignments do |t|
      t.integer  :game_id, null: false
      t.integer  :assassin_id, null: false
      t.integer  :target_id, null: false
      t.string   :status, null: false, default: 'inactive'
      t.datetime :time_activated
      t.datetime :time_deactivated

      t.timestamps null: false
    end

    add_index :assignments, :game_id
  end
end
