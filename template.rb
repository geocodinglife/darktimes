def source_paths
  [File.expand_path(File.dirname(__FILE__))]
end

def add_gems
  gem 'devise', '~> 4.7', '>= 4.7.1'
  gem 'sidekiq', '~> 6.0', '>= 6.0.6'
  gem 'pry', '~> 0.13.0'
  gem 'pry-rails', '~> 0.3.9'
  gem 'awesome_print', '~> 1.8'
  gem 'faker', '~> 2.11'
end

def add_users
  generate "devise:install"
  environment "config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }",
              env: 'development'

  route "root to: 'home#index'"
  generate :devise, "User", "username", "name", "admin:boolean"

  in_root do
    migration = Dir.glob("db/migrate/*").max_by{ |f| File.mtime(f) }
    gsub_file migration, /:admin/, ":admin, default: false"
  end
end

def copy_templates
  directory "app", force: true
end

def add_react
  inpu_text = 'heart'
  @posts = `node heart.js #{inpu_text}`
  puts @posts
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
end

def add_foreman
  copy_file "Procfile"
end

source_paths

add_gems

after_bundle do
  add_users
  add_sidekiq
  add_foreman
  copy_templates

  # Migrate
  rails_command "db:create"
  rails_command "db:migrate"

  git :init
  git add: "."
  git commit: %Q{ -m "Initial commit" }

  say
  say "Kickoff app successfully created! 👍", :green
  say
  say "Switch to your app by running:"
  say "$ cd #{app_name}", :yellow
  say
  say "Then run:"
  say "$ rails server", :green
end
