import 'package:flutter/material.dart';
import 'package:ai_barcode_scanner/ai_barcode_scanner.dart';
import 'package:login/constants/globals.dart';

Future<String> scan(BuildContext homeContext) async {
  var context = navigatorKey.currentContext;
  if (context == null) return '';
  var scanController = MobileScannerController(
    formats: [BarcodeFormat.qrCode],
  );
  var result = await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => AiBarcodeScanner(
        controller: scanController,
        galleryButtonType: GalleryButtonType.icon,
        validator: (value) {
          return true;
        },
        onDetect: (BarcodeCapture capture) {
          if (homeContext.mounted) {
            Navigator.pop(context, capture.barcodes.firstOrNull?.rawValue);
          }
        },
      ),
    ),
  );
  scanController.dispose();
  return result ?? '';
}
