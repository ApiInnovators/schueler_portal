import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class UserLoginWidget extends StatefulWidget {
  final MyAppState? appState;

  UserLoginWidget({super.key, this.appState});

  @override
  State<UserLoginWidget> createState() => _UserLoginWidgetState();
}

class _UserLoginWidgetState extends State<UserLoginWidget> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final institutionController = TextEditingController(
    text: UserLogin.login?.schulkuerzel,
  );
  bool showPassword = false;
  bool isLoading = false;

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
                  decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: "Passwort",
                      suffixIcon: IconButton(
                          onPressed: () =>
                              setState(() => showPassword = !showPassword),
                          icon: Icon(
                            showPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ))),
                  obscureText: !showPassword,
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
                  autofillHints: const [AutofillHints.organizationName],
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          LoginData login = LoginData(
                            email: emailController.text.trim(),
                            password: passwordController.text.trim(),
                            schulkuerzel: institutionController.text.trim(),
                          );

                          setState(() => isLoading = true);
                          final authenticationResp =
                              await ApiClient.authenticate(login, true);
                          setState(() => isLoading = false);

                          if (authenticationResp.statusCode == 200) {
                            TextInput.finishAutofillContext();
                            UserLogin.update(
                              true,
                              newLogin: login,
                              newAccessToken: authenticationResp.data!,
                            );
                            if (widget.appState == null) {
                              navigatorKey.currentState?.pop();
                            } else {
                              widget.appState!.setLogin(true);
                            }
                          } else if (authenticationResp.statusCode == 422) {
                            Tools.quickSnackbar("Eingabe fehlerhaft");
                          } else {
                            Tools.quickSnackbar(
                                "Failed to login: ${authenticationResp.reasonPhrase}");
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(),
                        )
                      : const Text("Login"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
