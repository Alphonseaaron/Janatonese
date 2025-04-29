import express from 'express';
import path from 'path';
import { fileURLToPath } from 'url';
import fs from 'fs';
import { spawn } from 'child_process';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const app = express();
const port: number = process.env.PORT ? parseInt(process.env.PORT, 10) : 3000;

// Serve the Flutter web app
app.use(express.static(path.join(__dirname, '../janatonese/build/web')));

// Serve the Flutter project files statically
app.use('/janatonese', express.static(path.join(__dirname, '../janatonese')));

// Check if Flutter is available
const checkFlutter = spawn('which', ['flutter']);
let flutterAvailable = false;

checkFlutter.on('close', (code) => {
  flutterAvailable = code === 0;
  
  if (flutterAvailable) {
    console.log('Flutter is available. Building Flutter web app...');
    // Create the build directory if it doesn't exist
    const buildDir = path.join(__dirname, '../janatonese/build/web');
    if (!fs.existsSync(buildDir)) {
      fs.mkdirSync(buildDir, { recursive: true });
    }
    
    // Build the Flutter web app
    const buildFlutter = spawn('flutter', ['build', 'web'], {
      cwd: path.join(__dirname, '../janatonese'),
      stdio: 'inherit'
    });
    
    buildFlutter.on('close', (code) => {
      if (code === 0) {
        console.log('Flutter web app built successfully!');
      } else {
        console.error('Failed to build Flutter web app.');
        console.log('Serving placeholder app...');
        
        // Create placeholder HTML
        const placeholderHtml = `
        <!DOCTYPE html>
        <html>
        <head>
          <title>Janatonese - Flutter Messaging App</title>
          <style>
            body {
              font-family: Arial, sans-serif;
              display: flex;
              flex-direction: column;
              align-items: center;
              justify-content: center;
              height: 100vh;
              margin: 0;
              background-color: #f5f5f5;
              color: #333;
            }
            h1 {
              color: #009688;
            }
            .container {
              text-align: center;
              max-width: 600px;
              padding: 20px;
              border-radius: 8px;
              background-color: white;
              box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            }
            .description {
              margin: 20px 0;
              line-height: 1.5;
            }
            .feature {
              margin: 10px 0;
            }
          </style>
        </head>
        <body>
          <div class="container">
            <h1>Janatonese</h1>
            <h2>A Secure Messaging App with Three-Number Encryption</h2>
            
            <div class="description">
              <p>This Flutter-based application is currently under development.</p>
              <p>Janatonese uses a unique TOTP-based encryption system that encrypts messages as sets of three numbers for enhanced security.</p>
            </div>
            
            <h3>Key Features:</h3>
            <div class="feature">✅ Secure messaging with Three-Number encryption</div>
            <div class="feature">✅ Firebase authentication and real-time database</div>
            <div class="feature">✅ Contact management with shared secrets</div>
            <div class="feature">✅ Real-time message updates</div>
            <div class="feature">✅ Both encrypted and decrypted message views</div>
            
            <p style="margin-top: 30px; font-style: italic; color: #666;">
              To run the complete Flutter application, please ensure Flutter is installed correctly on your system.
            </p>
          </div>
        </body>
        </html>
        `;
        
        // Create the placeholder HTML file
        fs.writeFileSync(path.join(buildDir, 'index.html'), placeholderHtml);
      }
    });
  } else {
    console.log('Flutter is not available. Serving placeholder app...');
    
    // Create the build directory if it doesn't exist
    const buildDir = path.join(__dirname, '../janatonese/build/web');
    if (!fs.existsSync(buildDir)) {
      fs.mkdirSync(buildDir, { recursive: true });
    }
    
    // Create placeholder HTML
    const placeholderHtml = `
    <!DOCTYPE html>
    <html>
    <head>
      <title>Janatonese - Flutter Messaging App</title>
      <style>
        body {
          font-family: Arial, sans-serif;
          display: flex;
          flex-direction: column;
          align-items: center;
          justify-content: center;
          height: 100vh;
          margin: 0;
          background-color: #f5f5f5;
          color: #333;
        }
        h1 {
          color: #009688;
        }
        .container {
          text-align: center;
          max-width: 600px;
          padding: 20px;
          border-radius: 8px;
          background-color: white;
          box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .description {
          margin: 20px 0;
          line-height: 1.5;
        }
        .feature {
          margin: 10px 0;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <h1>Janatonese</h1>
        <h2>A Secure Messaging App with Three-Number Encryption</h2>
        
        <div class="description">
          <p>This Flutter-based application requires Flutter to be installed.</p>
          <p>Janatonese uses a unique TOTP-based encryption system that encrypts messages as sets of three numbers for enhanced security.</p>
        </div>
        
        <h3>Key Features:</h3>
        <div class="feature">✅ Secure messaging with Three-Number encryption</div>
        <div class="feature">✅ Firebase authentication and real-time database</div>
        <div class="feature">✅ Contact management with shared secrets</div>
        <div class="feature">✅ Real-time message updates</div>
        <div class="feature">✅ Both encrypted and decrypted message views</div>
        
        <p style="margin-top: 30px; font-style: italic; color: #666;">
          To run the complete Flutter application, please ensure Flutter is installed correctly on your system.
        </p>
      </div>
    </body>
    </html>
    `;
    
    // Create the placeholder HTML file
    fs.writeFileSync(path.join(buildDir, 'index.html'), placeholderHtml);
  }
});

// Catch-all route to serve the Flutter app
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, '../janatonese/build/web/index.html'));
});

// Start the server
app.listen(port, '0.0.0.0', () => {
  console.log(`Server running at http://0.0.0.0:${port}/`);
});