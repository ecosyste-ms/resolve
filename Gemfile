source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.1.3"

gem "rails", "~> 7.0.3"
gem "sprockets-rails"
gem "pg", "~> 1.4"
gem "puma", "~> 6.0"
gem "jbuilder"
gem "tzinfo-data", platforms: %i[ mingw mswin x64_mingw jruby ]
gem "bootsnap", require: false
gem "sassc-rails"
gem "faraday"
gem "faraday-retry"
gem "faraday-gzip"
gem "faraday-follow_redirects"
gem "hiredis"
gem "redis", '<5', require: ["redis", "redis/connection/hiredis"]
gem "sidekiq", '<7'
gem "sidekiq-unique-jobs"
gem 'sidekiq-status'
gem "pghero"
gem "pg_query"
gem 'bootstrap'
gem "rack-attack"
gem "rack-attack-rate-limit", require: "rack/attack/rate-limit"
gem 'rack-cors'
gem 'rswag-api'
gem 'rswag-ui'
gem 'typhoeus'
gem 'pub_grub'
gem 'semantic_range'
gem 'semantic'
gem 'google-protobuf', '3.21.12'

group :development, :test do
  gem "debug", platforms: %i[ mri mingw x64_mingw ]
end

group :development do
  gem "web-console"
end

group :test do
  gem "shoulda"
  gem "webmock"
  gem "mocha"
  gem "rails-controller-testing"
end
