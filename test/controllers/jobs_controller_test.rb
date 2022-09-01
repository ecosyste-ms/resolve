require 'test_helper'

class JobsControllerTest < ActionDispatch::IntegrationTest
  test 'starts processing a resolve' do
    Registry.create(name: 'rubygems.org', url: 'https://rubygems.org', ecosystem: 'rubygems', packages_count: 1000)
    get resolve_path(registry: 'rubygems.org', package_name: 'rails')
    assert_response :success
    assert_template 'jobs/resolve'
  end
end