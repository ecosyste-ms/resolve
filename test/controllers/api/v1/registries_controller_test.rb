require 'test_helper'

class ApiV1RegistriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @rubygems = Registry.create!(name: 'rubygems.org', url: 'https://rubygems.org', ecosystem: 'rubygems', packages_count: 1000)
    @npmjs = Registry.create!(name: 'npmjs.org', url: 'https://www.npmjs.com', ecosystem: 'npm', packages_count: 2000)
  end

  test 'list registries' do
    get api_v1_registries_path
    assert_response :success

    registries = JSON.parse(@response.body)

    assert_equal 2, registries.length
    assert_equal 'npmjs.org', registries[0]['name']
    assert_equal 'rubygems.org', registries[1]['name']
  end

  test 'excludes unsupported ecosystems' do
    Registry.create!(name: 'hub.docker.com', url: 'https://hub.docker.com', ecosystem: 'docker', packages_count: 500)

    get api_v1_registries_path
    registries = JSON.parse(@response.body)

    assert_equal 2, registries.length
    assert_nil registries.find { |r| r['name'] == 'hub.docker.com' }
  end

  test 'registries include expected fields' do
    get api_v1_registries_path
    registry = JSON.parse(@response.body).find { |r| r['name'] == 'rubygems.org' }

    assert_equal 'https://rubygems.org', registry['url']
    assert_equal 'rubygems', registry['ecosystem']
    assert_equal 1000, registry['packages_count']
  end
end
