import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App.jsx'
import './index.css'

import { StatusBar } from '@capacitor/status-bar';

// Function to hide the status bar on mobile - was covering up game buttons
const hideStatusBar = async () => {
  try {
    await StatusBar.hide();
  } catch (err) {
    console.log("Status bar plugin not available (web mode)");
  }
};

hideStatusBar();

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <div className="h-app w-full overflow-hidden">
      <App />
    </div>
  </React.StrictMode>,
)
