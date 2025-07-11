class Registry < ApplicationRecord
  include EcosystemsApiClient

  def self.all_names
    Registry.all.map(&:name)
  end

  def self.sync_registries
    resp = ecosystems_connection.get('https://packages.ecosyste.ms/api/v1/registries')
    return unless resp.success?
    json = JSON.parse(resp.body)

    json.each do |registry|
      Registry.find_or_create_by(name: registry['name']) do |r|
        r.url = registry['url']
        r.ecosystem = registry['ecosystem']
        r.packages_count = registry['packages_count']
      end
    end
  end
end
