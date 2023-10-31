import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:schueler_portal/api/api_client.dart';
import 'package:schueler_portal/api/request_models/base_request.dart';
import 'package:schueler_portal/data_loader.dart';
import 'package:schueler_portal/main.dart';

import '../api/response_models/api/user.dart';

class UserLogin {
  static Map<String, String> _userData = {};
  static const _secureStorage = FlutterSecureStorage();
  static User? user;

  static Future<void> updateLogin(BaseRequest req) async {
    _userData["email"] = req.email;
    _userData["password"] = req.password;
    _userData["institution"] = req.schulkuerzel;
    ApiClient.updateCredentials(req);
    DataLoader.cancelAndReset();
    DataLoader.cacheData();
    await save();
    user = (await DataLoader.getUser()).data;
  }

  static Future<void> save() async {
    for (String key in _userData.keys) {
      await _secureStorage.write(key: key, value: _userData[key]);
    }
  }

  static Future<BaseRequest?> load() async {
    // Returns null if data is missing
    // Should only be called once on app start

    _userData = await _secureStorage.readAll();

    if (!_userData.containsKey("email") ||
        !_userData.containsKey("password") ||
        !_userData.containsKey("institution")) {
      return null;
    }

    return BaseRequest(
      email: _userData["email"]!,
      password: _userData["password"]!,
      schulkuerzel: _userData["institution"]!,
    );
  }
}

class UserLoginWidget extends StatelessWidget {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final institutionController = TextEditingController();
  final MyAppState myAppState;

  UserLoginWidget({super.key, required this.myAppState});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login"),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          children: [
            const Text("Email"),
            TextField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Email",
              ),
              controller: emailController,
            ),
            const Text("Passwort"),
            TextField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Passwort",
              ),
              obscureText: true,
              enableSuggestions: false,
              autocorrect: false,
              controller: passwordController,
            ),
            const Text("Schulkürzel"),
            TextField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Schulkürzel",
              ),
              controller: institutionController,
            ),
            ElevatedButton(
              onPressed: () async {
                BaseRequest req = BaseRequest(
                  email: emailController.text.trim(),
                  password: passwordController.text.trim(),
                  schulkuerzel: institutionController.text.trim(),
                );

                ApiResponse<bool> validationResp =
                    await ApiClient.validateLogin(req);

                if (validationResp.statusCode == 200) {
                  if (validationResp.data!) {
                    myAppState.setLogin(true);
                    UserLogin.updateLogin(req);
                  } else {
                    Fluttertoast.showToast(msg: "Invalid login data");
                  }
                } else {
                  Fluttertoast.showToast(
                      msg: "Failed to login: ${validationResp.statusCode}");
                }
              },
              child: const Text("Login"),
            ),
          ],
        ),
      ),
    );
  }
}
