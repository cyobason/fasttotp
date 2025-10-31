import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:flutter/material.dart';
import 'package:login/constants/globals.dart';
import 'package:login/constants/locales.dart';
import 'dart:typed_data';
import 'package:login/utils/web_server.dart';

void alert(String title, {VoidCallback? onTap}) {
  var context = navigatorKey.currentContext;
  if (context == null) return;
  showGeneralDialog(
    context: context,
    pageBuilder:
        (
          BuildContext buildContext,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
        ) {
          return TDConfirmDialog(
            title: title,
            buttonStyle: TDDialogButtonStyle.text,
            buttonText: Lang.t('confirm'),
            action: () {
              Navigator.pop(context);
              onTap?.call();
            },
          );
        },
  );
}

void confirm(
  String title,
  String right, {
  String? content = '',
  VoidCallback? onTap,
}) {
  var context = navigatorKey.currentContext;
  if (context == null) return;
  showGeneralDialog(
    context: context,
    pageBuilder:
        (
          BuildContext buildContext,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
        ) {
          return TDAlertDialog(
            title: title,
            content: content!.isNotEmpty ? content : null,
            buttonStyle: TDDialogButtonStyle.text,
            leftBtn: TDDialogButtonOptions(
              title: Lang.t('cancel'),
              action: () {
                Navigator.pop(context);
              },
            ),
            rightBtn: TDDialogButtonOptions(
              title: right,
              theme: TDButtonTheme.danger,
              action: () {
                Navigator.pop(context);
                onTap?.call();
              },
            ),
          );
        },
  );
}

void showImageDialog(Uint8List imageBytes) {
  var context = navigatorKey.currentContext;
  if (context == null) return;
  showGeneralDialog(
    context: context,
    pageBuilder:
        (
          BuildContext buildContext,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
        ) {
          return TDConfirmDialog(
            contentMaxHeight: 230,
            title: Lang.t('scanWithNewDevice'),
            contentWidget: Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: ClipRRect(
                  child: Image.memory(
                    imageBytes,
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            buttonStyle: TDDialogButtonStyle.text,
            buttonText: Lang.t('confirm'),
            action: () {
              Navigator.pop(context);
              closeWebServer();
            },
          );
        },
  );
}
