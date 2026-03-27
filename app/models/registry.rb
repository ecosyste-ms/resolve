class Registry < ApplicationRecord
  include EcosystemsApiClient

  SUPPORTED_ECOSYSTEMS = %w[
    npm rubygems cargo pypi go maven packagist pub hex nuget
    swift clojars hackage conda deno helm conan cocoapods
  ].freeze

  scope :supported, -> { where(ecosystem: SUPPORTED_ECOSYSTEMS) }

  def self.all_names
    supported.pluck(:name)
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
