import 'package:flutter/material.dart';

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext c) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'RUDRA SURVEYOR',
    home: Scaffold(
      appBar: AppBar(
        title: const Text('RUDRA SURVEYOR'),
        centerTitle: true,
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: [
          _b('જમીન માપણી', Icons.landscape),
          _b('GPS માપણી', Icons.location_on),
          _b('Unit Conversion', Icons.swap_horiz),
          _b('Area Calculator', Icons.calculate),
        ],
      ),
    ),
  );

  static Widget _b(String t, IconData i) => Card(
    child: InkWell(
      onTap: () {},
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(i, size: 45),
            const SizedBox(height: 8),
            Text(t, textAlign: TextAlign.center),
          ],
        ),
      ),
    ),
  );
}
