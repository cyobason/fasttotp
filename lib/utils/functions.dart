import 'package:auth_totp/auth_totp.dart';

String obfuscateId(String fullId) {
  var parts = fullId.split(':');
  if (parts.length > 6) {
    String firstThree = parts.sublist(0, 3).join(':');
    String lastThree = parts.sublist(parts.length - 3).join(':');
    return '$firstThree:***:$lastThree';
  }
  return fullId;
}

String generatedTOTPCode(String secret) {
  return AuthTOTP.generateTOTPCode(secretKey: secret, interval: 30);
}
