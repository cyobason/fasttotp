import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:login/constants/globals.dart';
import 'package:login/constants/locales.dart';
import 'package:remixicon/remixicon.dart';

TDDrawerItem item({
  required IconData icon,
  required String id,
  String right = "",
  bool arrow = true,
  bool finger = false,
  VoidCallback? onChanged,
}) {
  var context = navigatorKey.currentContext;
  return TDDrawerItem(
    title: id,
    content: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 24, color: TDTheme.of(context).brandColor7),
            SizedBox(width: TDTheme.of(context).spacer12),
            Text(
              Lang.t(id),
              style: TextStyle(
                color: TDTheme.of(context).fontGyColor1,
                fontSize: TDTheme.of(context).fontBodyLarge?.size ?? 16,
                height: TDTheme.of(context).fontBodyLarge?.height ?? 24,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            right.isNotEmpty
                ? right == 'switch'
                      ? TDSwitch(
                          isOn: finger,
                          size: TDSwitchSize.small,
                          onChanged: (value) {
                            onChanged?.call();
                            return value;
                          },
                        )
                      : Row(
                          children: [
                            Text(
                              right,
                              style: TextStyle(
                                color: TDTheme.of(context).grayColor7,
                                fontSize:
                                    TDTheme.of(context).fontBodyLarge?.size ??
                                    16,
                                height:
                                    TDTheme.of(context).fontBodyLarge?.height ??
                                    24,
                              ),
                            ),
                          ],
                        )
                : Container(),
            arrow && right != 'switch'
                ? Icon(
                    Remix.arrow_right_s_line,
                    size: 24,
                    color: TDTheme.of(context).grayColor4,
                  )
                : Container(),
          ],
        ),
      ],
    ),
  );
}
