import React from 'react';
import { Route, Switch } from 'react-router-dom';
import ROUTES from './routes';

const Router = () => {
  return (
      <Switch>
        {ROUTES.map(({ component, path, ...rest }) => {
          const Component = component;
          return (
            <Route
              key={path}
              path={path}
              {...rest}
              render={(props) => {
                return (

                    <Component {...props} />
                );
              }}
            />
          );
        })}
      </Switch>

  );
};

export default Router;

  
  // import React, { Component } from 'react';
  // import {BrowserRouter as Router, Route, NavLink, Switch} from 'react-router-dom';

  // import Home from '../views/Home';
  // import logo from '../images/logo.svg';
  // import '../stylesheets/App.css';

  // const Navigation = () => (
  //   <nav className="navbar navbar-expand-lg navbar-dark bg-dark">
  //     <ul className="navbar-nav mr-auto">
  //       <li className="nav-item"><NavLink exact className="nav-link" activeClassName="active" to="/">Home</NavLink></li>
  //       <li className="nav-item"><NavLink exact className="nav-link" activeClassName="active" to="/articles">Articles</NavLink></li>
  //     </ul>
  //   </nav>
  // );

  // class App extends Component {
  //   render() {
  //     return (
  //       <div className="App">
  //         <Router>
  //           <div className="container">
  //             <Navigation />
  //             <Main />
  //           </div>
  //         </Router>
  //       </div>
  //     );
  //   }
  // }

  // const Main = () => (
  //   <Switch>
  //     <Route exact path="/" component={Home} />
  //   </Switch>
  // );

  // export default App;
