import 'package:flutter/material.dart';
import 'package:task2/screen/welcome.dart';
import 'package:task2/screen/dashboard.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Task2',
      themeMode: ThemeMode.system,
      initialRoute: '/welcome',
      routes: {
        '/dashboard': (context) => const Dashboard(),
        '/welcome': (context) => const Welcome(),
      },
    );
  }
}
