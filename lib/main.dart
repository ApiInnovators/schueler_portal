import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:schueler_portal/api/api_client.dart';
import 'package:schueler_portal/data_loader.dart';
import 'package:schueler_portal/globals.dart';
import 'package:schueler_portal/pages/chats/chats.dart';
import 'package:schueler_portal/pages/home/home.dart';
import 'package:schueler_portal/pages/homework/homework.dart';
import 'package:schueler_portal/pages/timetable/stundenplan_page.dart';
import 'package:schueler_portal/pages/user_login.dart';
import 'package:schueler_portal/user_data.dart';

import 'api/response_models/api/chat.dart';
import 'custom_widgets/my_future_builder.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Future.wait([
    UserData.init(),
    LocallyCachedApiData.init(),
    UserLogin.load(),
  ]);

  if (UserLogin.login == null) {
    log("No saved user login, opening login page...");
    runApp(const MyApp());
    forceLogin();
    return;
  }

  if (UserLogin.accessToken == null) {
    log("No saved api access token, data will be cached later");
    runApp(const MyApp());
    return;
  }

  runApp(const MyApp());

  final validationResp = await ApiClient.hasValidToken();

  if (validationResp.statusCode == 200) {
    if (validationResp.data == true) {
      log("Saved access token is still valid (best case scenario)");
      DataLoader.cacheData();
      return;
    }

    return;
  }
}

class MyApp extends StatefulWidget {

  const MyApp({super.key});

  @override
  State<StatefulWidget> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  Color accentColor = UserData.getAccentColor();

  setAccentColor(Color color) => setState(() => accentColor = color);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Schüler Portal',
      scaffoldMessengerKey: snackbarKey,
      navigatorKey: navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: accentColor,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: accentColor,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: MyHomePage(myAppState: this),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final MyAppState myAppState;

  const MyHomePage({super.key, required this.myAppState});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        useLegacyColorScheme: false,
        onTap: (int index) => setState(() => currentPageIndex = index),
        currentIndex: currentPageIndex,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            activeIcon: Icon(Icons.home),
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            activeIcon: Icon(Icons.edit),
            icon: Icon(Icons.edit_outlined),
            label: 'Hausaufgaben',
          ),
          BottomNavigationBarItem(
            activeIcon: Icon(Icons.chat_bubble),
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            activeIcon: Icon(Icons.table_chart),
            icon: Icon(Icons.table_chart_outlined),
            label: 'Stundenplan',
          ),
        ],
      ),
      body: <Widget>[
        HomeWidget(myAppState: widget.myAppState),
        const HomeworkWidget(),
        const ChatsWidget(),
        const StundenplanPage(),
      ][currentPageIndex],
    );
  }
}

class ChatsNavigationDestination extends StatefulWidget {
  const ChatsNavigationDestination({super.key});

  @override
  State<ChatsNavigationDestination> createState() =>
      _ChatsNavigationDestinationState();
}

class _ChatsNavigationDestinationState
    extends State<ChatsNavigationDestination> {
  // TODO: update unreadChats when chats gets refreshed

  int? _unreadChats;
  static const defaultNavDest = NavigationDestination(
    selectedIcon: Icon(Icons.chat_bubble),
    icon: Icon(Icons.chat_bubble_outline),
    label: 'Chats',
  );

  int _countUnreadChats(List<Chat> chats) =>
      chats.where((element) => element.unreadMessagesCount > 0).length;

  @override
  Widget build(BuildContext context) {
    return ApiFutureBuilder(
      future: DataLoader.getChats(),
      errorWidget: defaultNavDest,
      failedRequestWidget: defaultNavDest,
      loadingIndicator: NavigationDestination(
        selectedIcon: Badge(
            backgroundColor: Theme.of(context).colorScheme.secondary,
            label: SizedBox.square(
              dimension: 5,
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.onSecondary,
                strokeWidth: 1.5,
              ),
            ),
            child: const Icon(Icons.chat_bubble)),
        icon: Badge(
          backgroundColor: Theme.of(context).colorScheme.secondary,
          label: SizedBox.square(
            dimension: 5,
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.onSecondary,
              strokeWidth: 1.5,
            ),
          ),
          child: const Icon(Icons.chat_bubble_outline),
        ),
        label: 'Chats',
      ),
      builder: (context, data) {
        _unreadChats ??= _countUnreadChats(data);

        if (_unreadChats! < 1) return defaultNavDest;

        return NavigationDestination(
          selectedIcon: Badge(
            backgroundColor: Theme.of(context).colorScheme.secondary,
            label: Text(
              _unreadChats.toString(),
              style:
                  TextStyle(color: Theme.of(context).colorScheme.onSecondary),
            ),
            child: const Icon(Icons.chat_bubble),
          ),
          icon: Badge(
            backgroundColor: Theme.of(context).colorScheme.secondary,
            label: Text(
              _unreadChats.toString(),
              style:
                  TextStyle(color: Theme.of(context).colorScheme.onSecondary),
            ),
            child: const Icon(Icons.chat_bubble_outline),
          ),
          label: 'Chats',
        );
      },
    );
  }
}
