require 'test_helper'

class JobsControllerTest < ActionDispatch::IntegrationTest
  test 'starts processing a resolve' do
    get resolve_path(registry: 'rubygems.org', package_name: 'rails')
    assert_response :success
    assert_template 'jobs/resolve'
  end
end