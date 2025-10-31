import 'package:flutter/services.dart';
import 'package:login/utils/preferences.dart';
import 'package:login/constants/locales.dart';
import 'package:login/utils/alert.dart';
import 'package:local_auth/local_auth.dart';
// ignore: depend_on_referenced_packages
import 'package:local_auth_android/local_auth_android.dart';
// ignore: depend_on_referenced_packages
import 'package:local_auth_darwin/local_auth_darwin.dart';

Future<Map<String, bool>> authenticateWithBiometrics({
  bool update = false,
}) async {
  var auth = LocalAuthentication();
  var authenticated = false;
  try {
    authenticated = await auth.authenticate(
      localizedReason: Lang.t('localizedReason'),
      authMessages: <AuthMessages>[
        AndroidAuthMessages(
          biometricHint: Lang.t('androidBiometricHint'),
          biometricNotRecognized: Lang.t('androidBiometricNotRecognized'),
          biometricRequiredTitle: Lang.t('androidBiometricRequiredTitle'),
          biometricSuccess: Lang.t('success'),
          cancelButton: Lang.t('cancel'),
          deviceCredentialsRequiredTitle: Lang.t(
            'androidDeviceCredentialsRequiredTitle',
          ),
          deviceCredentialsSetupDescription: Lang.t(
            'androidDeviceCredentialsSetupDescription',
          ),
          goToSettingsButton: Lang.t('goToSettings'),
          goToSettingsDescription: Lang.t('androidGoToSettingsDescription'),
          signInTitle: Lang.t('androidSignInTitle'),
        ),
        IOSAuthMessages(
          goToSettingsButton: Lang.t('goToSettings'),
          goToSettingsDescription: Lang.t('androidGoToSettingsDescription'),
          cancelButton: Lang.t('cancel'),
          lockOut: Lang.t('iOSLockOut'),
          localizedFallbackTitle: Lang.t('localizedFallbackTitle'),
        ),
      ],
      options: const AuthenticationOptions(
        stickyAuth: true,
        biometricOnly: true,
      ),
    );
    if (authenticated) {
      if (update) {
        var fingerValue = await option('finger');
        if (fingerValue.isNotEmpty) {
          await option('finger', remove: true);
        } else {
          await option('finger', value: 'authenticated');
        }
        return {'authenticated': true, 'verified': !fingerValue.isNotEmpty};
      }
      return {'authenticated': true};
    }
    return {'authenticated': false};
  } on PlatformException catch (e) {
    switch (e.code) {
      case 'auth_in_progress':
        alert(Lang.t('authInProgress'));
        break;
      case 'no_activity':
        alert(Lang.t('noActivity'));
        break;
      case 'no_fragment_activity':
        alert(Lang.t('noFragmentActivity'));
        break;
      case 'NotAvailable':
        alert(Lang.t('securityCredentialsNotAvailable'));
        break;
      case 'NotEnrolled':
        alert(Lang.t('noBiometricsEnrolled'));
        break;
      case 'LockedOut':
        alert(Lang.t('lockedOutTemporarily'));
        break;
      case 'PermanentlyLockedOut':
        alert(Lang.t('lockedOutPermanently'));
        break;
      default:
        alert('${e.message}');
        break;
    }
    return {'authenticated': false};
  }
}
