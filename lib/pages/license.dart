import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:login/constants/locales.dart';
import 'package:url_launcher/url_launcher.dart';

class MyLicensePage extends StatefulWidget {
  const MyLicensePage({super.key});

  @override
  LicenseState createState() => LicenseState();
}

class LicenseState extends State<MyLicensePage> {
  Map<String, Map> dependencies = {
    'ai_barcode_scanner': {'version': '7.0.0', 'license': 'Apache License 2.0'},
    'app_links': {'version': '6.4.1', 'license': 'Apache License 2.0'},
    'asn1lib': {'version': '1.6.5', 'license': 'BSD-2-Clause License'},
    'auth_totp': {'version': '1.0.1', 'license': 'MIT License'},
    'circular_countdown_timer': {'version': '0.2.4', 'license': 'MIT License'},
    'email_validator': {'version': '3.0.0', 'license': 'MIT License'},
    'flutter_html': {'version': '3.0.0', 'license': 'MIT License'},
    'flutter_localization': {
      'version': '0.3.3',
      'license': 'BSD-3-Clause License',
    },
    'flutter_native_splash': {'version': '2.4.7', 'license': 'MIT License'},
    'http': {'version': '1.5.0', 'license': 'BSD-3-Clause License'},
    'intl': {'version': '0.20.2', 'license': 'BSD-3-Clause License'},
    'local_auth': {'version': '2.3.0', 'license': 'BSD-3-Clause License'},
    'mobile_device_identifier': {
      'version': '0.0.3',
      'license': 'BSD-3-Clause License',
    },
    'network_info_plus': {
      'version': '7.0.0',
      'license': 'BSD-3-Clause License',
    },
    'package_info_plus': {
      'version': '9.0.0',
      'license': 'BSD-3-Clause License',
    },
    'path': {'version': '1.9.1', 'license': 'BSD-3-Clause License'},
    'path_provider': {'version': '2.1.5', 'license': 'BSD-3-Clause License'},
    'pointycastle': {'version': '4.0.0', 'license': 'MIT License'},
    'remixicon': {'version': '1.4.1', 'license': 'MIT License'},
    'shared_preferences': {
      'version': '2.5.3',
      'license': 'BSD-3-Clause License',
    },
    'shelf': {'version': '1.4.2', 'license': 'BSD-3-Clause License'},
    'sqflite': {'version': '2.4.2', 'license': 'BSD-2-Clause License'},
    'tdesign_flutter': {'version': '0.2.5', 'license': 'MIT License'},
    'url_launcher': {'version': '6.3.2', 'license': 'BSD-3-Clause License'},
  };
  List<Map>? items;

  void getDependencies() {
    var entries = dependencies.entries.map((entry) {
      var name = entry.key;
      var item = entry.value;
      return {
        'name': name,
        'license': item['license'],
        'version': item['version'],
        'url': 'https://pub.dev/packages/$name/license',
      };
    }).toList();
    setState(() {
      items = entries;
    });
  }

  @override
  void initState() {
    super.initState();
    getDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: TDTheme.of(context).brandColor7,
        title: Text(
          Lang.t('aboutLicense'),
          style: TextStyle(color: Colors.white),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: TDCellGroup(
          cells: items!.map((item) {
            return TDCell(
              titleWidget: Text(
                item['name'],
                style: TextStyle(
                  color: TDTheme.of(context).fontGyColor1,
                  fontSize: TDTheme.of(context).fontBodyLarge?.size ?? 16,
                  height: TDTheme.of(context).fontBodyLarge?.height ?? 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              note: item['version'],
              arrow: true,
              descriptionWidget: TDTag(item['license']),
              onClick: (_) {
                Uri url = Uri.parse(item['url']);
                launchUrl(url);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
