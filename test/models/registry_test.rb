require "test_helper"

class RegistryTest < ActiveSupport::TestCase
  setup do
    Registry.create!(name: 'rubygems.org', url: 'https://rubygems.org', ecosystem: 'rubygems', packages_count: 1000)
    Registry.create!(name: 'npmjs.org', url: 'https://www.npmjs.com', ecosystem: 'npm', packages_count: 2000)
    Registry.create!(name: 'hub.docker.com', url: 'https://hub.docker.com', ecosystem: 'docker', packages_count: 500)
  end

  test "supported scope filters to supported ecosystems" do
    supported = Registry.supported
    assert_equal 2, supported.count
    assert_includes supported.map(&:name), 'rubygems.org'
    assert_includes supported.map(&:name), 'npmjs.org'
    assert_not_includes supported.map(&:name), 'hub.docker.com'
  end

  test "all_names returns only supported registry names" do
    names = Registry.all_names
    assert_includes names, 'rubygems.org'
    assert_includes names, 'npmjs.org'
    assert_not_includes names, 'hub.docker.com'
  end
end
