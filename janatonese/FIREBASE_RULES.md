# Firebase Security Rules for Janatonese

This document provides the security rules for the Janatonese app's Firebase services.

## Firestore Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Check if the user is authenticated
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Check if the user owns the document
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    // Check if the user is a participant in the chat
    function isParticipant(chatData) {
      return isAuthenticated() && 
        (chatData.participant1 == request.auth.uid || 
         chatData.participant2 == request.auth.uid);
    }
    
    // User profiles - users can read any profile but only edit their own
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow create, update, delete: if isOwner(userId);
    }
    
    // Contacts - users can only access their own contacts
    match /contacts/{contactId} {
      allow read: if isAuthenticated() && resource.data.userId == request.auth.uid;
      allow create: if isAuthenticated() && request.resource.data.userId == request.auth.uid;
      allow update, delete: if isAuthenticated() && resource.data.userId == request.auth.uid;
    }
    
    // Chats - participants can read and update, but not delete chats
    match /chats/{chatId} {
      allow read, update: if isAuthenticated() && isParticipant(resource.data);
      allow create: if isAuthenticated() && 
        (request.resource.data.participant1 == request.auth.uid || 
         request.resource.data.participant2 == request.auth.uid);
      allow delete: if false;  // Don't allow chat deletion
      
      // Messages within chats
      match /messages/{messageId} {
        // Allow reading messages if the user is a participant in the parent chat
        allow read: if isAuthenticated() && 
          isParticipant(get(/databases/$(database)/documents/chats/$(chatId)).data);
          
        // Allow creating messages if the user is a participant and the senderId matches auth
        allow create: if isAuthenticated() && 
          isParticipant(get(/databases/$(database)/documents/chats/$(chatId)).data) && 
          request.resource.data.senderId == request.auth.uid;
        
        // Allow updating only for read receipts
        allow update: if isAuthenticated() && 
          isParticipant(get(/databases/$(database)/documents/chats/$(chatId)).data) &&
          request.resource.data.diff(resource.data).affectedKeys().hasOnly(['readAt', 'deliveredAt']);
          
        // Allow deleting only your own messages within 5 minutes of sending
        allow delete: if isAuthenticated() && 
          resource.data.senderId == request.auth.uid && 
          resource.data.timestamp.toMillis() > (request.time.toMillis() - 5 * 60 * 1000);
      }
    }
  }
}
```

## Realtime Database Rules

```javascript
{
  "rules": {
    ".read": false,
    ".write": false,
    
    // Connection status
    "status": {
      "$uid": {
        // Only authenticated users can read anyone's status
        ".read": "auth != null",
        // Users can only write their own status
        ".write": "auth != null && auth.uid == $uid",
        // Validate the data structure
        ".validate": "newData.hasChildren(['state', 'last_changed'])",
        "state": {
          ".validate": "newData.val() == 'online' || newData.val() == 'offline'"
        },
        "last_changed": {
          ".validate": "newData.val() <= now"
        }
      }
    },
    
    // Typing indicators
    "typing": {
      "$chatId": {
        "$uid": {
          // Only chat participants can read typing status
          ".read": "auth != null && 
            (root.child('chats').child($chatId).child('participant1').val() == auth.uid || 
             root.child('chats').child($chatId).child('participant2').val() == auth.uid)",
          // Users can only write their own typing status
          ".write": "auth != null && auth.uid == $uid",
          // Validate typing data structure
          ".validate": "newData.hasChildren(['isTyping', 'timestamp'])",
          "isTyping": {
            ".validate": "newData.isBoolean()"
          },
          "timestamp": {
            ".validate": "newData.val() <= now"
          }
        }
      }
    }
  }
}
```

## Storage Rules

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Profile pictures - readable by anyone, writable by owner
    match /profiles/{userId}/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Chat attachments - readable and writable by chat participants
    match /chats/{chatId}/{fileName} {
      allow read: if request.auth != null && 
        (exists(/databases/(default)/documents/chats/$(chatId))) &&
        (
          get(/databases/(default)/documents/chats/$(chatId)).data.participant1 == request.auth.uid || 
          get(/databases/(default)/documents/chats/$(chatId)).data.participant2 == request.auth.uid
        );
      
      allow write: if request.auth != null && 
        (exists(/databases/(default)/documents/chats/$(chatId))) &&
        (
          get(/databases/(default)/documents/chats/$(chatId)).data.participant1 == request.auth.uid || 
          get(/databases/(default)/documents/chats/$(chatId)).data.participant2 == request.auth.uid
        ) && 
        request.resource.size < 10 * 1024 * 1024 && // Max 10MB
        (
          request.resource.contentType.matches('image/.*') ||
          request.resource.contentType.matches('video/.*') ||
          request.resource.contentType.matches('audio/.*') ||
          request.resource.contentType.matches('application/pdf') ||
          request.resource.contentType.matches('application/msword') ||
          request.resource.contentType.matches('application/vnd.openxmlformats-officedocument.*') ||
          request.resource.contentType.matches('text/plain')
        );
    }
  }
}
```

## Setting Up Firebase

### Firestore Database

1. Copy and paste the Firestore rules to your Firebase console
2. Create the following indexes:

#### Indexes

1. Collection: `chats`
   - Fields to index:
     - `participant1` (Ascending) + `lastMessageTimestamp` (Descending)
     - `participant2` (Ascending) + `lastMessageTimestamp` (Descending)

2. Collection: `chats/{chatId}/messages`
   - Fields to index:
     - `timestamp` (Ascending)
     - `senderId` (Ascending) + `readAt` (Ascending)

3. Collection: `contacts`
   - Fields to index:
     - `userId` (Ascending) + `displayName` (Ascending)

### Realtime Database

1. Create a Realtime Database in your Firebase project
2. Copy and paste the Realtime Database rules to your Firebase console

### Storage

1. Copy and paste the Storage rules to your Firebase console

### Authentication

1. Enable Email/Password authentication in the Firebase console
2. Optionally, enable Google Sign-In for easier authentication