require 'test_helper'

class ApiV1JobsControllerTest < ActionDispatch::IntegrationTest

  setup do
    @registry = Registry.create!(name: 'rubygems.org', url: 'https://rubygems.org', ecosystem: 'rubygems', packages_count: 1000)
    p @registry
  end

  test 'submit a job' do
    p @registry
    p Registry.all.pluck(:name)
    post api_v1_jobs_path(registry: @registry.name, package_name: 'rails')
    assert_response :redirect
    assert_match /\/api\/v1\/jobs\//, @response.location
  end

  test 'submit an invalid job' do
    post api_v1_jobs_path
    assert_response :bad_request

    actual_response = JSON.parse(@response.body)

    assert_equal actual_response["title"], "Bad Request"
    assert_equal actual_response["details"], ["Package name can't be blank", "Registry can't be blank", "Registry is not included in the list"]
  end

  test 'check on a job' do
    p @registry
    p Registry.all.pluck(:name)
    @job = Job.create!(registry: @registry.name, package_name: 'rails')
    
    @job.expects(:check_status)
    Job.expects(:find).with(@job.id).returns(@job)

    get api_v1_job_path(id: @job.id)
    assert_response :success
    assert_template 'jobs/show', file: 'jobs/show.json.jbuilder'
    
    actual_response = JSON.parse(@response.body)

    assert_equal actual_response["registry"], @job.registry
    assert_equal actual_response["package_name"], @job.package_name
  end
end