import 'package:shared_preferences/shared_preferences.dart';

Future<String> option(String name, {String value = '', bool remove = false}) async {
  var prefs = await SharedPreferences.getInstance();
  if (remove){
    await prefs.remove(name);
    return '';
  }
  if (value.isNotEmpty) {
    await prefs.setString(name, value);
    return value;
  }
  return prefs.getString(name) ?? '';
}
