source 'https://rubygems.org'

# Framework
gem 'rails', '~> 4.2'
gem 'rails-i18n'
gem 'responders'
gem 'rails-observers'
gem "globalize", '< 5.1'

# Data
gem 'mysql2'
gem 'redis-rails'
gem 'aasm'
gem 'enumerize'
gem 'acts-as-taggable-on'
gem 'kaminari'
gem 'paranoid2'
gem 'paper_trail'
gem 'marginalia'                  # show where queries are coming from in the logs
gem 'active_hash'                 # YAML-sourced data

# Security
gem 'rotp'
gem 'bcrypt-ruby'

# Background Processing
gem 'amqp'
gem 'bunny'
gem 'pusher'
gem 'eventmachine'
gem 'em-websocket'
gem 'daemons-rails'

# API
gem 'grape', '~> 0.7.0'
gem 'grape-entity'
gem 'grape-swagger'
gem 'json'
gem 'jbuilder'
gem 'rest-client'

# Authentication
gem 'doorkeeper'
gem 'omniauth'
gem 'omniauth-identity'
gem 'omniauth-weibo-oauth2'

# Authorization
gem 'cancancan'

# ENV Vars
gem 'figaro', github: 'laserlemon/figaro', branch: :master

# Frontend
gem 'puma'

gem 'rack-attack'
gem 'rack-cors', require: 'rack/cors'

gem 'datagrid', '>= 1.5.7'
gem 'http_accept_language'
gem 'country_select', '~> 2.1.0'
gem 'gon', '~> 5.2.0'
gem 'simple_form', '~> 3.1.1'
gem 'slim-rails', '>= 3.1.3'
gem 'sass-rails', '>= 5.0.6'
gem 'coffee-rails', '>= 4.2.2'
gem 'uglifier', '>= 2.7.2'
gem "jquery-rails", ">= 3.1.4"
gem "angularjs-rails"
gem 'bootstrap-sass', '~> 3.2.0.2'
gem 'bootstrap-wysihtml5-rails', '>= 0.3.1.24'
gem 'font-awesome-sass'
gem 'bourbon'
gem 'momentjs-rails', '>= 2.17.1'
gem 'eco'
gem 'browser', '~> 0.8.0'
gem 'simple_captcha2', require: 'simple_captcha'
gem 'easy_table'

## MISC
gem 'liability-proof', github: 'peatio/liability-proof', branch: :master  # proves we really hold the bitcoins/money we claim to
gem 'phonelib'                  # validates phone numbers
gem 'twilio-ruby'
gem 'unread', github: 'peatio/unread'
gem 'carrierwave', '~> 0.10.0'  # storing documents online
gem 'recursive-open-struct'
gem 'awesome_print'             # fancy object output for console
gem 'bootsnap'                  # faster booting
gem 'bundleup', require: false  # easy gem upgrading
gem 'colorize'                  # colors for console output "test".yellow
gem 'fast_blank'                # C-implementation of .blank?
gem 'hirb'                      # model viewing in console
gem 'ensurance'                 # Model.ensure(thing)
gem 'whenever'                  # cron-like scheduling
gem 'rbtree'                    # RedBlackTree sorted hash

group :development, :test do
  gem 'factory_bot_rails'
  gem 'faker'
  # gem 'mina'
  # gem 'mina-slack', github: 'peatio/mina-slack'
  gem 'meta_request'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'pry-rails'
  gem 'quiet_assets'
  gem 'mails_viewer'
  gem 'timecop'
  gem 'spring'
  gem 'spring-commands-rspec'
  # gem 'dotenv-rails'
  # gem 'byebug'
end

group :test do
  gem 'database_cleaner'
  # gem 'mocha', :require => false
  gem 'shoulda-matchers'
  gem 'capybara'
  gem 'launchy'
  gem 'selenium-webdriver'
  gem 'poltergeist'

  gem 'rspec-rails'
  gem 'rspec-collection_matchers'
  gem 'rspec-its'
end
