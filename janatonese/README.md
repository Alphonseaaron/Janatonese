# Janatonese Secure Messaging

Janatonese is a secure messaging application that uses a unique TOTP-based encryption system, converting each character into a set of three random numbers.

## Features

- **Three-Number Encryption**: Each character is encrypted as a set of three numbers using TOTP (Time-based One-Time Password) algorithms
- **Secure Messaging**: End-to-end encrypted communication
- **Contact Management**: Add contacts and share encryption secrets
- **Real-time Updates**: Instantly receive and decrypt messages
- **Dual View Mode**: Switch between encrypted and decrypted message views

## Technologies Used

- **Flutter**: Cross-platform UI framework
- **Firebase**: Authentication and real-time database
- **TOTP Algorithm**: Time-based encryption for heightened security
- **Provider Pattern**: State management

## Encryption System

The Janatonese encryption system works as follows:

1. Each character in a message is individually processed
2. For each character, a unique seed is generated using its ASCII code and position
3. The seed is combined with the current timestamp to create a time-based factor
4. This factor is used with a shared secret key to generate a 3-digit TOTP code
5. The sequence of 3-digit codes forms the encrypted message

Example:
```
Original message: "Hello"
Encrypted as: "392 718 245 103 571"
```

## Project Structure

```
janatonese/
├── lib/
│   ├── models/             # Data models
│   ├── screens/            # UI screens
│   ├── providers/          # State management
│   ├── services/           # Firebase services
│   ├── utils/              # Utility functions (including encryption)
│   └── main.dart           # App entry point
├── assets/                 # Images and fonts
└── pubspec.yaml            # Dependencies
```

## Getting Started

1. Clone the repository
2. Configure your Firebase project and update `firebase_options.dart`
3. Run `flutter pub get` to install dependencies
4. Start the application with `flutter run`

## Security Notes

- Shared secrets should be exchanged securely between contacts
- The encryption system's security comes from the combination of time-based factors and the shared secret
- Each character has a different 3-digit code even when the same character appears multiple times