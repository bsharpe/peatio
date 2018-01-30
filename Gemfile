source 'https://rubygems.org'

ruby '2.4.2'

# Framework
gem 'rails', '5.1.4'
gem 'responders'
gem 'rails-observers'
gem "globalize"

# Data
gem 'mysql2'
gem 'redis-rails'
gem 'aasm'
gem 'enumerize'
gem 'kaminari'
gem 'paranoid2'
gem 'paper_trail'
gem 'marginalia'                  # show where queries are coming from in the logs
gem 'active_hash'                 # YAML-sourced data  **GET RID OF THIS**

# Security
gem 'rotp'                        # Ruby One Time Password library
gem 'bcrypt-ruby'

# Background Processing
gem 'amqp'
gem 'bunny'
gem 'pusher'
gem 'eventmachine'
gem 'em-websocket'
gem 'daemons-rails'
gem 'sucker_punch'
gem 'wisper'

# API
gem 'grape'
gem 'grape-entity'
# gem 'grape-swagger'
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

gem 'datagrid'
gem 'http_accept_language'
gem 'country_select'
gem 'gon'
gem 'simple_form'
gem 'slim-rails'
gem 'sass-rails', '>= 5.0.6'
gem 'coffee-rails', '>= 4.2.2'
gem 'uglifier', '>= 2.7.2'
gem "jquery-rails", ">= 3.1.4"
gem "angularjs-rails"
gem 'bootstrap-sass', '~> 3.2.0.2'
gem 'bootstrap-wysihtml5-rails', '>= 0.3.1.24'
gem 'font-awesome-sass'
gem 'bourbon'
gem 'momentjs-rails'
gem 'eco'
gem 'browser'
# gem 'simple_captcha2', require: 'simple_captcha'
gem 'easy_table'

## MISC
gem 'liability-proof', github: 'peatio/liability-proof', branch: :master  # proves we really hold the bitcoins/money we claim to
gem 'phonelib'                  # validates phone numbers
gem 'twilio-ruby'
gem 'unread', github: 'ledermann/unread'
gem 'carrierwave'               # storing documents online
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

gem 'interactor'                # better service objects
gem 'interactor-contracts'      # better contract validation for better service objects

group :development, :test do
  gem 'factory_bot_rails'
  gem 'faker'
  # gem 'mina'
  # gem 'mina-slack', github: 'peatio/mina-slack'
  gem 'meta_request'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'pry-rails'
  # gem 'quiet_assets'
  gem 'mails_viewer'
  gem 'timecop'
  # gem 'spring'
  # gem 'spring-commands-rspec'
  # gem 'listen'
  # gem 'dotenv-rails'
  gem 'pry-byebug'
  gem 'pry-coolline'
  gem 'pry-rescue'
  gem 'pry-stack_explorer'
  gem 'annotate'
end

group :test do
  # gem 'database_cleaner'
  # gem 'mocha', :require => false
  gem 'shoulda-matchers'
  gem 'capybara'
  gem 'launchy'
  gem 'selenium-webdriver'
  gem 'poltergeist'

  gem 'rspec-rails'
  gem 'rspec-mocks'
  gem 'rspec-collection_matchers'
  gem 'rspec-its'
end
