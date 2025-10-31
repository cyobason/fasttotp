import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:login/constants/locales.dart';
import 'package:flutter_html/flutter_html.dart';

class MyTermsPage extends StatelessWidget {
  const MyTermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: TDTheme.of(context).brandColor7,
        title: Text(
          Lang.t('aboutTermsOfUse'),
          style: TextStyle(color: Colors.white),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Html(
          data: '''
          <h3>Terms of Use</h3>
          <p>Last updated: Oct. 2025</p>
          <p>Before using the FastTOTP mobile application (hereinafter referred to as the "App" or "Service") operated by Cyobason (hereinafter referred to as "I" or "me"), please carefully read these Terms and Conditions (hereinafter referred to as the "Terms of Use" or "Terms"). By using the App, you agree to be bound by all provisions herein.</p>
          <h3>1. Conditions of use</h3>
          <ul>
            <li>
              <p>1.1 By using this App, you certify that you have read, understood, and agree to comply with this Agreement. If you do not agree to these Terms, you must stop using the App immediately.</p>
            </li>
            <li>
              <p>1.2 You are solely responsible for safeguarding the TOTP keys and account information created within the App (e.g., account names, secret keys). You shall bear full liability for any account security issues caused by improper storage (such as device loss or key leakage).</p>
            </li>
            <li>
              <p>1.3 You may not use the App for any illegal purposes, including but not limited to generating verification keys for unauthorized accounts or assisting in activities that violate laws or regulations.</p>
            </li>
          </ul>
          <h3>2. Privacy policy</h3>
          <p>This Terms of Use and our Privacy Policy constitute a complete agreement. By using the App, you are deemed to have also agreed to all contents of the Privacy Policy. In case of any conflict between the two, the provisions related to data processing in the Privacy Policy shall prevail. We recommend you review the Privacy Policy carefully to understand how we protect and handle your data.</p>
          <h3>3. Age restriction</h3>
          <p>You must be at least 18 years of age to use this App. By using the App, you warrant that you are 18 years of age or older and have the legal capacity to abide by this Agreement. I assume no responsibility for liabilities arising from misrepresentation of age.</p>
          <h3>4. Intellectual property</h3>
          <ul>
            <li>
              <p>4.1 All materials, products, services, and related intellectual property rights of the App (including but not limited to software code, interface design, trademarks, and copyrights) belong to me and my licensors.</p>
            </li>
            <li>
              <p>4.2 You may not engage in any of the following acts without prior written permission: reverse engineering, cracking, or tampering with the App; copying, redistributing, or publicly displaying the App’s intellectual property content in any form (electronic, digital, or otherwise).</p>
            </li>
          </ul>
          <h3>5. User Data</h3>
          <ul>
            <li>
              <p>5.1 This App will only connect to the API associated with the QR code you scan for login purposes, and will not connect to any other networks.</p>
              <p>This API connection is solely used to transmit the following data, all of which are only for completing login authentication:</p>
              <ul>
                <li>
                  <p>id: Unique account identifier (used to distinguish different login accounts, with no personal identity relevance);</p>
                </li>
                <li>
                  <p>code: One-time verification key (core data for login authentication);</p>
                </li>
                <li>
                  <p>email: The email address you use to link your FastTOTP account (only used to match your target login account);</p>
                </li>
                <li>
                  <p>secret: TOTP base secret key (underlying data for generating one-time verification keys, which will be encrypted during transmission).</p>
                </li>
              </ul>
              <p>The above transmitted data is only used to complete a single login authentication. Additionally, no additional personal identification information (such as name, ID number) or device information (such as device model, system version) will be transmitted.</p>
            </li>
            <li>
              <p>5.2 All FastTOTP account data created by you (e.g., account names, secret keys) is stored only locally on your device and will not be uploaded to my servers or shared with any third parties.</p>
            </li>
            <li>
              <p>5.3 All data will be irrecoverable once the App is deleted. Please perform data migration or proceed with caution before deleting the App.</p>
            </li>
          </ul>
          <h3>6. Applicable law</h3>
          <p>By using this App, you agree that, without regard to principles of conflict of laws, the laws of the Chinese Mainland (excluding the Hong Kong Special Administrative Region, Macao Special Administrative Region, and Taiwan Region) shall govern these Terms and Conditions, as well as any disputes of any kind that may arise between you and me.</p>
          <h3>7. Disputes</h3>
          <ul>
            <li>
              <p>7.1 Any dispute related to your use of the App shall first be resolved through friendly negotiation between the two parties.</p>
            </li>
            <li>
              <p>7.2 If negotiation fails, the dispute shall be submitted to the people’s court with jurisdiction in Huizhou, China for resolution through litigation. You consent to the exclusive jurisdiction and venue of such court.</p>
            </li>
          </ul>
          <h3>8. Indemnification</h3>
          <p>You agree to indemnify me and hold me harmless against any legal claims, demands, losses, or damages (including reasonable attorney fees) that may arise from your use or misuse of the Service (e.g., using the App for illegal activities or violating third-party rights). I reserve the right to select my own legal counsel.</p>
          <h3>9. Limitation on liability</h3>
          <ul>
            <li>
              <p>9.1 I shall not be liable for any damages (including direct, indirect, or consequential damages) that may occur to you as a result of your misuse of this App.</p>
            </li>
            <li>
              <p>9.2 For technical failures of the App that prevent you from using the Service normally, my liability is limited to "promptly repairing the fault"; I shall not be liable for indirect losses caused by service interruptions (e.g., business losses due to delayed account login), unless the fault is caused by my intentional misconduct or gross negligence.</p>
            </li>
            <li>
              <p>9.3 I reserve the right to edit, modify, or change this Agreement at any time. After modification, I will: (a) display a pop-up notification on the App’s launch page; (b) update the "Last updated" date at the top of these Terms. Your continued use of the App after the modification constitutes acceptance of the revised Agreement.</p>
            </li>
            <li>
              <p>9.4 This Agreement is an understanding between you and me, and it supersedes and replaces all prior agreements (whether written or oral) regarding the use of this App, effective as of the "Last updated" date above.</p>
            </li>
          </ul>
          ''',
        ),
      ),
    );
  }
}
