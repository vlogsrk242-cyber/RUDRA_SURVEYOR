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
        fontFamily: 'sans',
        colorSchemeSeed: Colors.blue,
      ),
      home: const Dashboard(),
    );
  }
}

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int selectedIndex = 0;

  void openPage(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f8fc),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'RUDRA SURVEYOR',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xff123b70),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              openPage(const SettingsPage());
            },
            icon: const Icon(
              Icons.settings_outlined,
              color: Color(0xff123b70),
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 20),
          child: Column(
            children: [

              // HEADER
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xff075ca8),
                      Color(0xff118ed0),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    Image.asset(
                      'assets/rudra_logo.jpg',
                      height: 125,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) {
                        return const Icon(
                          Icons.landscape,
                          size: 90,
                          color: Colors.white,
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'નમસ્તે!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'RUDRA SURVEYOR માં આપનું સ્વાગત છે.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // OP1 + OP2
              Row(
                children: [
                  Expanded(
                    child: SurveyCard(
                      op: 'OP1',
                      title: 'જમીન માપણી નોંધ',
                      description:
                          'માલિકની માહિતી, ગામ, તાલુકો, મોબાઇલ, સર્વે નંબર, તારીખ, કુલ પેમેન્ટ અને PDF રિપોર્ટ.',
                      icon: Icons.edit_document,
                      iconColor: Colors.blue,
                      onTap: () {
                        openPage(const LandEntryPage());
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SurveyCard(
                      op: 'OP2',
                      title: 'GPS માપણી',
                      description:
                          'GPS દ્વારા જમીનની Boundary માપો, Area અને Distance ગણો, Map પર જુઓ.',
                      icon: Icons.location_on,
                      iconColor: Colors.green,
                      onTap: () {
                        openPage(const GpsPage());
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // OP3 + OP4
              Row(
                children: [
                  Expanded(
                    child: SurveyCard(
                      op: 'OP3',
                      title: 'Unit Conversion',
                      description:
                          'ચો.મી., ચો.ફૂટ, ગુંઠા, એકર, હેક્ટર વગેરેમાં રૂપાંતર.',
                      icon: Icons.swap_horiz,
                      iconColor: Colors.deepPurple,
                      onTap: () {
                        openPage(const UnitPage());
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SurveyCard(
                      op: 'OP4',
                      title: 'Area Calculator',
                      description:
                          'લંબચોરસ, ચોરસ, ત્રિકોણ અને અન્ય આકારોની જમીનનું ક્ષેત્રફળ ગણો.',
                      icon: Icons.calculate,
                      iconColor: Colors.orange,
                      onTap: () {
                        openPage(const AreaPage());
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // SAVED HISTORY
              GestureDetector(
                onTap: () {
                  openPage(const HistoryPage());
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xffe5f2ff),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 32,
                            backgroundColor: Color(0xff1476c9),
                            child: Icon(
                              Icons.history,
                              color: Colors.white,
                              size: 38,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Saved History',
                                  style: TextStyle(
                                    color: Color(0xff123b70),
                                    fontSize: 23,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'આગળની બધી નોંધો, માપણી અને પેમેન્ટ અહીંથી જુઓ અને ફરી ખોલો.',
                                  style: TextStyle(
                                    color: Color(0xff23486c),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            color: Color(0xff1476c9),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      Row(
                        children: [
                          HistoryBox(
                            icon: Icons.description,
                            title: 'કુલ નોંધો',
                            value: '12',
                          ),
                          const SizedBox(width: 8),
                          HistoryBox(
                            icon: Icons.location_on,
                            title: 'કુલ માપણી',
                            value: '8',
                          ),
                          const SizedBox(width: 8),
                          HistoryBox(
                            icon: Icons.currency_rupee,
                            title: 'કુલ પેમેન્ટ',
                            value: '₹1,85,000',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // BOTTOM NAVIGATION
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        backgroundColor: Colors.white,
        onDestinationSelected: (index) {
          setState(() {
            selectedIndex = index;
          });

          if (index == 1) {
            openPage(const HistoryPage());
          } else if (index == 2) {
            openPage(const MapPage());
          } else if (index == 3) {
            openPage(const ProfilePage());
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}


// --------------------------------------------------
// SURVEY CARD
// --------------------------------------------------

class SurveyCard extends StatelessWidget {
  final String op;
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const SurveyCard({
    super.key,
    required this.op,
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        height: 315,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              blurRadius: 7,
              spreadRadius: 1,
              offset: Offset(0, 3),
              color: Color(0x22000000),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: iconColor,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Text(
                op,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),

            const SizedBox(height: 15),

            Center(
              child: Icon(
                icon,
                size: 68,
                color: iconColor,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              title,
              style: TextStyle(
                color: const Color(0xff123b70),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: Text(
                description,
                style: const TextStyle(
                  color: Color(0xff23486c),
                  fontSize: 14,
                  height: 1.35,
                ),
              ),
            ),

            Align(
              alignment: Alignment.bottomRight,
              child: CircleAvatar(
                radius: 22,
                backgroundColor: iconColor,
                child: const Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// --------------------------------------------------
// HISTORY BOX
// --------------------------------------------------

class HistoryBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const HistoryBox({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: const Color(0xff1476c9),
              size: 25,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xff123b70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// --------------------------------------------------
// PAGES
// --------------------------------------------------

class LandEntryPage extends StatelessWidget {
  const LandEntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ToolPage(
      title: 'જમીન માપણી નોંધ',
      icon: Icons.edit_document,
      description:
          'માલિકની માહિતી, ગામ, તાલુકો, મોબાઇલ, સર્વે નંબર, તારીખ અને પેમેન્ટની નોંધ કરો.',
    );
  }
}

class GpsPage extends StatelessWidget {
  const GpsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ToolPage(
      title: 'GPS માપણી',
      icon: Icons.location_on,
      description:
          'GPS Location, Boundary, Distance અને Area માપવા માટેનું Survey Tool.',
    );
  }
}

class UnitPage extends StatelessWidget {
  const UnitPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ToolPage(
      title: 'Unit Conversion',
      icon: Icons.swap_horiz,
      description:
          'ચોરસ ફૂટ, ચોરસ મીટર, ગુંઠા, એકર અને હેક્ટર જેવા એકમોનું રૂપાંતર.',
    );
  }
}

class AreaPage extends StatelessWidget {
  const AreaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ToolPage(
      title: 'Area Calculator',
      icon: Icons.calculate,
      description:
          'લંબચોરસ, ચોરસ, ત્રિકોણ અને અન્ય આકારોનું ક્ષેત્રફળ ગણવા માટેનું Calculator.',
    );
  }
}

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ToolPage(
      title: 'Saved History',
      icon: Icons.history,
      description:
          'અગાઉની જમીન માપણી, નોંધો અને પેમેન્ટની માહિતી અહીંથી જોઈ શકાય છે.',
    );
  }
}

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ToolPage(
      title: 'Survey Map',
      icon: Icons.map,
      description:
          'GPS Survey અને જમીનની Boundary જોવા માટેનું Map section.',
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ToolPage(
      title: 'Profile',
      icon: Icons.person,
      description:
          'RUDRA SURVEYOR Professional Surveyor Profile.',
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ToolPage(
      title: 'Settings',
      icon: Icons.settings,
      description:
          'Application settings અને preferences અહીંથી મેનેજ કરો.',
    );
  }
}


// --------------------------------------------------
// COMMON PAGE
// --------------------------------------------------

class ToolPage extends StatelessWidget {
  final String title;
  final IconData icon;
  final String description;

  const ToolPage({
    super.key,
    required this.title,
    required this.icon,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 100,
                color: const Color(0xff1476c9),
              ),
              const SizedBox(height: 25),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff123b70),
                ),
              ),
              const SizedBox(height: 15),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  height: 1.5,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 30),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('પાછા Dashboard પર'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
