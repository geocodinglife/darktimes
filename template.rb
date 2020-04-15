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

# def add_root
#   File.open('config/routes.rb', 'r+') do |file|
#     lines = file.each_line.to_a
#     lines[9] = "root 'home#index'"
#     file.rewind
#     file.write(lines.join)
#   end
# end

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
    lines[9] = "root 'home#index'"
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
    lines[9][0]  = " "
    lines[10][0] = " "
    lines[11][0] = " "
    lines[12][0] = " "
    lines[13][0] = " "
    lines[14][0] = " "
    lines[15][0] = " "
    file.rewind
    file.write(lines.join)
  end
  # route "root to: 'home#index'"
  insert_into_file 'Procfile', "web: cd #{app_name} && PORT=3000 yarn start"
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

   insert_into_file "#{app_name}_web/src/views/home/index.js", "#{content}\n\n"


  content1 = <<-JS
import React, { Component } from 'react';
import {BrowserRouter as Router, Route, NavLink, Switch} from 'react-router-dom';

import '../stylesheets/App.css';
import Index from './home/index';

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

  insert_into_file "#{app_name}_web/src/views/App.jsx", "#{content1}\n\n"

# const fs = require('fs')
# const someFile = #{app_name}_web/src/views/App.jsx
# fs.readFile(someFile, 'utf8', function (err, data) {
#   if (err) {
#     return console.log(err);
#   }
#   let result = data.split('\n')
#   result[3] = "import {BrowserRouter as Router, Route, NavLink, Switch} from 'react-router-dom'"
#   result1 = result.join("\n")
#   fs.writeFile(someFile, result1, 'utf8', function (err) {
#      if (err) return console.log(err);
#   });
# });


`
   const fs = require('fs')
   const someFile = #{app_name}_web/src/index.js
   fs.readFile(someFile, 'utf8', function (err, data) {
     if (err) {
       return console.log(err);
     }
     let result = data.replace('./App', './views/App');

     fs.writeFile(someFile, result, 'utf8', function (err) {
        if (err) return console.log(err);
     });
   });
`

  # `node flash.js #{app_name}.web`
end

source_paths

add_gems

after_bundle do
  add_users
  # add_root
  add_sidekiq
  add_foreman
  copy_templates
  rails_command "db:create"
  rails_command "db:migrate"
  remove_comments
  add_react

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
