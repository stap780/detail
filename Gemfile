source 'https://rubygems.org'
git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end
# # ruby '2.4.4'
# gem 'rails', '~> 5.0.7', '>= 5.0.7.2'

ruby "3.2.0"
gem "rails", "~> 7.1.1"

# gem 'puma', '~> 3.0'
gem "puma", ">= 6.0"

# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem "sprockets-rails"

# Bundle and transpile JavaScript [https://github.com/rails/jsbundling-rails]
gem "jsbundling-rails"

# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"

# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"

gem "cssbundling-rails", "~> 1.4"

# Use Redis adapter to run Action Cable in production
gem "redis", ">= 4.0.1"

gem "bootsnap", require: false
gem "gem-release"

gem 'jbuilder', '~> 2.5'
gem 'devise'
gem 'high_voltage'
gem 'simple_form'
gem 'rest-client'
gem 'nokogiri'
gem 'cocoon'
gem 'will_paginate'
gem 'ransack'
gem 'roo'
gem 'roo-xls'
gem 'whenever', require: false
gem 'mechanize'
gem 'pg'

gem 'daemons'
gem 'bcrypt_pbkdf', '< 2.0', :require => false
gem 'ed25519', '~> 1.2', '>= 1.2.4'

gem "sidekiq"
gem "faraday"
gem 'net-ftp'
gem 'will_paginate-bootstrap-style'

group :development, :test do
  gem 'byebug', platform: :mri
end
group :development do
  gem 'web-console', '>= 3.3.0'
  gem 'capistrano', require: false
  gem 'capistrano-bundler', require: false
  gem 'capistrano-rails', require: false
  gem 'capistrano-rails-console', require: false
  gem 'capistrano-rvm', require: false
  gem "capistrano3-puma", require: false
  gem 'hub', :require=>nil
  gem 'rails_layout'
end


