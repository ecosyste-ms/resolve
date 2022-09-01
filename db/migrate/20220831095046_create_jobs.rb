class CreateJobs < ActiveRecord::Migration[7.0]
  def change
    enable_extension 'pgcrypto' unless extension_enabled?('pgcrypto')

    create_table :jobs, id: :uuid, default: 'gen_random_uuid()' do |t|
      t.string :sidekiq_id
      t.string :status
      t.string :url
      t.string :registry
      t.string :package_name
      t.string :ip
      t.string :sha256
      t.json :results, default: {}

      t.timestamps
    end

    add_index :jobs, :status
  end
end
