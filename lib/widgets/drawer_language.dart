import 'package:login/constants/globals.dart';
import 'package:flutter/material.dart';
import 'package:login/constants/locales.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:remixicon/remixicon.dart';

void openLanguageSettingDrawer() {
  var context = navigatorKey.currentContext;
  if (context == null) return;
  var items = Lang.getSupportedLanguages();
  var currentLocale = FlutterLocalization.instance.currentLocale;
  var code = currentLocale?.languageCode;
  languageSettingDrawer = TDDrawer(
    context,
    title: Lang.t('translate'),
    visible: true,
    items: items
        .map(
          (e) => TDDrawerItem(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              e['name']!,
              style: TextStyle(
                color: TDTheme.of(context).fontGyColor1,
                fontSize: TDTheme.of(context).fontBodyLarge?.size ?? 16,
                height: TDTheme.of(context).fontBodyLarge?.height ?? 24,
                fontWeight: FontWeight.w400,
              ),
            ),
            code == e['code']
                ? Icon(
              Remix.check_line,
              size: 24,
              color: TDTheme.of(context).brandColor7,
            )
                : Container(),
          ],
        ),
      ),
    )
        .toList(),
    onItemClick: (index, item) {
      var code = items[index]['code'];
      FlutterLocalization.instance.translate(code!);
      languageSettingDrawer?.close();
    },
  );
}
