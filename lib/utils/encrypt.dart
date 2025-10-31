import 'package:login/constants/globals.dart';
import 'package:pointycastle/asymmetric/oaep.dart';
import 'package:pointycastle/asymmetric/rsa.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:pointycastle/pointycastle.dart'
    hide ASN1Parser, ASN1Sequence, ASN1BitString, ASN1Integer;
import 'package:asn1lib/asn1lib.dart';

String encrypt(String value) {
  var publicKeyValue = parsePublicKeyFromPem(publicKey!);
  var encrypted = rsaEncrypt(publicKeyValue, value);
  return base64Encode(encrypted);
}

Uint8List rsaEncrypt(RSAPublicKey publicKey, String plaintext) {
  var encryptor = OAEPEncoding(RSAEngine())
    ..init(true, PublicKeyParameter<RSAPublicKey>(publicKey));
  var plaintextBytes = utf8.encode(plaintext);
  return encryptor.process(Uint8List.fromList(plaintextBytes));
}

RSAPublicKey parsePublicKeyFromPem(String pem) {
  var publicKeyPEM = pem
      .replaceAll('-----BEGIN PUBLIC KEY-----', '')
      .replaceAll('-----END PUBLIC KEY-----', '')
      .replaceAll('\n', '');
  var publicKeyDER = base64Decode(publicKeyPEM);
  var asn1Parser = ASN1Parser(publicKeyDER);
  var topLevelSeq = asn1Parser.nextObject() as ASN1Sequence;
  var publicKeyBitString = topLevelSeq.elements[1] as ASN1BitString;
  var publicKeyAsn = ASN1Parser(publicKeyBitString.contentBytes());
  var publicKeySeq = publicKeyAsn.nextObject() as ASN1Sequence;
  var modulus = publicKeySeq.elements[0] as ASN1Integer;
  var exponent = publicKeySeq.elements[1] as ASN1Integer;
  return RSAPublicKey(modulus.valueAsBigInteger, exponent.valueAsBigInteger);
}
