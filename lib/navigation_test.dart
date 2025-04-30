import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

final logger = Logger();

void main() {
  runApp(NavigationTestApp());
}

class NavigationTestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test de Navigation',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => HomeScreen(),
        '/second': (context) => SecondScreen(),
        '/third': (context) => ThirdScreen(),
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Écran d\'accueil'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Test de Navigation',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                logger.d('Navigation vers /second');
                Navigator.of(context).pushNamed('/second');
              },
              child: Text('Aller à l\'écran 2'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                logger.d('Navigation vers /third');
                Navigator.of(context).pushNamed('/third');
              },
              child: Text('Aller à l\'écran 3'),
            ),
          ],
        ),
      ),
    );
  }
}

class SecondScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Écran 2'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Écran 2',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                logger.d('Retour à l\'écran d\'accueil');
                Navigator.of(context).pop();
              },
              child: Text('Retour'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                logger.d('Navigation vers /third');
                Navigator.of(context).pushNamed('/third');
              },
              child: Text('Aller à l\'écran 3'),
            ),
          ],
        ),
      ),
    );
  }
}

class ThirdScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Écran 3'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Écran 3',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                logger.d('Retour à l\'écran précédent');
                Navigator.of(context).pop();
              },
              child: Text('Retour'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                logger.d('Retour à l\'écran d\'accueil');
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: Text('Retour à l\'accueil'),
            ),
          ],
        ),
      ),
    );
  }
}
