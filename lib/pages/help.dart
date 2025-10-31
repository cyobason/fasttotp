import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:login/constants/locales.dart';
import 'package:flutter_html/flutter_html.dart';

class MyHelpCenterPage extends StatelessWidget {
  const MyHelpCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: TDTheme.of(context).brandColor7,
        title: Text(
          Lang.t('aboutHelpCenter'),
          style: TextStyle(color: Colors.white),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Html(
          data: '''
          <h3>Overview</h3>
          <p>This app takes "no registration, no password" as its core advantage and focuses on a minimalist QR code login experience. It eliminates the need for tedious account registration processes and the hassle of remembering or entering passwords — users only need to scan the login QR code for the corresponding scenario using the app to quickly complete identity verification and log in.</p>
          <p>To further ensure data security during use, RSA security encryption technology is applied throughout the entire data collection process. This encryption method is currently unbreakable, providing an additional layer of protection for your information. Overall, the app significantly lowers the operation barrier while ensuring login security and convenience, making it suitable for various scenarios that require efficient login.</p>
          <h3>Add an Email Address</h3>
          <p>Tap the "+" icon in the top-right corner to add the email address you want to use for logging in.</p>
          <h3>Log In via QR Code Scan</h3>
          <p>Tap the QR code scanning icon button in the bottom-right corner, then scan the QR code displayed on the website to complete the login.</p>
          <h3>Delete an Email Address</h3>
          <p>Swipe right on the email address you want to remove, and a delete button will appear.</p>
          <h3>Delete a Logged-in Website or App</h3>
          <p>Long-press the name of the website or app you want to remove, and a delete confirmation dialog will pop up to proceed with the deletion.</p>
          <h3>Data Migration</h3>
          <p>Select either the "Old Device" or "New Device" option to start the data migration process.</p>
          <ul>
            <li>
              <p>First, select "Old Device" on your original device. A QR code will then be displayed on the screen.</p>
            </li>
            <li>
              <p>Use your new device to scan this QR code, and the data migration will proceed automatically.</p>
            </li>
          </ul>
          <p>That’s it! All core operations—from adding an email and logging in via QR code to deleting accounts or migrating data—are designed to be simple and straightforward. No complicated steps, just easy, efficient use whenever you need it.</p>
          ''',
        ),
      ),
    );
  }
}
