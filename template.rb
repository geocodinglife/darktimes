def source_paths
  [File.expand_path(File.dirname(__FILE__))]
end

def add_gems
  gem 'devise', '~> 4.7', '>= 4.7.1'
  gem 'sidekiq', '~> 6.0', '>= 6.0.6'
  gem 'dotenv-rails'
  gem 'olive_branch'
  gem 'rack-cors'
  gem 'active_model_serializers'
  gem 'jwt'
end

def add_development_gems
  content = <<-RUBY
gem 'pry', '~> 0.13.0'
  gem 'pry-rails', '~> 0.3.9'
  gem 'amazing_print'
  gem 'faker', '~> 2.11'
  gem 'rubocop-rails', '~> 2.8', '>= 2.8.1', require: false
  RUBY

  inject_into_file "Gemfile", "  #{content}\n", :before => /^  gem 'spring'/
end

generate "controller", "home index"

def add_users
  generate "devise:install"
  environment "config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }",
              env: 'development'

  generate :devise, "User", "username", "name", "admin:boolean"

  in_root do
    migration = Dir.glob("db/migrate/*").max_by{ |f| File.mtime(f) }
    gsub_file migration, /:admin/, ":admin, default: false"
  end
end

def copy_templates
  directory "app", force: true
end

def add_olive_branch
  content = <<-RUBY
  excluded_routes = ->(env) { !env["PATH_INFO"].match(%r{^/api}) }
    config.middleware.use OliveBranch::Middleware,
                        inflection:       "camel",
                        exclude_params:   excluded_routes,
                        exclude_response: excluded_routes
  RUBY

  inject_into_file "config/application.rb", "  #{content}\n", :before => /^  end/
end

def add_sidekiq
  environment "config.active_job.queue_adapter = :sidekiq"

  insert_into_file "config/routes.rb",
    "require 'sidekiq/web'\n\n",
    before: "Rails.application.routes.draw do"

  content = <<-RUBY
    authenticate :user, lambda { |u| u.admin? } do
      mount Sidekiq::Web => '/sidekiq'
    end
  RUBY

  insert_into_file "config/routes.rb", "#{content}\n\n", after: "Rails.application.routes.draw do\n"

  File.open('config/routes.rb', 'r+') do |file|
    lines = file.each_line.to_a
    lines[9] = "  root 'home#index'"
    file.rewind
    file.write(lines.join)
  end

end

def add_foreman
  copy_file "Procfile"
end

def remove_comments
  File.open('config/initializers/cors.rb', 'r+') do |file|
    lines = file.each_line.to_a
    lines[7][0]  = " "
    lines[8][0]  = " "
    lines[9]     = "      origins 'http://localhost:3000'"
    lines[10][0] = " "
    lines[11][0] = " "
    lines[12][0] = " "
    lines[13][0] = " "
    lines[14][0] = " "
    lines[15][0] = " "
    file.rewind
    file.write(lines.join)
  end

  # insert_into_file 'Procfile', "web: cd #{app_name}_web && PORT=3000 yarn start"
end

def create_config_file
  copy_file '.rubocop.yml', '.rubocop.yml'
end

def create_env_file
  copy_file '.env.example', '.env.example'
end

def add_react
  directory 'super-duper-template', "#{app_name}_web"
 ` cd #{app_name}_web --template cra-template && yarn install`
end

gsub_file('Gemfile', /^\s*#.*\n/, '')

source_paths
create_config_file
create_env_file
add_development_gems
add_gems

after_bundle do
  add_users
  add_sidekiq
  add_foreman
  copy_templates
  rails_command "db:create"
  rails_command "db:migrate"
  remove_comments
  add_olive_branch
  add_react

  git :init
  git add: "."
  git commit: %Q{ -m "Initial commit" }

  say "Kickoff app successfully created! 👍", :green
  say "Then run:"
  # say "foreman start", :green
end
