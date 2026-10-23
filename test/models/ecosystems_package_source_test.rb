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

  def test_resolving_dependencies_in_the_past
    stub_request(:get, "https://packages.ecosyste.ms/api/v1/registries/rubygems.org/packages/redis-client/versions?per_page=1000&before=2022-08-16T12:00:00Z")
      .to_return({ status: 200, body: file_fixture('redis-client-versions') })
    stub_request(:get, "https://packages.ecosyste.ms/api/v1/registries/rubygems.org/packages/connection_pool/versions?per_page=1000&before=2022-08-16T12:00:00Z")
      .to_return({ status: 200, body: file_fixture('connection_pool-versions') })
    
    # Releases 0.7.1, 0.7.0, 0.6.2, 0.6.1 were all published after 2022-08-16T12:00:00Z.
    # The latest available release satisfying >= 0.6.0 at this cutoff was 0.6.0 (published 2022-08-16T09:22:15Z).
    source = EcosystemsPackageSource.new({ 'redis-client' => '>= 0.6.0' }, 'rubygems.org', '2022-08-16T12:00:00Z')

    solver = PubGrub::VersionSolver.new(source: source)
    result = solver.solve
    assert_equal '0.6.0', result['redis-client']
    assert_equal '2.2.5', result['connection_pool']
  end

  # def test_resolving_npm_dependencies
  #   source = EcosystemsPackageSource.new({ 'express' => '>= 0' }, 'npmjs.org')

  #   solver = PubGrub::VersionSolver.new(source: source)
  #   result = solver.solve
  #   assert_equal result['redis-client'], '0.7.1'
  #   assert_equal result['connection_pool'], '2.2.5'
  # end
end
