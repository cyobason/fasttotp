import 'package:flutter/material.dart';
import 'package:login/constants/globals.dart';
import 'package:login/constants/locales.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:remixicon/remixicon.dart';
import 'package:login/widgets/drawer_item.dart';
import 'package:login/pages/license.dart';
import 'package:login/pages/privacy.dart';
import 'package:login/pages/terms.dart';
import 'package:login/pages/help.dart';

void openAboutDrawer() {
  var context = navigatorKey.currentContext;
  if (context == null) return;
  aboutDrawer = TDDrawer(
    context,
    title: Lang.t('about'),
    visible: true,
    items: [
      item(icon: Remix.question_line, id: 'aboutHelpCenter'),
      item(icon: Remix.file_text_line, id: 'aboutTermsOfUse'),
      item(icon: Remix.spy_line, id: 'aboutPrivacyPolicy'),
      item(icon: Remix.git_repository_line, id: 'aboutLicense'),
    ],
    onItemClick: (index, item) {
      if (item.title == 'aboutHelpCenter') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MyHelpCenterPage()),
        );
      }
      if (item.title == 'aboutTermsOfUse') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MyTermsPage()),
        );
      }
      if (item.title == 'aboutPrivacyPolicy') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MyPrivacyPage()),
        );
      }
      if (item.title == 'aboutLicense') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MyLicensePage()),
        );
      }
    },
  );
}
