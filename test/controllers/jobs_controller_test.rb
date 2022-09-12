require 'test_helper'

class JobsControllerTest < ActionDispatch::IntegrationTest

  setup do
    @registry = Registry.create!(name: 'rubygems.org', url: 'https://rubygems.org', ecosystem: 'rubygems', packages_count: 1000)
  end

  test 'starts processing a resolve' do
    get resolve_path(registry: 'rubygems.org', package_name: 'rails')
    assert_response :success
    assert_template 'jobs/resolve'
  end
end