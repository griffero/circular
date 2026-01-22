source "https://rubygems.org"

ruby "~> 3.2"

# Rails 8
gem "rails", "~> 8.0.4"

# Database
gem "pg", "~> 1.5"

# Web server
gem "puma", ">= 6.0"

# Authentication
gem "bcrypt", "~> 3.1"

# Authorization
gem "pundit", "~> 2.3"

# JSON serialization
gem "blueprinter", "~> 1.0"
gem "oj", "~> 3.16"  # Fast JSON parsing

# Background jobs
gem "sidekiq", "~> 7.2"
gem "sidekiq-scheduler", "~> 5.0"

# Redis
gem "redis", "~> 5.0"
gem "hiredis-client", "~> 0.22"

# ActionCable with Redis
gem "kredis", "~> 1.7"

# GraphQL API
gem "graphql", "~> 2.5"

# File uploads
gem "aws-sdk-s3", "~> 1.143"
gem "image_processing", "~> 1.12"

# Pagination
gem "pagy", "~> 6.4"

# Search
gem "pg_search", "~> 2.3"

# Rate limiting
gem "rack-attack", "~> 6.7"

# CORS
gem "rack-cors", "~> 2.0"

# Stripe billing
gem "stripe", "~> 10.8"

# UUID generation
gem "uuid7", "~> 0.2"

# Environment variables
gem "dotenv-rails", "~> 3.1"

# Time zones
gem "tzinfo-data", platforms: %i[windows jruby]

# Performance
gem "bootsnap", require: false

# Deployment
gem "kamal", require: false
gem "thruster", require: false

group :development, :test do
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  gem "brakeman", require: false
  gem "rubocop", "~> 1.60", require: false
  gem "rubocop-rails", "~> 2.23", require: false
  gem "rubocop-rspec", "~> 2.26", require: false
  gem "rubocop-performance", "~> 1.20", require: false
  
  # Testing
  gem "rspec-rails", "~> 6.1"
  gem "factory_bot_rails", "~> 6.4"
  gem "faker", "~> 3.2"
  gem "shoulda-matchers", "~> 6.1"
  gem "database_cleaner-active_record", "~> 2.1"
end

group :development do
  gem "letter_opener", "~> 1.9"
  gem "graphiql-rails", "~> 1.10"
end

group :test do
  gem "webmock", "~> 3.19"
  gem "vcr", "~> 6.2"
  gem "simplecov", require: false
  gem "pundit-matchers", "~> 3.1"
end
