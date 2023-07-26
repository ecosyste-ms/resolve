class AddVersionToJobs < ActiveRecord::Migration[7.0]
  def change
    add_column :jobs, :version, :string, default: '>= 0'
  end
end
