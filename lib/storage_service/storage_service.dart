
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService{

  static final FlutterSecureStorage secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true
    ),
  );

  static const String passKey = 'password';

  static Future<String?> loadPassword()async{
    return await secureStorage.read(key: passKey);
  }

  static Future savePassword(String password)async{
    await secureStorage.write(key: passKey, value: password);
  }

  static Future<bool> hasPass()async{
    return await secureStorage.read(key: passKey)!=null;
  }

  static Future deletePass()async{
    await secureStorage.delete(key: passKey);
  }
}