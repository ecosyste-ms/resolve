require 'test_helper'

class EcosystemsApiClientTest < ActiveSupport::TestCase
  class TestModel < ApplicationRecord
    include EcosystemsApiClient
  end

  def test_user_agent_header_is_set
    stub_request(:get, "https://packages.ecosyste.ms/api/v1/test")
      .with(headers: { 'User-Agent' => 'resolve.ecosyste.ms' })
      .to_return(status: 200, body: '{"test": "success"}')

    response = TestModel.ecosystems_connection.get("https://packages.ecosyste.ms/api/v1/test")
    
    assert_equal 200, response.status
    assert_equal '{"test": "success"}', response.body
  end

  def test_request_without_user_agent_should_not_be_made
    stub_request(:get, "https://packages.ecosyste.ms/api/v1/test")
      .with(headers: { 'User-Agent' => 'resolve.ecosyste.ms' })
      .to_return(status: 200, body: '{"test": "success"}')

    # This should raise an error because WebMock expects the User-Agent header
    assert_raises(WebMock::NetConnectNotAllowedError) do
      Faraday.get("https://packages.ecosyste.ms/api/v1/test")
    end
  end
end