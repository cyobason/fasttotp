# FastTOTP

A streamlined Flutter application designed specifically for quick and secure QR code-based login authentication across websites and applications. Provides TOTP generation and biometric security features for enhanced user experience.

## Features

- **QR Code Login**: Quickly scan QR codes to authenticate and log in to websites and applications
- **TOTP Generation**: Secure Time-based One-Time Password generation for multi-factor authentication
- **Biometric Authentication**: Enhanced security with fingerprint and face recognition support on both Android and iOS
- **Account Management**: Add and manage multiple authentication accounts
- **Multi-language Support**: Available in 13 languages including English, Spanish, Chinese, Arabic, German, Portuguese, French, Russian, Hindi, Italian, Japanese, Korean, and Indonesian
- **Secure Local Storage**: Uses SQLite and encrypted storage to protect sensitive authentication data
- **Deep Linking**: Seamless app-to-app communication for enhanced authentication flows
- **Device-Specific Security**: Unique device identification with obfuscation to protect user privacy

## Screenshots

(Add screenshots here once the app is fully developed)

## Getting Started

### Prerequisites

- Flutter SDK (latest version recommended)
- Dart SDK
- Android Studio / Xcode for platform-specific development

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/cyobason/fasttotp.git
   cd fasttotp
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the application:
   ```bash
   flutter run
   ```

## Usage

### QR Code Login

1. When prompted to login on a website or application, look for the "Scan QR Code to Login" option
2. Open FastTOTP and tap the scan button
3. Position the QR code within the scanning frame
4. The app will automatically authenticate and log you in to the target website or application

### Managing Authentication Accounts

1. Tap the add button to register a new account
2. Enter the required account information
3. The app will generate a secure TOTP secret and store it locally
4. Your account will be available for quick access during future logins

### Using Biometric Authentication

1. Ensure your device supports biometric authentication (fingerprint or face recognition)
2. Enable biometric authentication in the app settings
3. When prompted, use your biometric data to quickly and securely authenticate without entering passwords

## Technical Details

### Architecture

- **Streamlined Architecture**: Optimized for quick authentication flows and minimal latency
- **MVVM Pattern**: Follows the Model-View-ViewModel architecture for clean separation of concerns
- **Localization**: Implements Flutter Localization for extensive multi-language support
- **State Management**: Uses Flutter's built-in state management with StatefulWidgets
- **Database**: SQLite for secure local storage of authentication credentials

### Security Features

- **Biometric Verification**: Leverages the device's secure biometric API for enhanced authentication
- **Local Encryption**: All sensitive authentication data is encrypted and stored securely
- **Device ID Obfuscation**: Protects user privacy by obfuscating device identifiers
- **QR Code Security**: Validates and processes QR codes using secure scanning practices

### Dependencies

Key dependencies include:

- `ai_barcode_scanner`: Core functionality for QR code scanning and processing
- `auth_totp`: For generating secure Time-based One-Time Passwords
- `local_auth`: For biometric authentication integration
- `app_links`: For deep linking to facilitate seamless authentication between apps
- `sqflite`: For local database storage of authentication data
- `flutter_localization`: For supporting 13 different languages
- `tdesign_flutter`: For creating a consistent and modern UI experience
- `pointycastle`: For cryptographic operations to secure sensitive data

## Supported Platforms

- Android
- iOS

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the Apache-2.0 license - see the LICENSE file for details.

## Contact

For questions or support, please contact the project maintainers.
