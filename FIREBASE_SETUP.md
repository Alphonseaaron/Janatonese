# Firebase Setup Guide for Janatonese

This document provides step-by-step instructions to set up Firebase for the Janatonese secure messaging app.

## 1. Create a Firebase Project

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter "Janatonese" (or your preferred name) as the project name
4. Choose whether to enable Google Analytics (recommended)
5. Accept the terms and click "Create project"

## 2. Add a Web App to Your Firebase Project

1. From the project overview page, click the web icon (</>) to add a web app
2. Register the app with the name "Janatonese Web"
3. Check the box "Also set up Firebase Hosting for this app" (optional)
4. Click "Register app"
5. Copy the Firebase configuration object for the next steps
6. Click "Continue to console"

## 3. Set Up Authentication

1. In the Firebase console, go to "Authentication" from the left sidebar
2. Click "Get started"
3. Enable the "Email/Password" sign-in method by clicking on it and toggling the enable switch
4. Click "Save"

## 4. Set Up Firestore Database

1. Go to "Firestore Database" from the left sidebar
2. Click "Create database"
3. Choose "Start in production mode" (recommended for security)
4. Select a location nearest to your primary user base
5. Click "Enable"

## 5. Set Up Firestore Security Rules

1. In the Firestore Database section, go to the "Rules" tab
2. Replace the default rules with the security rules provided in the `firebase_rules.txt` file:

```
// Firestore Rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // User profiles
    match /users/{userId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && request.auth.uid == userId;
      allow update: if request.auth != null && request.auth.uid == userId;
      allow delete: if request.auth != null && request.auth.uid == userId;
    }
    
    // Contacts (each user's contacts)
    match /contacts/{contactId} {
      allow read: if request.auth != null && resource.data.userId == request.auth.uid;
      allow create: if request.auth != null && request.resource.data.userId == request.auth.uid;
      allow update: if request.auth != null && resource.data.userId == request.auth.uid;
      allow delete: if request.auth != null && resource.data.userId == request.auth.uid;
    }
    
    // Chats
    match /chats/{chatId} {
      allow read: if request.auth != null && (
        resource.data.participant1 == request.auth.uid || 
        resource.data.participant2 == request.auth.uid
      );
      allow create: if request.auth != null && (
        request.resource.data.participant1 == request.auth.uid || 
        request.resource.data.participant2 == request.auth.uid
      );
      allow update: if request.auth != null && (
        resource.data.participant1 == request.auth.uid || 
        resource.data.participant2 == request.auth.uid
      );
      allow delete: if false;  // Don't allow chat deletions, only archiving
    }
    
    // Messages in chats
    match /chats/{chatId}/messages/{messageId} {
      allow read: if request.auth != null && (
        get(/databases/$(database)/documents/chats/$(chatId)).data.participant1 == request.auth.uid || 
        get(/databases/$(database)/documents/chats/$(chatId)).data.participant2 == request.auth.uid
      );
      allow create: if request.auth != null && (
        get(/databases/$(database)/documents/chats/$(chatId)).data.participant1 == request.auth.uid || 
        get(/databases/$(database)/documents/chats/$(chatId)).data.participant2 == request.auth.uid
      ) && request.resource.data.senderId == request.auth.uid;
      allow update: if false;  // Don't allow editing messages after sending
      allow delete: if request.auth != null && resource.data.senderId == request.auth.uid && 
                    resource.data.timestamp.toMillis() > (request.time.toMillis() - 5 * 60 * 1000); // Allow deletion only within 5 minutes of sending
    }
  }
}
```

3. Click "Publish"

## 6. Create Firestore Indexes

1. Go to the "Indexes" tab in Firestore Database
2. Add the following composite indexes:

### Collection: chats
- Fields to index:
  - participant1 (Ascending) + lastMessageTimestamp (Descending)
  - participant2 (Ascending) + lastMessageTimestamp (Descending)

### Collection: chats/chatId/messages
- Fields to index:
  - timestamp (Ascending)

### Collection: contacts
- Fields to index:
  - userId (Ascending) + displayName (Ascending)

## 7. Set Up Firebase Storage (Optional)

1. Go to "Storage" from the left sidebar
2. Click "Get started"
3. Choose "Start in production mode"
4. Click "Next"
5. Select a location (same as your Firestore Database)
6. Click "Done"
7. Go to the "Rules" tab and update the rules:

```
// Firebase Storage Rules
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Profile pictures
    match /profiles/{userId}/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Chat attachments
    match /chats/{chatId}/{fileName} {
      allow read: if request.auth != null && (
        exists(/databases/$(database)/documents/chats/$(chatId)) &&
        (
          get(/databases/$(database)/documents/chats/$(chatId)).data.participant1 == request.auth.uid || 
          get(/databases/$(database)/documents/chats/$(chatId)).data.participant2 == request.auth.uid
        )
      );
      allow write: if request.auth != null && (
        exists(/databases/$(database)/documents/chats/$(chatId)) &&
        (
          get(/databases/$(database)/documents/chats/$(chatId)).data.participant1 == request.auth.uid || 
          get(/databases/$(database)/documents/chats/$(chatId)).data.participant2 == request.auth.uid
        )
      ) && request.resource.size < 10 * 1024 * 1024; // Limit file size to 10MB
    }
  }
}
```

## 8. Add Firebase SDK to the App

1. Create a new file `lib/firebase_options.dart` with the Firebase configuration:

```dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // Replace with your configuration details from the Firebase console
    return const FirebaseOptions(
      apiKey: 'YOUR_API_KEY',
      appId: 'YOUR_APP_ID',
      messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
      projectId: 'YOUR_PROJECT_ID',
      authDomain: 'YOUR_AUTH_DOMAIN',
      storageBucket: 'YOUR_STORAGE_BUCKET',
      measurementId: 'YOUR_MEASUREMENT_ID',
    );
  }
}
```

2. Replace the placeholder values with your actual Firebase configuration

## 9. Deploy the App (Optional)

1. Install the Firebase CLI if you haven't already
2. Run `firebase login` to authenticate
3. Run `firebase init` and select Hosting
4. Connect to your Firebase project
5. Set your public directory to `build/web`
6. Configure as a single-page app
7. Build your Flutter web app with `flutter build web`
8. Deploy with `firebase deploy`

## 10. Testing

1. Run the app locally with `flutter run -d chrome`
2. Test user registration, login, and messaging functionality
3. Verify that messages are properly encrypted and decrypted
4. Check that database rules are properly securing your data

## Troubleshooting

- **Authentication Issues**: Ensure you've properly enabled Email/Password authentication
- **Database Permission Denied**: Review your security rules and make sure they match the ones provided
- **Firebase Configuration**: Double-check that your Firebase configuration details are correctly copied into `firebase_options.dart`
- **Web Build Issues**: If deploying to web, ensure you've properly configured the web app in Firebase and updated your `index.html` with the necessary Firebase scripts