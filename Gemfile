source 'https://rubygems.org'
ruby '2.0.0'

win_os = false

if $PROGRAM_NAME =~ /[A-Za-z]:[\/\\]/
  win_os = true
  os = 'Windows'
else
  os = '*nix/os x'
end

puts "\nBundling on #{os}."

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.0.0'

# Database
gem 'mysql2', '0.3.11'

# Use SCSS for stylesheets
gem 'sass-rails', '~> 4.0.0'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'

# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails', '~> 4.0.0'

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'

# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 1.0.1'

group :doc do
  # bundle exec rake doc:rails generates the API under doc/api.
  gem 'sdoc', require: false
end

group :test do
  gem "rspec"
end

gem 'debugger', group: [:development, :test] if not win_os

group :development do 
  gem 'awesome_print'
end

gem "rspec-rails", :group => [:development, :test]

gem 'awesome_nested_set', :tag => 'rails4' , git: 'git://github.com/collectiveidea/awesome_nested_set.git'


# Use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# Use unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano', group: :development

# Use debugger
# 
