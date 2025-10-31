import 'package:flutter_localization/flutter_localization.dart';
import 'package:login/constants/globals.dart';
import 'package:login/constants/i18n/i18n.dart';

mixin Lang {
  static const String about = 'about';
  static const String aboutHelpCenter = 'aboutHelpCenter';
  static const String aboutLicense = 'aboutLicense';
  static const String aboutPrivacyPolicy = 'aboutPrivacyPolicy';
  static const String aboutTermsOfUse = 'aboutTermsOfUse';
  static const String addHintText = 'addHintText';
  static const String addSuccess = 'addSuccess';
  static const String addTip = 'addTip';
  static const String addTitle = 'addTitle';
  static const String androidBiometricHint = 'androidBiometricHint';
  static const String androidBiometricNotRecognized =
      'androidBiometricNotRecognized';
  static const String androidBiometricRequiredTitle =
      'androidBiometricRequiredTitle';
  static const String androidDeviceCredentialsRequiredTitle =
      'androidDeviceCredentialsRequiredTitle';
  static const String androidDeviceCredentialsSetupDescription =
      'androidDeviceCredentialsSetupDescription';
  static const String androidGoToSettingsDescription =
      'androidGoToSettingsDescription';
  static const String androidSignInTitle = 'androidSignInTitle';
  static const String apiRequestFail = 'apiRequestFail';
  static const String authInProgress = 'authInProgress';
  static const String cancel = 'cancel';
  static const String choose = 'choose';
  static const String colName = 'colName';
  static const String confirm = 'confirm';
  static const String confirmDelete = 'confirmDelete';
  static const String confirmLogin = 'confirmLogin';
  static const String dangerousOperation = 'dangerousOperation';
  static const String dataTransfer = 'dataTransfer';
  static const String delete = 'delete';
  static const String emailExists = 'emailExists';
  static const String emptyState = 'emptyState';
  static const String enableFingerprintFirst = 'enableFingerprintFirst';
  static const String finger = 'finger';
  static const String goToSettings = 'goToSettings';
  static const String id = 'id';
  static const String invalidEmail = 'invalidEmail';
  static const String iOSLockOut = 'iOSLockOut';
  static const String lastTime = 'lastTime';
  static const String localizedFallbackTitle = 'localizedFallbackTitle';
  static const String localizedReason = 'localizedReason';
  static const String lockedOutPermanently = 'lockedOutPermanently';
  static const String lockedOutTemporarily = 'lockedOutTemporarily';
  static const String loginSuccess = 'loginSuccess';
  static const String name = 'name';
  static const String newDevice = 'newDevice';
  static const String noActivity = 'noActivity';
  static const String noBiometricsEnrolled = 'noBiometricsEnrolled';
  static const String noFragmentActivity = 'noFragmentActivity';
  static const String noResults = 'noResults';
  static const String olDevice = 'olDevice';
  static const String placeHolder = 'placeHolder';
  static const String qrScanEmpty = 'qrScanEmpty';
  static const String sameWifi = 'sameWifi';
  static const String scan = 'scan';
  static const String scanWithNewDevice = 'scanWithNewDevice';
  static const String securityCredentialsNotAvailable =
      'securityCredentialsNotAvailable';
  static const String settings = 'settings';
  static const String success = 'success';
  static const String translate = 'translate';

  static const List<MapLocale> mapLocales = [
    MapLocale('en', en),
    MapLocale('es', es),
    MapLocale('zh', zh),
    MapLocale('ar', ar),
    MapLocale('de', de),
    MapLocale('pt', pt),
    MapLocale('fr', fr),
    MapLocale('ru', ru),
    MapLocale('hi', hi),
    MapLocale('it', it),
    MapLocale('ja', ja),
    MapLocale('ko', ko),
    MapLocale('id', indonesia),
  ];


  static String getValidLanguageCode(String languageCode) {
    var supportedCodes = mapLocales
        .map((locale) => locale.languageCode)
        .toList();
    if (supportedCodes.contains(languageCode)) {
      return languageCode;
    }
    return 'en';
  }

  static String t(String key, [List<String> args = const []]) {
    var context = navigatorKey.currentContext;
    if (context == null) return key;
    return context.formatString(key, args);
  }

  static List<Map<String, String>> getSupportedLanguages() {
    return mapLocales.map((mapLocale) {
      String code = mapLocale.languageCode;
      String name = mapLocale.mapData['name'];
      return {'code': code, 'name': name};
    }).toList();
  }
}
