class CreateRegistries < ActiveRecord::Migration[7.0]
  def change
    create_table :registries do |t|
      t.string :name
      t.string :url
      t.string :ecosystem
      t.integer :packages_count

      t.timestamps
    end
  end
end
