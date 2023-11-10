import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:schueler_portal/api/api_client.dart';
import 'package:schueler_portal/data_loader.dart';
import 'package:schueler_portal/main.dart';

import '../tools.dart';

class UserLogin {
  static const _secureStorage = FlutterSecureStorage();

  static String? accessToken;
  static LoginData? login;

  static Future<void> updateLogin(LoginData newLogin, String newAccessToken) {
    log("Updating login");
    login = newLogin;
    accessToken = newAccessToken;

    DataLoader.cancelAndReset();
    DataLoader.cacheData();
    return save();
  }

  static Future<void> save() async {
    log("Saved Login");
    if (accessToken != null) {
      await _secureStorage.write(key: "access_token", value: accessToken);
    }
    if (login != null) {
      await _secureStorage.write(key: "email", value: login!.email);
      await _secureStorage.write(key: "password", value: login!.password);
      await _secureStorage.write(
          key: "institution", value: login!.schulkuerzel);
    }
  }

  static Future<bool> load() async {
    // Returns true if data was loaded successfully
    final read = await _secureStorage.readAll();

    accessToken = read["access_token"];

    if (["email", "password", "institution"].any((e) => !read.containsKey(e))) {
      return false;
    }

    login = LoginData(
        email: read["email"]!,
        password: read["password"]!,
        schulkuerzel: read["institution"]!);

    return accessToken != null;
  }
}

class LoginData {
  final String email;
  final String password;
  final String schulkuerzel;

  LoginData(
      {required this.email,
      required this.password,
      required this.schulkuerzel});
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
                LoginData login = LoginData(
                  email: emailController.text.trim(),
                  password: passwordController.text.trim(),
                  schulkuerzel: institutionController.text.trim(),
                );

                final authenticationResp = await ApiClient.authenticate(login);

                if (authenticationResp.$1.statusCode == 200) {
                  myAppState.setLogin(true);
                  UserLogin.updateLogin(
                    login,
                    authenticationResp.$2["access_token"],
                  );
                } else {
                  Tools.quickSnackbar(
                      "Failed to login: ${authenticationResp.$1.reasonPhrase}");
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
