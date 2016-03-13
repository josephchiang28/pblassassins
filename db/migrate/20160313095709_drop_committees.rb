class DropCommittees < ActiveRecord::Migration
  def change
    drop_table :committees

    remove_column :players, :committee_id, :integer
    add_column :players, :committee, :string, null: false
  end
end
