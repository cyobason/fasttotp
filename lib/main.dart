import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:login/constants/locales.dart';
import 'package:login/pages/home.dart';
import 'package:login/constants/globals.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await FlutterLocalization.instance.ensureInitialized();
  List<Locale> locales = PlatformDispatcher.instance.locales;
  Locale primaryLocale = locales.first;
  runApp(MyApp(initialLocale: primaryLocale));
}

class MyApp extends StatefulWidget {
  final Locale initialLocale;
  const MyApp({super.key, required this.initialLocale});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  FlutterLocalization localization = FlutterLocalization.instance;
  Locale? _locale;

  @override
  void initState() {
    localization.init(
      mapLocales: Lang.mapLocales,
      initLanguageCode: Lang.getValidLanguageCode(
        widget.initialLocale.languageCode,
      ),
    );
    localization.onTranslatedLanguage = _onTranslatedLanguage;
    _locale = widget.initialLocale;
    super.initState();
  }

  void _onTranslatedLanguage(Locale? locale) {
    setState(() {
      _locale = locale!;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isRTL = _locale?.languageCode == 'ar';
    return MaterialApp(
      locale: _locale,
      navigatorKey: navigatorKey,
      supportedLocales: localization.supportedLocales,
      localizationsDelegates: localization.localizationsDelegates,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: TDTheme.of(context).grayColor1,
        appBarTheme: AppBarTheme(iconTheme: IconThemeData(color: Colors.white)),
      ),
      home: Directionality(
        textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
        child: const MyHomePage(),
      ),
    );
  }
}
