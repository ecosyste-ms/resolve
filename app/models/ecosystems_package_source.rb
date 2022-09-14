require 'pub_grub/package'
require 'pub_grub/version_constraint'
require 'pub_grub/incompatibility'
require 'pub_grub/basic_package_source'
require 'pub_grub/rubygems'

class EcosystemsPackageSource < PubGrub::BasicPackageSource

  def initialize(root_deps, registry)
    # TODO parse root deps from file
    # TODO parse registry from file
    @registry = registry # TODO validate registry
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
    resp = Faraday.get("https://packages.ecosyste.ms/api/v1/registries/#{@registry}/packages/#{package_name}/versions?per_page=1000")
    json = JSON.parse(resp.body) # TODO handle errors
   
    @packages[package_name] = {}
    # TODO sort versions
    json.each do |version|
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
    p 'all_versions_for', package_name
    fetch_package(package_name) unless @packages[package_name].keys.any?
    @packages[package_name].keys
  end

  def root_dependencies
    @root_deps
  end

  def dependencies_for(package, version)
    p 'dependencies_for', package, version
    @packages[package][version]
  end

  def parse_dependency(package, dependency)
    p 'parse_dependency', package, dependency
    fetch_package(package) unless @packages.key?(package)
    return false unless @packages.key?(package)

    VersionParser.parse_constraint(package, dependency)
  end
end