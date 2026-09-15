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
        colorSchemeSeed: Colors.blue,
      ),
      home: const Dashboard(),
    );
  }
}

// =====================================================
// DASHBOARD
// =====================================================

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
      MaterialPageRoute(builder: (context) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f8fc),

      // ================= APP BAR =================

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'RUDRA SURVEYOR',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
            color: Color(0xff103d72),
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
              color: Color(0xff103d72),
            ),
          ),
        ],
      ),

      // ================= BODY =================

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 15),
          child: Column(
            children: [

              // ================= HEADER =================

              Container(
                width: double.infinity,
                height: 255,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xff005ba9),
                      Color(0xff1595d3),
                      Color(0xff1a78bd),
                    ],
                  ),
                ),
                child: Stack(
                  children: [

                    // Decorative circles
                    Positioned(
                      right: -40,
                      top: -30,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                    ),

                    Positioned(
                      left: -50,
                      bottom: -60,
                      child: Container(
                        width: 170,
                        height: 170,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.06),
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          Row(
                            children: [

                              Container(
                                width: 115,
                                height: 115,
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius:
                                      BorderRadius.circular(18),
                                ),
                                child: ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(14),
                                  child: Image.asset(
                                    'assets/rudra_logo.jpg',
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.landscape,
                                        size: 70,
                                        color: Colors.blue,
                                      );
                                    },
                                  ),
                                ),
                              ),

                              const SizedBox(width: 14),

                              const Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [

                                    Text(
                                      'RUDRA',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 34,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1,
                                      ),
                                    ),

                                    Text(
                                      'SURVEYOR',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    SizedBox(height: 5),

                                    Text(
                                      'DGPS • DRONE • TOTAL STATION',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                  ],
                                ),
                              ),
                            ],
                          ),

                          const Spacer(),

                          const Text(
                            'નમસ્તે!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const Text(
                            'RUDRA SURVEYOR માં આપનું સ્વાગત છે.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),

                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ================= OP1 + OP2 =================

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Expanded(
                    child: OperationCard(
                      op: 'OP1',
                      title: 'જમીન માપણી નોંધ',
                      description:
                          'માલિકની માહિતી, ગામ, તાલુકો, મોબાઇલ, સર્વે નંબર, તારીખ, કુલ પેમેન્ટ અને PDF રિપોર્ટ.',
                      icon: Icons.description_outlined,
                      iconColor: const Color(0xff1476c9),
                      backgroundColor: const Color(0xffe5f3ff),
                      onTap: () {
                        openPage(const LandEntryPage());
                      },
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: OperationCard(
                      op: 'OP2',
                      title: 'GPS માપણી',
                      description:
                          'GPS દ્વારા જમીનની Boundary માપો, Area અને Distance ગણો, Map પર જુઓ.',
                      icon: Icons.location_on,
                      iconColor: const Color(0xff16a34a),
                      backgroundColor: const Color(0xffe8f8e9),
                      onTap: () {
                        openPage(const GpsPage());
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // ================= OP3 + OP4 =================

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Expanded(
                    child: OperationCard(
                      op: 'OP3',
                      title: 'Unit Conversion',
                      description:
                          'ચો.મી., ચો.ફૂટ, ગુંઠા, એકર, હેક્ટર વગેરેમાં રૂપાંતર.',
                      icon: Icons.swap_horiz,
                      iconColor: const Color(0xff6531b9),
                      backgroundColor: const Color(0xfff0eaff),
                      onTap: () {
                        openPage(const UnitPage());
                      },
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: OperationCard(
                      op: 'OP4',
                      title: 'Area Calculator',
                      description:
                          'લંબચોરસ, ચોરસ, ત્રિકોણ અને અન્ય આકારોની જમીનનું ક્ષેત્રફળ ગણો.',
                      icon: Icons.calculate,
                      iconColor: const Color(0xffef6c00),
                      backgroundColor: const Color(0xfffff1df),
                      onTap: () {
                        openPage(const AreaPage());
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ================= SAVED HISTORY =================

              GestureDetector(
                onTap: () {
                  openPage(const HistoryPage());
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xffe4f2ff),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x18000000),
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [

                      Row(
                        children: [

                          const CircleAvatar(
                            radius: 31,
                            backgroundColor: Color(0xff1476c9),
                            child: Icon(
                              Icons.history,
                              color: Colors.white,
                              size: 37,
                            ),
                          ),

                          const SizedBox(width: 12),

                          const Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [

                                Text(
                                  'Saved History',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xff123b70),
                                  ),
                                ),

                                SizedBox(height: 3),

                                Text(
                                  'આગળની બધી નોંધો, માપણી અને પેમેન્ટ અહીંથી જુઓ.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xff345776),
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

                      const SizedBox(height: 14),

                      Row(
                        children: [

                          HistoryBox(
                            icon: Icons.description,
                            title: 'કુલ નોંધો',
                            value: '12',
                          ),

                          const SizedBox(width: 7),

                          HistoryBox(
                            icon: Icons.location_on,
                            title: 'કુલ માપણી',
                            value: '8',
                          ),

                          const SizedBox(width: 7),

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

      // ================= BOTTOM NAVIGATION =================

      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        selectedIndex: selectedIndex,

        onDestinationSelected: (index) {

          setState(() {
            selectedIndex = index;
          });

          if (index == 0) {
            // Home
          }

          if (index == 1) {
            openPage(const HistoryPage());
          }

          if (index == 2) {
            openPage(const MapPage());
          }

          if (index == 3) {
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


// =====================================================
// OPERATION CARD
// =====================================================

class OperationCard extends StatelessWidget {
  final String op;
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final VoidCallback onTap;

  const OperationCard({
    super.key,
    required this.op,
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 315,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x18000000),
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // OP NUMBER

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: iconColor,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Text(
                  op,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ICON

              Center(
                child: Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    icon,
                    size: 52,
                    color: iconColor,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // TITLE

              Text(
                title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff123b70),
                ),
              ),

              const SizedBox(height: 7),

              // DESCRIPTION

              Expanded(
                child: Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: Color(0xff23486c),
                  ),
                ),
              ),

              // ARROW

              Align(
                alignment: Alignment.bottomRight,
                child: CircleAvatar(
                  radius: 21,
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
      ),
    );
  }
}


// =====================================================
// HISTORY BOX
// =====================================================

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
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [

            Icon(
              icon,
              color: const Color(0xff1476c9),
              size: 24,
            ),

            const SizedBox(height: 3),

            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
            ),

            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
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


// =====================================================
// LAND ENTRY
// =====================================================

class LandEntryPage extends StatelessWidget {
  const LandEntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ToolPage(
      title: 'જમીન માપણી નોંધ',
      icon: Icons.description,
      description:
          'માલિકની માહિતી, ગામ, તાલુકો, મોબાઇલ, સર્વે નંબર, તારીખ, પેમેન્ટ અને PDF રિપોર્ટ.',
    );
  }
}


// =====================================================
// GPS
// =====================================================

class GpsPage extends StatelessWidget {
  const GpsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ToolPage(
      title: 'GPS માપણી',
      icon: Icons.location_on,
      description:
          'GPS દ્વારા જમીનની Boundary, Area અને Distance માપવા માટેનું Survey section.',
    );
  }
}


// =====================================================
// UNIT
// =====================================================

class UnitPage extends StatelessWidget {
  const UnitPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ToolPage(
      title: 'Unit Conversion',
      icon: Icons.swap_horiz,
      description:
          'ચોરસ ફૂટ, ચોરસ મીટર, ગુંઠા, એકર અને હેક્ટર જેવા જમીનના એકમોનું રૂપાંતર.',
    );
  }
}


// =====================================================
// AREA
// =====================================================

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


// =====================================================
// HISTORY
// =====================================================

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


// =====================================================
// MAP
// =====================================================

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


// =====================================================
// PROFILE
// =====================================================

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


// =====================================================
// SETTINGS
// =====================================================

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ToolPage(
      title: 'Settings',
      icon: Icons.settings,
      description:
          'RUDRA SURVEYOR application settings અહીંથી મેનેજ કરો.',
    );
  }
}


// =====================================================
// COMMON TOOL PAGE
// =====================================================

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
      backgroundColor: const Color(0xfff5f8fc),

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
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              Icon(
                icon,
                size: 95,
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
                  fontSize: 16,
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
