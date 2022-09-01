require 'test_helper'

class HomeControllerTest < ActionDispatch::IntegrationTest
  test 'renders index' do
    Registry.create(name: 'rubygems.org', url: 'https://rubygems.org', ecosystem: 'rubygems', packages_count: 1000)
    get root_path
    assert_response :success
    assert_template 'home/index'
  end
end