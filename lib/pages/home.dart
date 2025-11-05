import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:remixicon/remixicon.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:mobile_device_identifier/mobile_device_identifier.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:local_auth/local_auth.dart';
import 'package:email_validator/email_validator.dart';
import 'package:auth_totp/auth_totp.dart';
import 'package:login/constants/package.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:app_links/app_links.dart';
import 'package:url_launcher/url_launcher.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  LocalAuthentication auth = LocalAuthentication();
  StreamSubscription<Uri>? link;
  String scheme = '';
  String requestId = '';
  bool fetch = false;
  List<Map<String, dynamic>> data = [];
  List<Map<String, dynamic>> full = [];
  String version = '';
  bool finger = false;
  String deviceId = '';
  String originalDeviceId = '';
  bool fingerSupported = false;
  TextEditingController email = TextEditingController();
  double screenWidth = 0;
  int expandedIndex = 0;

  @override
  void initState() {
    super.initState();
    initialization();
  }

  void initialization() async {
    FlutterNativeSplash.remove();
    await getVersion();
    await initDeviceId();
    await getFingerStatus();
    await loadData();
    initDeepLinks();
  }

  @override
  void dispose() {
    link?.cancel();
    super.dispose();
  }

  void initDeepLinks() {
    final appLinks = AppLinks();
    link = appLinks.uriLinkStream.listen((uri) {
      if (data.isNotEmpty) {
        showEmailChooseActionSheet(uri.queryParameters['url'].toString());
      } else {
        alert(Lang.t('emptyState'));
      }
      scheme = uri.queryParameters['callback'].toString();
      requestId = uri.queryParameters['request_id'].toString();
    });
  }

  void showEmailChooseActionSheet(String url) {
    actionSheetForChoose = TDActionSheet(
      context,
      visible: true,
      cancelText: Lang.t('cancel'),
      description: Lang.t('choose'),
      items: data.map((item) {
        return TDActionSheetItem(label: item['email']);
      }).toList(),
      onSelected: (e, index) async {
        setState(() {
          expandedIndex = index;
        });
        actionSheetForChoose?.close();
        await Future.delayed(Duration(milliseconds: 200));
        beforeScan(api: url);
      },
    );
  }

  Future<void> getVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    version = packageInfo.version;
  }

  Future<void> initDeviceId() async {
    var deviceIdValue = await option('device_id');
    if (deviceIdValue.isNotEmpty) {
      deviceId = obfuscateId(deviceIdValue);
      originalDeviceId = deviceIdValue;
    } else {
      String id;
      try {
        id = await MobileDeviceIdentifier().getDeviceId() ?? 'error';
      } on PlatformException {
        id = 'error';
      }
      deviceId = obfuscateId(id);
      originalDeviceId = id;
      await option('device_id', value: id);
    }
  }

  Future<void> getFingerStatus() async {
    auth.isDeviceSupported().then(
          (bool isSupported) => setState(() => fingerSupported = isSupported),
    );
    var fingerValue = await option('finger');
    if (fingerValue.isNotEmpty) {
      setState(() {
        finger = true;
      });
    }
  }

  void add() {
    email.text = '';
    showGeneralDialog(
      context: context,
      pageBuilder:
          (
          BuildContext buildContext,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          ) {
        return TDInputDialog(
          textEditingController: email,
          title: Lang.t('addTitle'),
          content: Lang.t('addTip'),
          hintText: Lang.t('addHintText'),
          leftBtn: TDDialogButtonOptions(
            title: Lang.t('cancel'),
            action: () {
              Navigator.pop(context);
            },
          ),
          rightBtn: TDDialogButtonOptions(
            title: Lang.t('confirm'),
            action: () {
              if (email.text.isEmpty) {
                return;
              }
              bool isValid = EmailValidator.validate(email.text);
              if (!isValid) {
                alert(Lang.t('invalidEmail'));
                return;
              }
              Navigator.pop(context);
              addEmailSuccess();
            },
          ),
        );
      },
    );
  }

  void addEmailSuccess() async {
    var value = email.text.trim();
    var db = await sqlite();
    var list = await db.rawQuery('SELECT * FROM emails WHERE email = ?', [
      value,
    ]);
    if (list.isNotEmpty) {
      await db.close();
      alert(Lang.t('emailExists'));
    } else {
      String secret = AuthTOTP.createSecret(
        length: 16,
        secretKeyStyle: SecretKeyStyle.upperLowerCase,
      );
      await db.insert('emails', {'email': value, 'secret': secret});
      await db.close();
      alert(
        Lang.t('addSuccess'),
        onTap: () {
          loadData();
        },
      );
    }
  }

  Future<void> loadData({bool reset = false}) async {
    var emailsWithAccounts = await getSqliteData();
    setState(() {
      data = emailsWithAccounts;
      full = emailsWithAccounts;
      fetch = true;
    });
    if (reset) {
      setState(() {
        expandedIndex = 0;
      });
    }
  }

  void verify() async {
    var result = await authenticateWithBiometrics(update: true);
    if (result['authenticated'] == true) {
      setState(() {
        finger = result['verified']!;
      });
    } else {
      setState(() {});
    }
  }

  Widget drawer() {
    var items = [
      item(
        icon: Remix.pass_valid_line,
        id: 'id',
        right: deviceId,
        arrow: false,
      ),
      item(
        icon: Remix.translate_2,
        id: 'translate',
        right: Lang.name.getString(context),
      ),
      item(icon: Remix.mobile_download_line, id: 'dataTransfer'),
      item(icon: Remix.information_line, id: 'about', right: version),
    ];
    if (fingerSupported) {
      items.insert(
        2,
        item(
          icon: Remix.fingerprint_line,
          id: 'finger',
          right: 'switch',
          finger: finger,
          onChanged: verify,
        ),
      );
    }
    return TDDrawerWidget(
      title: Lang.t('settings'),
      items: items,
      onItemClick: (index, item) {
        if (item.title == 'about') {
          openAboutDrawer();
        }
        if (item.title == 'dataTransfer') {
          dataTransfer();
        }
        if (item.title == 'translate') {
          openLanguageSettingDrawer();
        }
      },
    );
  }

  Widget main() {
    return Column(
      children: [
        TDSearchBar(
          placeHolder: Lang.t('placeHolder'),
          inputAction: TextInputAction.search,
          onClearClick: (String text) {
            setState(() {
              data = full;
              expandedIndex = 0;
            });
            return false;
          },
          onSubmitted: (String text) {
            if (text.trim().isEmpty) {
              return;
            }
            var filteredData = filterSqliteData(full, text);
            if (filteredData.isNotEmpty) {
              setState(() {
                data = filteredData;
                expandedIndex = 0;
              });
            } else {
              alert(Lang.t('noResults'));
            }
          },
          onTapOutside: (event) {
            FocusScope.of(context).unfocus();
          },
        ),
        Expanded(
          child: ListView.builder(
            itemBuilder: (context, index) {
              return MyListTile(
                key: Key('$index'),
                item: data[index],
                width: screenWidth,
                isExpanded: expandedIndex == index,
                onTap: () {
                  setState(() {
                    expandedIndex = index;
                  });
                },
                onRemove: () async {
                  if (!finger) {
                    alert(
                      Lang.t('enableFingerprintFirst'),
                      onTap: () {
                        scaffoldKey.currentState?.openEndDrawer();
                      },
                    );
                    return;
                  }
                  var item = data[index];
                  confirm(
                    item['email'],
                    Lang.t('delete'),
                    content: Lang.t('confirmDelete'),
                    onTap: () async {
                      var result = await authenticateWithBiometrics();
                      if (result['authenticated'] == false) {
                        return;
                      }
                      await deleteEmail(item['id']);
                      loadData();
                    },
                  );
                },
              );
            },
            itemCount: data.length,
          ),
        ),
      ],
    );
  }

  void dataTransfer() async {
    actionSheet = TDActionSheet(
      context,
      visible: true,
      cancelText: Lang.t('cancel'),
      description: Lang.t('sameWifi'),
      items: [
        TDActionSheetItem(label: Lang.t('newDevice')),
        TDActionSheetItem(label: Lang.t('olDevice')),
      ],
      onSelected: (e, index) async {
        actionSheet?.close();
        await Future.delayed(Duration(milliseconds: 200));
        if (index == 0) {
          confirm(
            Lang.t('dangerousOperation'),
            Lang.t('scan'),
            onTap: () async {
              var result = await authenticateWithBiometrics();
              if (result['authenticated'] == false) {
                return;
              }
              importData();
            },
          );
        }
        if (index == 1) {
          var result = await authenticateWithBiometrics();
          if (result['authenticated'] == false) {
            return;
          }
          showLoading();
          await createWebServer();
          hideLoading();
        }
      },
    );
  }

  void importData() async {
    // 1. scan web server qrcode
    var url = await scan(context);
    if (url.isEmpty) {
      alert(Lang.t('qrScanEmpty'));
      return;
    }
    // 2. get old device json data
    showLoading();
    var response = await request(url, '');
    hideLoading();
    if (response['statusCode'] == 401) {
      return;
    }
    // 3. recover data
    await recoverSqliteData(response['data']);
    await initDeviceId();
    loadData(reset: true);
  }

  void beforeScan({String api = ''}) async {
    if (data.isEmpty) {
      alert(Lang.t('emptyState'));
      return;
    }
    var currentEmail = data[expandedIndex]['email'];
    if (!finger) {
      alert(
        Lang.t('enableFingerprintFirst'),
        onTap: () {
          scaffoldKey.currentState?.openEndDrawer();
        },
      );
      return;
    }
    confirm(
      currentEmail,
      Lang.t(api.isNotEmpty ? 'confirm' : 'scan'),
      onTap: () async {
        var result = await authenticateWithBiometrics();
        if (result['authenticated'] == false) {
          return;
        }
        scanQrCode(currentEmail, api: api);
      },
    );
  }

  void scanQrCode(String title, {String api = ''}) async {
    var url = api;
    if (url.isEmpty) {
      // 1. scan qrcode
      url = await scan(context);
      if (url.isEmpty) {
        alert(Lang.t('qrScanEmpty'));
        return;
      }
      var uri = Uri.parse(url);
      url = '${uri.scheme}://${uri.host}${uri.path}';
      requestId = uri.queryParameters['request_id'].toString();
    }
    // 2. get public key
    showLoading();
    var responsePublicKey = await request(
      url,
      '/get_public_key',
      headers: {'totp-requestId': requestId},
    );
    hideLoading();
    if (responsePublicKey['statusCode'] == 401) {
      return;
    }
    publicKey = responsePublicKey['data']['key'];
    // 3. submit email and device id
    var item = data[expandedIndex];
    var submitHeaders = {
      'totp-id': encrypt(originalDeviceId),
      'totp-email': encrypt(item['email']),
      'totp-requestId': requestId,
    };
    showLoading();
    var responseSubmit = await request(
      url,
      '/submit',
      isPost: true,
      headers: submitHeaders,
    );
    hideLoading();
    if (responseSubmit['statusCode'] == 401) {
      return;
    }
    if (responseSubmit['data']['error'].toString().isNotEmpty) {
      alert(responseSubmit['data']['error']);
      return;
    }
    // 4. confirm login
    confirm(
      title,
      Lang.t('confirmLogin'),
      onTap: () async {
        showLoading();
        var code = generatedTOTPCode(item['secret']);
        var verifyHeaders = {
          'totp-id': encrypt(originalDeviceId),
          'totp-code': encrypt(code),
          'totp-email': encrypt(item['email']),
          'totp-requestId': requestId,
        };
        var isSecret =
            responseSubmit['data']['secret'].toString().toLowerCase() == 'true';
        if (isSecret) {
          verifyHeaders.addAll({'totp-secret': encrypt(item['secret'])});
        }
        // 5. post totp code to verify login
        var responseVerify = await request(
          url,
          '/verify',
          isPost: true,
          headers: verifyHeaders,
        );
        hideLoading();
        if (responseVerify['statusCode'] == 401) {
          return;
        }
        if (responseVerify['data']['error'].toString().isNotEmpty) {
          alert(responseVerify['data']['error']);
          return;
        }
        // 6. login successful
        alert(
          Lang.t('loginSuccess'),
          onTap: () async {
            // 7. update recently data
            var name = responseSubmit['data']['name'].toString();
            var domain = responseSubmit['data']['domain'].toString();
            var uniqueId = responseSubmit['data']['unique_id'].toString();
            int timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
            var db = await sqlite();
            await db.transaction((txn) async {
              await txn.update(
                'emails',
                {'timestamp': timestamp},
                where: 'id = ?',
                whereArgs: [item['id']],
              );
              int count = await txn.update(
                'accounts',
                {'timestamp': timestamp, 'name': name, 'domain': domain},
                where: 'email_id = ? and unique_id = ?',
                whereArgs: [item['id'], uniqueId],
              );
              if (count == 0) {
                await txn.insert('accounts', {
                  'email_id': item['id'],
                  'unique_id': uniqueId,
                  'name': name,
                  'domain': domain,
                  'timestamp': timestamp,
                });
              }
            });
            await db.close();
            await loadData(reset: true);
            if (api.isNotEmpty && scheme.isNotEmpty) {
              var uri = Uri.parse(scheme);
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
        );
      },
    );
  }

  void showLoading() {
    TDToast.showLoadingWithoutText(context: context);
  }

  void hideLoading() {
    TDToast.dismissLoading();
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        backgroundColor: TDTheme.of(context).brandColor7,
        title: Text('FastTOTP', style: TextStyle(color: Colors.white)),
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Remix.add_circle_fill),
            color: Colors.white,
            onPressed: add,
          ),
          IconButton(
            icon: const Icon(Remix.settings_3_fill),
            color: Colors.white,
            onPressed: () {
              scaffoldKey.currentState?.openEndDrawer();
            },
          ),
        ],
      ),
      endDrawer: drawer(),
      body: fetch
          ? (data.isNotEmpty
          ? main()
          : TDEmpty(
        type: TDEmptyType.plain,
        emptyText: Lang.t('emptyState'),
        emptyTextColor: TDTheme.of(context).grayColor7,
        image: Icon(
          Remix.folder_open_fill,
          size: 80,
          color: TDTheme.of(context).grayColor6,
        ),
      ))
          : Center(
        child: TDLoading(
          size: TDLoadingSize.large,
          icon: TDLoadingIcon.circle,
        ),
      ),
      floatingActionButton: data.isNotEmpty
          ? FloatingActionButton(
        onPressed: beforeScan,
        backgroundColor: TDTheme.of(context).brandColor7,
        child: const Icon(Remix.qr_scan_fill, color: Colors.white),
      )
          : Container(),
    );
  }
}
