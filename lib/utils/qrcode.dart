import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:login/utils/alert.dart';
import 'package:login/constants/locales.dart';

Future<Uint8List?> generateQrCode(String data) async {
  var apiEndpoints = [
    'https://api.qrserver.com/v1/create-qr-code/?data={data}&size=200x200',
    'https://api.2dcode.biz/v1/create-qr-code?data={data}&size=200x200&border=1',
  ];
  for (final api in apiEndpoints) {
    try {
      final url = api.replaceFirst('{data}', Uri.encodeComponent(data));
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        alert(Lang.t('apiRequestFail'));
      }
    } catch (e) {
      alert(Lang.t('apiRequestFail'));
    }
  }
  return null;
}
