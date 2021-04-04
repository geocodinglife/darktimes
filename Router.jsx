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