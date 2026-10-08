import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';
import { startClientKeepAlive } from './services/keepAliveService';
import './index.css';

// Start keep-alive heartbeat loop to prevent Render free-tier sleep mode
startClientKeepAlive();

ReactDOM.createRoot(document.getElementById('root') as HTMLElement).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
