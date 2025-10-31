import 'package:login/constants/package.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

Future<Database> sqlite() async {
  var databasesPath = await getDatabasesPath();
  var path = join(databasesPath, 'database');
  return await openDatabase(
    path,
    version: 1,
    onCreate: (Database db, int version) async {
      await db.execute(
        'CREATE TABLE emails '
        '('
        'id INTEGER PRIMARY KEY, '
        'email TEXT, '
        'secret TEXT, '
        'timestamp INTEGER DEFAULT 0 '
        ')',
      );
      await db.execute(
        'CREATE TABLE accounts '
        '('
        'id INTEGER PRIMARY KEY, '
        'email_id INTEGER DEFAULT 0, '
        'unique_id TEXT, '
        'name TEXT, '
        'domain TEXT, '
        'timestamp INTEGER DEFAULT 0 '
        ')',
      );
    },
  );
}

Future<List<Map<String, dynamic>>> getSqliteData() async {
  var db = await sqlite();
  var emails = await db.query('emails', orderBy: 'timestamp DESC, id DESC');
  var accounts = await db.query('accounts', orderBy: 'timestamp DESC, id DESC');
  Map<int, List<Map<String, dynamic>>> accountsByEmailId = {};
  for (var account in accounts) {
    var emailId = account['email_id'] as int;
    if (!accountsByEmailId.containsKey(emailId)) {
      accountsByEmailId[emailId] = [];
    }
    accountsByEmailId[emailId]!.add(account);
  }
  List<Map<String, dynamic>> emailsWithAccounts = emails.map((email) {
    var emailId = email['id'] as int;
    return {
      'id': email['id'],
      'email': email['email'],
      'secret': email['secret'],
      'timestamp': email['timestamp'],
      'accounts': accountsByEmailId[emailId] ?? [],
    };
  }).toList();
  await db.close();
  return emailsWithAccounts;
}

Future recoverSqliteData(Map<String, dynamic> data) async {
  var db = await sqlite();
  await db.delete('emails');
  await db.delete('accounts');
  await db.transaction((txn) async {
    for (var item in data['emails']) {
      txn.insert('emails', {
        'id': item['id'],
        'email': item['email'],
        'secret': item['secret'],
        'timestamp': item['timestamp'],
      });
      if (item['accounts'].length > 0) {
        for (var account in item['accounts']) {
          txn.insert('accounts', {
            'id': account['id'],
            'email_id': account['email_id'],
            'unique_id': account['unique_id'],
            'name': account['name'],
            'domain': account['domain'],
            'timestamp': account['timestamp'],
          });
        }
      }
    }
  });
  await db.close();
  await option('device_id', value: data['device_id']);
}

List<Map<String, dynamic>> filterSqliteData(
  List<Map<String, dynamic>> data,
  String text,
) {
  List<Map<String, dynamic>> filteredData = [];
  if (text.trim().isEmpty) {
    return filteredData;
  }
  for (var item in data) {
    var accounts = item['accounts'] as List<dynamic>?;
    if (accounts == null || accounts.isEmpty) {
      continue;
    }
    var matchedAccounts = accounts.where((account) {
      String? name = account['name']?.toString();
      return name != null && name.toLowerCase().contains(text.toLowerCase());
    }).toList();
    if (matchedAccounts.isNotEmpty) {
      var newItem = Map<String, dynamic>.from(item);
      newItem['accounts'] = matchedAccounts;
      filteredData.add(newItem);
    }
  }
  return filteredData;
}

Future<void> deleteEmail(int id) async {
  var db = await sqlite();
  await db.delete('emails', where: 'id = ?', whereArgs: [id]);
  await db.delete('accounts', where: 'email_id = ?', whereArgs: [id]);
  await db.close();
}

Future<void> deleteAccount(int id) async {
  var db = await sqlite();
  await db.delete('accounts', where: 'id = ?', whereArgs: [id]);
  await db.close();
}
