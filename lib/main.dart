import 'package:flutter/material.dart';
import 'package:schueler_portal/api/request_models/base_request.dart';
import 'package:schueler_portal/chats.dart';
import 'package:schueler_portal/data_loader.dart';
import 'package:schueler_portal/home.dart';
import 'package:schueler_portal/homework.dart';
import 'package:schueler_portal/stundenplan.dart';
import 'package:schueler_portal/api_client.dart';
import 'package:schueler_portal/user_login.dart';

import 'api/response_models/api/chat.dart';
import 'my_future_builder.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  BaseRequest? loadedLogin = await UserLogin.load();

  if (loadedLogin == null) {
    runApp(const MyApp(openLoginPage: true));
    return;
  }

  ApiClient.updateCredentials(loadedLogin);
  DataLoader.cacheData();
  DataLoader.getUser().then((value) => UserLogin.user = value.data!);

  runApp(const MyApp(openLoginPage: false));
}

class MyApp extends StatefulWidget {
  final bool openLoginPage;

  const MyApp({Key? key, required this.openLoginPage}) : super(key: key);

  @override
  State<StatefulWidget> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  late bool _loginSuccessful;

  @override
  void initState() {
    super.initState();
    _loginSuccessful = !widget.openLoginPage;
    if (!widget.openLoginPage) _initLogin();
  }

  setLogin(bool success) {
    setState(() {
      _loginSuccessful = success;
    });
  }

  Future<void> _initLogin() async {
    var loginReq = ApiClient.baseRequest;

    final result = await ApiClient.validateLogin(loginReq);

    if (result.statusCode != 200 || result.data != true) {
      setLogin(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Schüler Portal',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.redAccent,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.redAccent,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: _loginSuccessful
          ? const MyHomePage(title: 'Home Page')
          : UserLoginWidget(myAppState: this), // Placeholder widget
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        selectedIndex: currentPageIndex,
        destinations: const <Widget>[
          NavigationDestination(
            selectedIcon: Icon(Icons.home),
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.edit),
            icon: Icon(Icons.edit_outlined),
            label: 'Hausaufgaben',
          ),
          ChatsNavigationDestination(),
          NavigationDestination(
            selectedIcon: Icon(Icons.table_chart),
            icon: Icon(Icons.table_chart_outlined),
            label: 'Stundenplan',
          ),
        ],
      ),
      body: <Widget>[
        const HomeWidget(),
        const HomeworkWidget(),
        const ChatsWidget(),
        const StundenplanContainer(),
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

  int _countUnreadChats(ApiResponse<List<Chat>> chatResp) {
    if (chatResp.statusCode != 200) return -1;
    return chatResp.data!
        .where((element) => element.unreadMessagesCount > 0)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    return MyFutureBuilder(
      future: DataLoader.getChats(),
      loadingIndicator: const NavigationDestination(
        selectedIcon: Badge(
            label: SizedBox.square(
              dimension: 5,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 1.5,
              ),
            ),
            child: Icon(Icons.chat_bubble)),
        icon: Badge(
          label: SizedBox.square(
            dimension: 5,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 1.5,
            ),
          ),
          child: Icon(Icons.chat_bubble_outline),
        ),
        label: 'Chats',
      ),
      customBuilder: (context, snapshot) {
        _unreadChats ??= _countUnreadChats(snapshot.data!);

        if (_unreadChats! < 1) {
          const NavigationDestination(
            selectedIcon: Icon(Icons.chat_bubble),
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chats',
          );
        }

        return NavigationDestination(
          selectedIcon: Badge(
            label: Text(_unreadChats.toString()),
            child: const Icon(Icons.chat_bubble),
          ),
          icon: Badge(
            label: Text(_unreadChats.toString()),
            child: const Icon(Icons.chat_bubble_outline),
          ),
          label: 'Chats',
        );
      },
    );
  }
}
