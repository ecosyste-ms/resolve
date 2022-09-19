require 'test_helper'

class EcosystemsPackageSourceTest < ActiveSupport::TestCase
  def test_resolving_dependencies
    stub_request(:get, "https://packages.ecosyste.ms/api/v1/registries/rubygems.org/packages/redis-client/versions?per_page=1000")
      .to_return({ status: 200, body: file_fixture('redis-client-versions') })
    stub_request(:get, "https://packages.ecosyste.ms/api/v1/registries/rubygems.org/packages/connection_pool/versions?per_page=1000")
      .to_return({ status: 200, body: file_fixture('connection_pool-versions') })
    
    source = EcosystemsPackageSource.new({ 'redis-client' => '>= 0.6.0' }, 'rubygems.org')

    solver = PubGrub::VersionSolver.new(source: source)
    result = solver.solve
    assert_equal result['redis-client'], '0.7.1'
    assert_equal result['connection_pool'], '2.2.5'
  end

  # def test_resolving_npm_dependencies
  #   source = EcosystemsPackageSource.new({ 'express' => '>= 0' }, 'npmjs.org')

  #   solver = PubGrub::VersionSolver.new(source: source)
  #   result = solver.solve
  #   assert_equal result['redis-client'], '0.7.1'
  #   assert_equal result['connection_pool'], '2.2.5'
  # end
end