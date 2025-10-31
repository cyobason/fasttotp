import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:login/constants/globals.dart';
import 'package:login/utils/alert.dart';
import 'package:login/constants/locales.dart';

Future<Map<String, dynamic>> request(
  String url,
  String command, {
  Map<String, String>? headers,
  bool isPost = false,
}) async {
  var uri = Uri.parse(url + command);
  try {
    http.Response response;
    if (isPost) {
      response = await http
          .get(uri, headers: headers)
          .timeout(Duration(milliseconds: connectTimeout));
    } else {
      response = await http
          .post(uri, headers: headers)
          .timeout(Duration(milliseconds: connectTimeout));
    }
    bool isSuccess = response.statusCode >= 200 && response.statusCode < 300;
    if (isSuccess) {
      dynamic data;
      try {
        data = json.decode(response.body);
      } catch (e) {
        data = response.body;
      }
      return {'statusCode': response.statusCode, 'data': data};
    }
  } catch (e) {
    // Request fail.
  }
  alert(Lang.t('apiRequestFail'));
  return {'statusCode': 401, 'data': {}};
}
