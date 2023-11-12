import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:schueler_portal/api/api_client.dart';
import 'package:schueler_portal/data_loader.dart';
import 'package:schueler_portal/globals.dart';

import '../main.dart';
import '../tools.dart';

class UserLogin {
  static const _secureStorage = FlutterSecureStorage();

  static String? accessToken;
  static LoginData? login;

  static Future<void> update(bool recacheData,
      {LoginData? newLogin, String? newAccessToken}) {
    if (newLogin != null) login = newLogin;
    if (newAccessToken != null) accessToken = newAccessToken;
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

void forceLogin() async {
  await Future.doWhile(() async {
    await Future.delayed(const Duration(milliseconds: 30));
    return navigatorKey.currentState == null;
  }).timeout(const Duration(seconds: 1));

  navigatorKey.currentState?.push(
    MaterialPageRoute(
      builder: (context) {
        return UserLoginWidget();
      },
    ),
  );
}

class UserLoginWidget extends StatelessWidget {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final institutionController = TextEditingController();
  final MyAppState? appState;

  UserLoginWidget({super.key, this.appState});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Login"),
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: AutofillGroup(
            child: Column(
              children: [
                const Text("Email"),
                TextField(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "Email",
                  ),
                  controller: emailController,
                  autofillHints: const [AutofillHints.email],
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
                  autofillHints: const [AutofillHints.password],
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

                    final authenticationResp =
                        await ApiClient.authenticate(login, true);

                    if (authenticationResp.statusCode == 200) {
                      UserLogin.update(
                        true,
                        newLogin: login,
                        newAccessToken: authenticationResp.data!,
                      );
                      if (appState == null) {
                        navigatorKey.currentState?.pop();
                      } else {
                        appState!.setLogin(true);
                      }
                    } else if (authenticationResp.statusCode == 422) {
                      Tools.quickSnackbar("Eingabe fehlerhaft");
                    } else {
                      Tools.quickSnackbar(
                          "Failed to login: ${authenticationResp.reasonPhrase}");
                    }
                  },
                  child: const Text("Login"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
