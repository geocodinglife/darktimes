def source_paths
  [File.expand_path(File.dirname(__FILE__))]
end


def add_gems
  gem 'devise', '~> 4.7', '>= 4.7.1'
  gem 'sidekiq', '~> 6.0', '>= 6.0.6'
  gem 'dotenv-rails'
  gem 'olive_branch'
  gem 'rack-cors'
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

  insert_into_file 'Procfile', "web: cd #{app_name}_web && PORT=3000 yarn start"
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
   touch src/views/home/Index.js
   mv src/logo.svg src/images/logo.svg
   rm -R src/index.css
   touch src/stylesheets/index.css
   mv src/App.css src/stylesheets/App.css
   rm -R src/App.js
   rm -R src/index.js
   touch src/index.js
   touch src/views/App.js
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

  insert_into_file "#{app_name}_web/src/views/home/Index.js", "#{content}\n\n"

  content1 = <<-JS
  import React, { Component } from 'react';
  import {BrowserRouter as Router, Route, NavLink, Switch} from 'react-router-dom';

  import Index from './home/Index';
  import logo from '../images/logo.svg';
  import '../stylesheets/App.css';

  const Navigation = () => (
    <nav className="navbar navbar-expand-lg navbar-dark bg-dark">
      <ul className="navbar-nav mr-auto">
        <li className="nav-item"><NavLink exact className="nav-link" activeClassName="active" to="/">Home</NavLink></li>
        <li className="nav-item"><NavLink exact className="nav-link" activeClassName="active" to="/articles">Articles</NavLink></li>
      </ul>
    </nav>
  );

  class App extends Component {
    render() {
      return (
        <div className="App">
          <Router>
            <div className="container">
              <Navigation />
              <Main />
            </div>
          </Router>
        </div>
      );
    }
  }

  const Main = () => (
    <Switch>
      <Route exact path="/" component={Index} />
    </Switch>
  );

  export default App;
  JS

  insert_into_file "#{app_name}_web/src/views/App.js", "#{content1}\n\n"

  content2 = <<-JS
  import React from 'react';
  import ReactDOM from 'react-dom';
  import './stylesheets/index.css';
  import App from './views/App';
  import * as serviceWorker from './serviceWorker';

  ReactDOM.render(<React.StrictMode><App /></React.StrictMode>,document.getElementById('root'));

  serviceWorker.unregister();
  JS

  insert_into_file "#{app_name}_web/src/index.js", "#{content2}\n\n"
  # `node flash.js #{app_name}`
end



gsub_file('Gemfile', /^\s*#.*\n/, '')
source_paths
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
