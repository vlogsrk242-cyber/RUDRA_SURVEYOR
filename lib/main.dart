import 'package:flutter/material.dart';

void main() {
  runApp(const RudraSurveyor());
}

class RudraSurveyor extends StatelessWidget {
  const RudraSurveyor({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RUDRA SURVEYOR',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'RUDRA SURVEYOR',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Image.asset(
                'assets/rudra_logo.jpg',
                height: 150,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.landscape, size: 100),
              ),
              const SizedBox(height: 8),
              const Text(
                'Professional Land Surveyor',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Survey • Calculation • Measurement',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.05,
                children: [
                  _card(
                    context,
                    'જમીન માપણી',
                    Icons.landscape,
                    const LandPage(),
                  ),
                  _card(
                    context,
                    'GPS માપણી',
                    Icons.location_on,
                    const GpsPage(),
                  ),
                  _card(
                    context,
                    'Area Calculator',
                    Icons.calculate,
                    const AreaPage(),
                  ),
                  _card(
                    context,
                    'Unit Conversion',
                    Icons.swap_horiz,
                    const UnitPage(),
                  ),
                  _card(
                    context,
                    'માપ એકમો',
                    Icons.straighten,
                    const InfoPage(),
                  ),
                  _card(
                    context,
                    'Customer Care',
                    Icons.phone,
                    const CustomerPage(),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              const Text(
                'RUDRA SURVEYOR',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Text(
                'Professional Survey Information & Calculation',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _card(
    BuildContext context,
    String title,
    IconData icon,
    Widget page,
  ) {
    return Card(
      elevation: 5,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => page),
          );
        },
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 45),
                const SizedBox(height: 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LandPage extends StatelessWidget {
  const LandPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SimplePage(
      title: 'જમીન માપણી',
      icon: Icons.landscape,
      items: [
        'લંબાઈ × પહોળાઈથી વિસ્તાર',
        'ચોરસ ફૂટ ગણતરી',
        'ચોરસ મીટર ગણતરી',
        'ગુંઠા અને એકર માહિતી',
        'હેક્ટર માહિતી',
      ],
    );
  }
}

class GpsPage extends StatelessWidget {
  const GpsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SimplePage(
      title: 'GPS માપણી',
      icon: Icons.location_on,
      items: [
        'GPS Location',
        'Latitude અને Longitude',
        'Distance Measurement',
        'Location Information',
        'GPS Survey Tools',
      ],
    );
  }
}

class AreaPage extends StatelessWidget {
  const AreaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SimplePage(
      title: 'Area Calculator',
      icon: Icons.calculate,
      items: [
        'Rectangle Area',
        'Square Area',
        'Triangle Area',
        'Circle Area',
        'Custom Area Calculation',
      ],
    );
  }
}

class UnitPage extends StatelessWidget {
  const UnitPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SimplePage(
      title: 'Unit Conversion',
      icon: Icons.swap_horiz,
      items: [
        'Square Feet ↔ Square Meter',
        'Acre ↔ Guntha',
        'Hectare ↔ Acre',
        'Meter ↔ Feet',
        'Kilometer ↔ Meter',
      ],
    );
  }
}

class InfoPage extends StatelessWidget {
  const InfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SimplePage(
      title: 'માપ એકમોની માહિતી',
      icon: Icons.straighten,
      items: [
        '1 Acre = 40 Guntha',
        '1 Hectare ≈ 2.471 Acre',
        '1 Square Meter ≈ 10.764 Square Feet',
        '1 Meter ≈ 3.281 Feet',
        'જમીનના વિવિધ માપ એકમોની માહિતી',
      ],
    );
  }
}

class CustomerPage extends StatelessWidget {
  const CustomerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SimplePage(
      title: 'Customer Care',
      icon: Icons.phone,
      items: [
        'Customer Care',
        'Y.M. DHUNDHALAVA',
        'Phone: 8487847474',
        'Survey related support',
      ],
    );
  }
}

class SimplePage extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> items;

  const SimplePage({
    super.key,
    required this.title,
    required this.icon,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Icon(icon, size: 80),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          ...items.map(
            (item) => Card(
              child: ListTile(
                leading: Icon(icon),
                title: Text(
                  item,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
