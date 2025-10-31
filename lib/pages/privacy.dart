import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:login/constants/locales.dart';
import 'package:flutter_html/flutter_html.dart';

class MyPrivacyPage extends StatelessWidget {
  const MyPrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: TDTheme.of(context).brandColor7,
        title: Text(
          Lang.t('aboutPrivacyPolicy'),
          style: TextStyle(color: Colors.white),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Html(
          data: '''
          <h3>Privacy Policy</h3>
          <p>Last updated: Oct. 2025</p>
          <p>FastTOTP App (“we”, “us”, or “our”) values your privacy. This Privacy Policy explains what information we collect, how we use it, and the choices you have.</p>
          <p>The app will not connect to any network other than the API connection associated with the QR code you scan for login.</p>
          <h3>1. Permissions</h3>
          <p>We request the following permissions solely to support core features. We do not collect or transmit personal data beyond what is described here.</p>
          <ul>
            <li>
            <h4>CAMERA</h4>
            <p>Used solely for QR code scanning to enable login and data migration; no camera-captured content or personal data is stored or shared.</p>
            </li>
            <li>
            <h4>BIOMETRIC</h4>
            <p>Used solely for biometric authentication (e.g., fingerprint, face recognition) to secure app access or verify sensitive operations; no biometric data is stored or shared externally.</p>
            </li>
          </ul>
          <h3>2. Migration Content Data</h3>
          <p>User-generated data within the app solely for transfer between authorized devices; no content is stored post-migration.</p>
          <h3>3. Device Information</h3>
          <p>We do not collect any device-related information (including but not limited to Device ID, device model, system version, hardware configuration, or network information) during your use of the app. No data related to your device will be acquired, stored, transmitted, or processed by us at any stage.</p>
          <h3>4. Security</h3>
          <p>We implement commercially reasonable technical and organizational measures to protect your data. However, no system is 100% secure. Use caution when sharing sensitive information.</p>
          <h3>5. Changes to This Policy</h3>
          <p>We may update this Privacy Policy from time to time. We will post any changes here with a revised “Last updated” date.</p>
          <h3>6. Contact Us</h3>
          <p>If you have questions or wish to exercise your data rights, please email us at:</p>
          <p>📧 cyobason@gmail.com</p>
          <p>By installing or using our app, you acknowledge that you have read and agree to this Privacy Policy. If you do not agree, please do not use the app.</p>
          ''',
        ),
      ),
    );
  }
}
