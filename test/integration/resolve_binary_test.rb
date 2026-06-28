require "test_helper"

# These tests run the real resolve binary against real registries. They are
# skipped unless RESOLVE_BINARY points at an executable. Set it to a local
# build of resolve-cli to verify parser changes before tagging a release.
#
#   RESOLVE_BINARY=~/code/ecosystems/resolve-cli/resolve bin/rails test test/integration
#
# Network access and the relevant package manager (composer for packagist)
# must be available.
class ResolveBinaryTest < ActiveSupport::TestCase
  setup do
    @binary = ENV["RESOLVE_BINARY"]
    skip "RESOLVE_BINARY not set" if @binary.blank?
    skip "RESOLVE_BINARY not executable: #{@binary}" unless File.executable?(@binary)

    Registry.find_or_create_by!(name: "packagist.org") do |r|
      r.url = "https://packagist.org"
      r.ecosystem = "packagist"
      r.packages_count = 0
    end
  end

  # https://github.com/ecosyste-ms/resolve/issues/842
  #
  # composer show --tree falls back to ASCII tree characters when stdout is
  # not a TTY. The old parser missed those markers, so package names came back
  # as "|--guzzlehttp/promises" with the constraint string ("^2.5") in place of
  # the resolved version, and platform requirements (php, ext-*) leaked through.
  test "packagist results have clean names and resolved versions" do
    skip "composer not installed" unless system("composer", "--version", out: File::NULL, err: File::NULL)

    job = Job.create!(registry: "packagist.org", package_name: "google/auth", status: "pending")
    job.resolve

    assert_equal "complete", job.status, "resolve failed: #{job.results.inspect}"
    results = job.results
    assert_kind_of Hash, results
    assert results.any?, "expected at least one resolved dependency"

    results.each do |name, version|
      refute_match(/[`|]--/, name, "tree-drawing prefix leaked into package name: #{name.inspect}")
      refute_match(/\A(php|hhvm)\z/, name, "platform requirement leaked into results: #{name.inspect}")
      refute_match(/\A(ext|lib|composer)-/, name, "platform requirement leaked into results: #{name.inspect}")
      refute_match(/[\^~*|<>=\s]/, version, "expected resolved version for #{name}, got constraint #{version.inspect}")
    end

    assert results.key?("guzzlehttp/promises"), "expected transitive dep guzzlehttp/promises in results"
    assert_match(/\A\d+\.\d+/, results["guzzlehttp/promises"])
  end
end
