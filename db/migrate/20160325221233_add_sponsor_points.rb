class AddSponsorPoints < ActiveRecord::Migration
  def change
    add_column :players, :sponsor_points, :integer, null: false, default: 0
  end
end
