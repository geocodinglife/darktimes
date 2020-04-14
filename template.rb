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

generate "controller", "home index"

def add_users
  generate "devise:install"
  environment "config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }",
              env: 'development'

  # route "root to: 'home#index'"
  generate :devise, "User", "username", "name", "admin:boolean"

  in_root do
    migration = Dir.glob("db/migrate/*").max_by{ |f| File.mtime(f) }
    gsub_file migration, /:admin/, ":admin, default: false"
  end
end

def copy_templates
  directory "app", force: true
end

def add_react_native

end

def add_react
  `npx create-react-app #{app_name}_web &&
   cd #{app_name}_web &&
   yarn add react-router-dom axios
   mkdir public/images
   mv public/favicon.ico public/images/favicon.ico
   mkdir src/images
   mkdir src/stylesheets
   mkdir src/views
   mkdir src/views/home
   touch src/views/home/index.js
   mv src/logo.svg src/images/logo.svg
   mv src/index.css src/stylesheets/index.css
   mv src/App.css src/stylesheets/App.css
   mv src/App.js src/views/App.jsx
   mv src/App.test.js src/views/App.test.js
  `

  content = <<-JS
import React from 'react';

const Index = () => {
  return (
    <div className="jumbotron">
      <h1>Home page</h1>
    </div>
  );
}

export default Index;
   JS

   content1 = <<-JS
     import App from './views/App'
   JS

   content2 = <<-JS
     import {BrowserRouter as Router, Route, NavLink, Switch} from 'react-router-dom'
   JS

  insert_into_file "#{app_name}_web/src/views/home/index.js", "#{content}\n\n"
  insert_into_file "#{app_name}_web/src/index.js", "#{content1}"
  insert_into_file "#{app_name}_web/src/views/App.jsx", "#{content2}"

  # `node flash.js #{app_name}.web`
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

def add_root
  File.open('config/initializers/routes.rb', 'r+') do |file|
    file.each_line.to_a
    file[10] = root to: 'home#index'
    file.rewind
    file.write(lines.join)
  end
end

def remove_comments
  File.open('config/initializers/cors.rb', 'r+') do |file|
  lines = file.each_line.to_a
  lines[7][0]  = ""
  lines[8][0]  = ""
  lines[9][0]  = ""
  lines[10][0] = ""
  lines[11][0] = ""
  lines[12][0] = ""
  lines[13][0] = ""
  lines[14][0] = ""
  lines[15][0] = ""
  file.rewind
  file.write(lines.join)
end

#   cors = <<-RUBY
# Rails.application.config.middleware.insert_before 0, Rack::Cors do
#   allow do
#     origins 'http://localhost:3000'
#     resource '*', :headers => :any, :methods => [:get, :post, :put, :patch, :delete, :options]
#   end
# end
# RUBY

  # insert_into_file 'config/initializers/cors.rb', "#{cors}\n\n\n\n"
  # route "root to: 'home#index'"
  insert_into_file 'Procfile', "web: cd #{app_name} && PORT=3000 yarn start"
end


source_paths

add_gems

after_bundle do
  add_users
  add_sidekiq
  add_react
  add_foreman
  copy_templates
  remove_comments
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
