import 'package:flutter/material.dart';
import 'package:schueler_portal/api/response_models/api/user.dart';
import 'package:schueler_portal/chats.dart';
import 'package:schueler_portal/data_loader.dart';
import 'package:schueler_portal/home.dart';
import 'package:schueler_portal/homework.dart';
import 'package:schueler_portal/secrets.dart';
import 'package:schueler_portal/stundenplan.dart';
import 'package:schueler_portal/api_client.dart';

ApiClient apiClient =
    ApiClient(Secrets.email, Secrets.password, Secrets.schulkuerzel);
late User user;

Future<void> main() async {
  DataLoader.fetchData();
  user = await DataLoader.getUser();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Schüler Portal',
      theme: ThemeData(
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Home Page'),
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

  Widget chatsNavigationDestination() {
    NavigationDestination constructDestination(int unreadChats) {
      return NavigationDestination(
        selectedIcon: Badge(
          label: Text(unreadChats.toString()),
          child: const Icon(Icons.chat_bubble),
        ),
        icon: Badge(
          label: Text(unreadChats.toString()),
          child: const Icon(Icons.chat_bubble_outline),
        ),
        label: 'Chats',
      );
    }

    if (DataLoader.cachedChats != null) {
      int unreadChats = DataLoader.cachedChats!
          .where((element) => element.unreadMessagesCount > 0)
          .length;
      return constructDestination(unreadChats);
    }

    return FutureBuilder(
      future: DataLoader.getChats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          int unreadChats = snapshot.data!
              .where((element) => element.unreadMessagesCount > 0)
              .length;
          return constructDestination(unreadChats);
        }

        return const NavigationDestination(
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
        );
      },
    );
  }

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
        destinations: <Widget>[
          const NavigationDestination(
            selectedIcon: Icon(Icons.home),
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          const NavigationDestination(
            selectedIcon: Icon(Icons.edit),
            icon: Icon(Icons.edit_outlined),
            label: 'Hausaufgaben',
          ),
          chatsNavigationDestination(),
          const NavigationDestination(
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
