require 'test_helper'

class HomeControllerTest < ActionDispatch::IntegrationTest

  setup do
    @registry = Registry.create!(name: 'rubygems.org', url: 'https://rubygems.org', ecosystem: 'rubygems', packages_count: 1000)
  end

  test 'renders index' do
    get root_path
    assert_response :success
    assert_template 'home/index'
  end
end