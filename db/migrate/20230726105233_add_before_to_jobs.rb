class AddBeforeToJobs < ActiveRecord::Migration[7.0]
  def change
    add_column :jobs, :before, :datetime
  end
end
