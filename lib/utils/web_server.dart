import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:login/utils/sqlite.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:path_provider/path_provider.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:login/constants/globals.dart';
import 'package:login/utils/qrcode.dart';
import 'package:login/utils/alert.dart';
import 'package:login/constants/locales.dart';
import 'package:login/utils/preferences.dart';

Future createWebServer() async {
  // 1. json file ready
  var jsonFile = await getFile();
  // 2. read sqlite data
  var emailsWithAccounts = await getSqliteData();
  var deviceIdValue = await option('device_id');
  await jsonFile.writeAsString(
    jsonEncode({'emails': emailsWithAccounts, 'device_id': deviceIdValue}),
  );
  // 3. get device wifi ip
  var info = NetworkInfo();
  var wifiIP = await info.getWifiIP();
  // 4. create web server
  closeWebServer(delete: false);
  webServer = await shelf_io.serve(
    (Request request) async {
      try {
        var jsonData = await jsonFile.readAsBytes();
        return Response.ok(
          jsonData,
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return Response.internalServerError(body: '$e');
      }
    },
    wifiIP!,
    8080,
  );
  webServer!.autoCompress = true;
  var url = 'http://${webServer!.address.host}:${webServer!.port}';
  // 5. show qrcode
  Uint8List? qrcode = await generateQrCode(url);
  if (qrcode == null) {
    alert(Lang.t('apiRequestFail'), onTap: closeWebServer);
    return;
  }
  showImageDialog(qrcode);
}

void closeWebServer({bool delete = true}) async {
  if (webServer != null) {
    await webServer!.close(force: true);
  }
  if (delete) {
    var jsonFile = await getFile();
    if (jsonFile.existsSync()) {
      await jsonFile.delete();
    }
  }
}

Future<File> getFile() async {
  var tempDir = await getTemporaryDirectory();
  var jsonPath = '${tempDir.path}/temp_data.json';
  return File(jsonPath);
}
