import React from 'react';
import { BrowserRouter } from 'react-router-dom';

import Router from './routes/Router';
import NavBar from './components/NavBar/navbar'
const App = () => (
  <BrowserRouter>
      <Router />
  </BrowserRouter>
);
export default App;
