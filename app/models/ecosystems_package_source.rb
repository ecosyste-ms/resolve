require 'pub_grub/package'
require 'pub_grub/version_constraint'
require 'pub_grub/incompatibility'
require 'pub_grub/basic_package_source'
require 'pub_grub/rubygems'

class EcosystemsPackageSource < PubGrub::BasicPackageSource
  include EcosystemsApiClient

  def initialize(root_deps, registry, before = nil)
    # TODO parse root deps from file
    # TODO parse registry from file
    @registry = registry # TODO validate registry
    @before = before
    @root_deps = root_deps 

    @packages = {}

    root_deps.each do |package_name, constraint|
      fetch_package(package_name)
    end
    
    super()
  end

  def packages
    @packages
  end

  def fetch_package(package_name)
    before_str = if @before.present?
      @before.respond_to?(:iso8601) ? @before.iso8601 : @before.to_s
    end

    url = "https://packages.ecosyste.ms/api/v1/registries/#{@registry}/packages/#{package_name}/versions?per_page=1000"
    url += "&before=#{before_str}" if before_str.present?
    resp = ecosystems_connection.get(url)
    json = JSON.parse(resp.body) # TODO handle errors
   
    @packages[package_name] = {}

    before_time = if @before.present?
      if @before.is_a?(Time) || @before.is_a?(DateTime)
        @before
      else
        Time.parse(@before.to_s) rescue nil
      end
    end

    # TODO sort versions
    json.each do |version|
      if before_time && version['published_at'].present?
        pub_time = Time.parse(version['published_at']) rescue nil
        next if pub_time && pub_time > before_time
      end

      # next if version['metadata']['platform'].present?
      @packages[package_name][version['number']] = {}
      version['dependencies'].each do |dependency|
        next unless dependency['kind'] == 'runtime'
        @packages[dependency['package_name']] ||= {}
        @packages[package_name][version['number']][dependency['package_name']] = *dependency['requirements'].split(', ')
      end
    end
  end

  def all_versions_for(package_name)
    fetch_package(package_name) unless @packages[package_name].keys.any?
    @packages[package_name].keys
  end

  def root_dependencies
    @root_deps
  end

  def dependencies_for(package, version)
    @packages[package][version]
  end

  def parse_dependency(package, dependency)
    fetch_package(package) unless @packages.key?(package)
    return false unless @packages.key?(package)

    VersionParser.parse_constraint(package, dependency)
  end
end
