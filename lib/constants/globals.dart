import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
int connectTimeout = 3000;
TDDrawer? languageSettingDrawer;
TDDrawer? aboutDrawer;
TDActionSheet? actionSheet;
TDActionSheet? actionSheetForChoose;
String? publicKey;
HttpServer? webServer;
