# Real-Time Features in Janatonese

This document explains how real-time features like typing indicators and read receipts are implemented in the Janatonese app.

## Architecture Overview

Janatonese uses a combination of Firebase Firestore and Firebase Realtime Database to implement real-time features:

- **Firebase Firestore**: For storing message data, user profiles, and chat metadata
- **Firebase Realtime Database**: For handling presence (online status) and typing indicators
- **Firebase Storage**: For storing message attachments

## Typing Indicators

Typing indicators show when a user is actively typing a message. This creates a more engaging and responsive conversation experience.

### Implementation

1. **Detecting Typing Events**:
   - The app monitors text input in the message field
   - When a user starts typing, the app sets `isTyping` to `true`
   - When typing stops (after a brief delay) or a message is sent, `isTyping` is set to `false`

2. **Throttling Updates**:
   - To prevent excessive database writes, typing status updates are throttled
   - Updates are only sent if the status changes or if a minimum time interval has passed (2 seconds)

3. **Data Structure in Firestore**:
   ```json
   /chats/{chatId} {
     "{userId}_typing": true|false,
     "{userId}_typingTimestamp": timestamp
   }
   ```

4. **Listening for Changes**:
   - The app subscribes to changes in the chat document
   - When another user's typing status changes, the UI is updated to show or hide the typing indicator
   - The typing indicator is only shown if the timestamp is recent (within 10 seconds)

## Read Receipts

Read receipts show when a message has been viewed by the recipient. This helps users know when their messages have been seen.

### Implementation

1. **Marking Messages as Read**:
   - When a user opens a chat, all unread messages from the other user are marked as read
   - This is done in a batch update to Firestore
   - The `readAt` field is set to the current timestamp

2. **Data Structure**:
   ```json
   /chats/{chatId}/messages/{messageId} {
     "senderId": "user123",
     "text": "encrypted_message",
     "timestamp": timestamp,
     "sentAt": timestamp,
     "deliveredAt": timestamp,
     "readAt": timestamp
   }
   ```

3. **Message Status**:
   - Messages can have several statuses: sending, sent, delivered, read, failed
   - The status is determined by examining the presence of various timestamp fields

4. **UI Indicators**:
   - Different icons show the message status (checkmarks)
   - For read messages, the app displays when the message was read ("Read today at 10:45")

## Online Presence

Online presence shows when users are actively using the app. This helps users know when they're likely to get a quick response.

### Implementation

1. **Setting Online Status**:
   - When the app is opened, the user's status is set to "online"
   - When the app is closed, the status is set to "offline"
   - A disconnection handler ensures offline status is set even if the app crashes

2. **Data Structure in RTDB**:
   ```json
   /status/{userId} {
     "state": "online"|"offline",
     "last_changed": timestamp
   }
   ```

3. **UI Indicators**:
   - Online users show a green dot next to their profile picture
   - Offline users may show their last seen time ("Last seen 2 hours ago")

## Connection Between Components

Here's how these features interact within the app architecture:

1. **ChatStatusService**: 
   - Central service that handles typing indicators and read receipts
   - Provides methods to update and listen for status changes
   - Manages database connections and throttling

2. **PresenceService**:
   - Manages user online status
   - Uses Firebase Realtime Database for faster updates
   - Syncs status to Firestore for persistence

3. **EnhancedChatProvider**:
   - Higher-level provider that coordinates between UI and services
   - Maintains message state and handles sending/receiving
   - Integrates with the status services

4. **RealTimeChatScreen**:
   - UI component that displays messages, typing indicators, and read receipts
   - Responds to real-time updates from the providers

## Performance Considerations

- **Throttling**: Typing status updates are throttled to reduce database writes
- **Batching**: Read status updates are batched together in a single database operation
- **RTDB vs. Firestore**: Realtime Database is used for presence due to its lower latency

## Security Rules

Security rules are set up to ensure that:

1. Users can only read and write typing indicators for chats they participate in
2. Only the recipient can mark a message as read
3. Message content can only be modified by the sender
4. Online status can only be updated by the user themselves

See [FIREBASE_RULES.md](../FIREBASE_RULES.md) for detailed security rules.