import 'package:flutter/material.dart';
import 'package:schueler_portal/data_loader.dart';
import 'package:schueler_portal/home.dart';
import 'package:schueler_portal/secrets.dart';
import 'package:schueler_portal/stundenplan.dart';
import 'package:schueler_portal/api_client.dart';

ApiClient apiClient =
    ApiClient(Secrets.email, Secrets.password, Secrets.schulkuerzel);

void main() {
  runApp(const MyApp());
  DataLoader.fetchData();
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
          NavigationDestination(
            selectedIcon: Icon(Icons.chat_bubble),
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chats',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.table_chart),
            icon: Icon(Icons.table_chart_outlined),
            label: 'Stundenplan',
          ),
        ],
      ),
      body: <Widget>[
        const HomeWidget(),
        Container(
          alignment: Alignment.center,
          child: const Text('Hausaufgaben'),
        ),
        Container(
          alignment: Alignment.center,
          child: const Text('Chats'),
        ),
        const StundenplanContainer(),
      ][currentPageIndex],
    );
  }
}
