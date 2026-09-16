import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const RudraSurveyorApp());
}

class RudraSurveyorApp extends StatelessWidget {
  const RudraSurveyorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RUDRA SURVEYOR',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FB),
      ),
      home: const AuthGate(),
    );
  }
}

/* =========================================================
   ACCOUNT STORE
========================================================= */

class AccountStore {
  static const String accountsKey = 'rudra_accounts';
  static const String currentUserKey = 'rudra_current_user';

  static Future<List<Map<String, dynamic>>> accounts() async {
    final p = await SharedPreferences.getInstance();
    final list = p.getStringList(accountsKey) ?? [];

    return list.map<Map<String, dynamic>>((e) {
      try {
        return Map<String, dynamic>.from(jsonDecode(e) as Map);
      } catch (_) {
        return <String, dynamic>{};
      }
    }).where((e) => e.isNotEmpty).toList();
  }

  static Future<Map<String, dynamic>?> findAccount(
    String mobile,
  ) async {
    final list = await accounts();

    for (final account in list) {
      if (account['mobile']?.toString() == mobile) {
        return account;
      }
    }

    return null;
  }

  static Future<bool> createAccount({
    required String name,
    required String mobile,
    required String password,
    String? photoPath,
  }) async {
    final p = await SharedPreferences.getInstance();
    final list = p.getStringList(accountsKey) ?? [];

    for (final item in list) {
      try {
        final account =
            Map<String, dynamic>.from(jsonDecode(item) as Map);

        if (account['mobile']?.toString() == mobile) {
          return false;
        }
      } catch (_) {}
    }

    final account = {
      'name': name,
      'mobile': mobile,
      'password': password,
      'photoPath': photoPath ?? '',
      'createdAt': DateTime.now().toIso8601String(),
    };

    list.add(jsonEncode(account));

    await p.setStringList(accountsKey, list);
    await setCurrentUser(mobile);

    return true;
  }

  static Future<bool> login(
    String mobile,
    String password,
  ) async {
    final account = await findAccount(mobile);

    if (account == null) {
      return false;
    }

    if (account['password']?.toString() != password) {
      return false;
    }

    await setCurrentUser(mobile);

    return true;
  }

  static Future<void> setCurrentUser(
    String mobile,
  ) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(currentUserKey, mobile);
  }

  static Future<String?> currentUser() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(currentUserKey);
  }

  static Future<Map<String, dynamic>?> currentAccount() async {
    final mobile = await currentUser();

    if (mobile == null || mobile.isEmpty) {
      return null;
    }

    return findAccount(mobile);
  }

  static Future<void> logout() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(currentUserKey);
  }

  static Future<void> clearSession() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(currentUserKey);
  }
}

/* =========================================================
   ACCOUNT-WISE HISTORY STORE
========================================================= */

class HistoryStore {
  static const String recordsKey = 'land_records';
  static const String filesKey = 'saved_files';

  static Future<String> _recordsStorageKey() async {
    final mobile = await AccountStore.currentUser();

    if (mobile == null || mobile.isEmpty) {
      return recordsKey;
    }

    final safeMobile =
        mobile.replaceAll(RegExp(r'[^0-9]'), '');

    return '${recordsKey}_$safeMobile';
  }

  static Future<String> _filesStorageKey() async {
    final mobile = await AccountStore.currentUser();

    if (mobile == null || mobile.isEmpty) {
      return filesKey;
    }

    final safeMobile =
        mobile.replaceAll(RegExp(r'[^0-9]'), '');

    return '${filesKey}_$safeMobile';
  }

  static Future<List<Map<String, dynamic>>> records() async {
    final p = await SharedPreferences.getInstance();
    final key = await _recordsStorageKey();

    final list = p.getStringList(key) ?? [];

    return list.map<Map<String, dynamic>>((e) {
      try {
        return Map<String, dynamic>.from(
          jsonDecode(e) as Map,
        );
      } catch (_) {
        return <String, dynamic>{};
      }
    }).where((e) => e.isNotEmpty).toList();
  }

  static Future<void> addRecord(
    Map<String, dynamic> record,
  ) async {
    final p = await SharedPreferences.getInstance();
    final key = await _recordsStorageKey();

    final list = p.getStringList(key) ?? [];

    list.add(jsonEncode(record));

    await p.setStringList(key, list);
  }

  static Future<void> deleteRecord(
    int index,
  ) async {
    final p = await SharedPreferences.getInstance();
    final key = await _recordsStorageKey();

    final list = p.getStringList(key) ?? [];

    if (index >= 0 && index < list.length) {
      list.removeAt(index);
      await p.setStringList(key, list);
    }
  }

  static Future<void> addFile(
    Map<String, dynamic> file,
  ) async {
    final p = await SharedPreferences.getInstance();
    final key = await _filesStorageKey();

    final list = p.getStringList(key) ?? [];

    list.add(jsonEncode(file));

    await p.setStringList(key, list);
  }

  static Future<List<Map<String, dynamic>>> files() async {
    final p = await SharedPreferences.getInstance();
    final key = await _filesStorageKey();

    final list = p.getStringList(key) ?? [];

    return list.map<Map<String, dynamic>>((e) {
      try {
        return Map<String, dynamic>.from(
          jsonDecode(e) as Map,
        );
      } catch (_) {
        return <String, dynamic>{};
      }
    }).where((e) => e.isNotEmpty).toList();
  }

  static Future<void> deleteFile(
    int index,
  ) async {
    final p = await SharedPreferences.getInstance();
    final key = await _filesStorageKey();

    final list = p.getStringList(key) ?? [];

    if (index >= 0 && index < list.length) {
      try {
        final item = jsonDecode(list[index]);

        final path = item is Map
            ? item['path']?.toString()
            : null;

        if (path != null) {
          try {
            final f = File(path);

            if (await f.exists()) {
              await f.delete();
            }
          } catch (_) {}
        }
      } catch (_) {}

      list.removeAt(index);

      await p.setStringList(key, list);
    }
  }

  static Future<void> migrateLegacyData() async {
    final mobile = await AccountStore.currentUser();

    if (mobile == null || mobile.isEmpty) {
      return;
    }

    final p = await SharedPreferences.getInstance();

    final recordsKeyForUser =
        await _recordsStorageKey();

    final filesKeyForUser =
        await _filesStorageKey();

    final oldRecords =
        p.getStringList(recordsKey) ?? [];

    final oldFiles =
        p.getStringList(filesKey) ?? [];

    final currentRecords =
        p.getStringList(recordsKeyForUser) ?? [];

    final currentFiles =
        p.getStringList(filesKeyForUser) ?? [];

    if (currentRecords.isEmpty &&
        oldRecords.isNotEmpty) {
      await p.setStringList(
        recordsKeyForUser,
        oldRecords,
      );

      await p.remove(recordsKey);
    }

    if (currentFiles.isEmpty &&
        oldFiles.isNotEmpty) {
      await p.setStringList(
        filesKeyForUser,
        oldFiles,
      );

      await p.remove(filesKey);
    }
  }
}

/* =========================================================
   AUTH GATE
========================================================= */

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() =>
      _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool loading = true;

  @override
  void initState() {
    super.initState();
    start();
  }

  Future<void> start() async {
    // દરેક વખતે APK ખોલવામાં Login page આવશે.
    await AccountStore.clearSession();

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return LoginPage(
      onLogin: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const Dashboard(),
          ),
        );
      },
    );
  }
}

/* =========================================================
   LOGIN PAGE
========================================================= */

class LoginPage extends StatefulWidget {
  final VoidCallback onLogin;

  const LoginPage({
    super.key,
    required this.onLogin,
  });

  @override
  State<LoginPage> createState() =>
      _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final mobile = TextEditingController();
  final password = TextEditingController();

  bool loading = false;
  bool hidePassword = true;

  @override
  void dispose() {
    mobile.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> login() async {
    final m = mobile.text.trim();
    final p = password.text;

    if (m.isEmpty || p.isEmpty) {
      _message(
        'મોબાઇલ નંબર અને પાસવર્ડ દાખલ કરો',
      );
      return;
    }

    if (m.length != 10) {
      _message(
        '10 અંકનો મોબાઇલ નંબર દાખલ કરો',
      );
      return;
    }

    setState(() {
      loading = true;
    });

    final success =
        await AccountStore.login(m, p);

    if (!mounted) return;

    setState(() {
      loading = false;
    });

    if (success) {
      await HistoryStore.migrateLegacyData();

      if (!mounted) return;

      widget.onLogin();
    } else {
      _message(
        'મોબાઇલ નંબર અથવા પાસવર્ડ ખોટો છે',
      );
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
      ),
    );
  }

  void openSignup() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SignupPage(
          onSignupComplete: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => const Dashboard(),
              ),
              (route) => false,
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 35),

            Center(
              child: ClipRRect(
                borderRadius:
                    BorderRadius.circular(25),
                child: Image.asset(
                  'assets/rudra_logo.jpg',
                  width: 110,
                  height: 110,
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Center(
              child: Text(
                'RUDRA SURVEYOR',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 6),

            const Center(
              child: Text(
                'Professional Land Survey Tools',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ),

            const SizedBox(height: 40),

            Card(
              elevation: 3,
              child: Padding(
                padding:
                    const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 22),

                    TextField(
                      controller: mobile,
                      keyboardType:
                          TextInputType.phone,
                      maxLength: 10,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'મોબાઇલ નંબર',
                        prefixIcon:
                            Icon(Icons.phone),
                        border:
                            OutlineInputBorder(),
                        counterText: '',
                      ),
                    ),

                    const SizedBox(height: 14),

                    TextField(
                      controller: password,
                      obscureText: hidePassword,
                      decoration:
                          InputDecoration(
                        labelText:
                            'પાસવર્ડ',
                        prefixIcon:
                            const Icon(
                          Icons.lock,
                        ),
                        border:
                            const OutlineInputBorder(),
                        suffixIcon:
                            IconButton(
                          onPressed: () {
                            setState(() {
                              hidePassword =
                                  !hidePassword;
                            });
                          },
                          icon: Icon(
                            hidePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    SizedBox(
                      width:
                          double.infinity,
                      height: 52,
                      child:
                          FilledButton.icon(
                        onPressed:
                            loading
                                ? null
                                : login,
                        icon: loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth:
                                      2,
                                  color:
                                      Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.login,
                              ),
                        label: Text(
                          loading
                              ? 'Login...'
                              : 'Login',
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    const Divider(),

                    const SizedBox(height: 8),

                    TextButton.icon(
                      onPressed: openSignup,
                      icon: const Icon(
                        Icons.person_add,
                      ),
                      label: const Text(
                        'નવું Account બનાવો',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* =========================================================
   SIGNUP PAGE
========================================================= */

class SignupPage extends StatefulWidget {
  final VoidCallback onSignupComplete;

  const SignupPage({
    super.key,
    required this.onSignupComplete,
  });

  @override
  State<SignupPage> createState() =>
      _SignupPageState();
}

class _SignupPageState
    extends State<SignupPage> {
  final name = TextEditingController();
  final mobile = TextEditingController();
  final password = TextEditingController();
  final confirmPassword =
      TextEditingController();

  File? selectedPhoto;
  String? photoName;

  bool loading = false;
  bool hidePassword = true;
  bool hideConfirmPassword = true;

  @override
  void dispose() {
    name.dispose();
    mobile.dispose();
    password.dispose();
    confirmPassword.dispose();
    super.dispose();
  }

  Future<void> pickPhoto() async {
    final result =
        await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: false,
    );

    if (result == null ||
        result.files.single.path == null) {
      return;
    }

    final picked =
        File(result.files.single.path!);

    final dir =
        await getApplicationDocumentsDirectory();

    final photoDir = Directory(
      '${dir.path}/ProfilePhotos',
    );

    if (!await photoDir.exists()) {
      await photoDir.create(
        recursive: true,
      );
    }

    final extension =
        result.files.single.extension ??
            'jpg';

    final file = File(
      '${photoDir.path}/profile_${DateTime.now().millisecondsSinceEpoch}.$extension',
    );

    final saved =
        await picked.copy(file.path);

    if (!mounted) return;

    setState(() {
      selectedPhoto = saved;
      photoName =
          result.files.single.name;
    });
  }

  Future<void> signup() async {
    final n = name.text.trim();
    final m = mobile.text.trim();
    final p = password.text;
    final cp = confirmPassword.text;

    if (n.isEmpty) {
      _message('નામ દાખલ કરો');
      return;
    }

    if (m.length != 10) {
      _message(
        '10 અંકનો મોબાઇલ નંબર દાખલ કરો',
      );
      return;
    }

    if (p.length < 4) {
      _message(
        'પાસવર્ડ ઓછામાં ઓછો 4 અંક/અક્ષરનો રાખો',
      );
      return;
    }

    if (p != cp) {
      _message(
        'Confirm Password સરખો નથી',
      );
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final created =
          await AccountStore.createAccount(
        name: n,
        mobile: m,
        password: p,
        photoPath: selectedPhoto?.path,
      );

      if (!mounted) return;

      setState(() {
        loading = false;
      });

      if (!created) {
        _message(
          'આ મોબાઇલ નંબરથી Account પહેલેથી બનાવેલ છે',
        );
        return;
      }

      await HistoryStore.migrateLegacyData();

      if (!mounted) return;

      _message(
        'Account સફળતાપૂર્વક બની ગયું',
      );

      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      if (!mounted) return;

      widget.onSignupComplete();
    } catch (e) {
      if (mounted) {
        setState(() {
          loading = false;
        });

        _message(
          'Account બનાવવામાં error: $e',
        );
      }
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Account',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 8),

          Center(
            child: GestureDetector(
              onTap: pickPhoto,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 55,
                    backgroundColor:
                        const Color(
                      0xFF1565C0,
                    ).withOpacity(.10),
                    backgroundImage:
                        selectedPhoto != null
                            ? FileImage(
                                selectedPhoto!,
                              )
                            : null,
                    child: selectedPhoto ==
                            null
                        ? const Icon(
                            Icons.person,
                            size: 58,
                            color:
                                Color(0xFF1565C0),
                          )
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding:
                          const EdgeInsets.all(8),
                      decoration:
                          const BoxDecoration(
                        color:
                            Color(0xFF1565C0),
                        shape:
                            BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color:
                            Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          Center(
            child: Text(
              photoName ??
                  'ફોટો ઉમેરો',
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
          ),

          const SizedBox(height: 25),

          AppField(
            controller: name,
            label: 'નામ',
            icon: Icons.person,
          ),

          AppField(
            controller: mobile,
            label: 'મોબાઇલ નંબર',
            icon: Icons.phone,
            keyboard:
                TextInputType.phone,
            maxLength: 10,
          ),

          TextField(
            controller: password,
            obscureText: hidePassword,
            decoration:
                InputDecoration(
              labelText:
                  'પાસવર્ડ',
              prefixIcon:
                  const Icon(
                Icons.lock,
              ),
              border:
                  const OutlineInputBorder(),
              suffixIcon:
                  IconButton(
                onPressed: () {
                  setState(() {
                    hidePassword =
                        !hidePassword;
                  });
                },
                icon: Icon(
                  hidePassword
                      ? Icons.visibility
                      : Icons.visibility_off,
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          TextField(
            controller:
                confirmPassword,
            obscureText:
                hideConfirmPassword,
            decoration:
                InputDecoration(
              labelText:
                  'Confirm Password',
              prefixIcon:
                  const Icon(
                Icons.lock_outline,
              ),
              border:
                  const OutlineInputBorder(),
              suffixIcon:
                  IconButton(
                onPressed: () {
                  setState(() {
                    hideConfirmPassword =
                        !hideConfirmPassword;
                  });
                },
                icon: Icon(
                  hideConfirmPassword
                      ? Icons.visibility
                      : Icons.visibility_off,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed:
                  loading ? null : signup,
              icon: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                        color:
                            Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.person_add,
                    ),
              label: Text(
                loading
                    ? 'Creating Account...'
                    : 'Create Account',
              ),
            ),
          ),

          const SizedBox(height: 15),

          const Center(
            child: Text(
              'Account અને app data આ ફોનમાં locally save થશે.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* =========================================================
   PDF SERVICE
========================================================= */

class PdfService {
  static Future<File> createReport(
    Map<String, dynamic> r,
  ) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat:
            PdfPageFormat.a4,
        margin:
            const pw.EdgeInsets.all(
          32,
        ),
        build: (_) => pw.Column(
          crossAxisAlignment:
              pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Text(
                'RUDRA SURVEYOR',
                style:
                    pw.TextStyle(
                  fontSize: 25,
                  fontWeight:
                      pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Center(
              child: pw.Text(
                'LAND SURVEY REPORT',
                style:
                    pw.TextStyle(
                  fontSize: 13,
                  fontWeight:
                      pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 18),
            pw.Divider(),
            _row(
              'Owner Name',
              r['owner'],
            ),
            _row(
              'Mobile Number',
              r['mobile'],
            ),
            _row(
              'Village',
              r['village'],
            ),
            _row(
              'Taluka',
              r['taluka'],
            ),
            _row(
              'Survey Number',
              r['survey'],
            ),
            _row(
              'Survey Date',
              r['date'],
            ),
            _row(
              'Total Payment',
              'Rs. ${r['payment'] ?? '0'}',
            ),
            if ((r['fileName'] ?? '')
                .toString()
                .isNotEmpty)
              _row(
                'Uploaded File',
                r['fileName'],
              ),
            pw.SizedBox(height: 25),
            pw.Container(
              width:
                  double.infinity,
              padding:
                  const pw.EdgeInsets.all(
                12,
              ),
              decoration:
                  pw.BoxDecoration(
                border:
                    pw.Border.all(
                  color:
                      PdfColors.grey,
                ),
              ),
              child: pw.Text(
                'This report is generated by RUDRA SURVEYOR application.',
                style:
                    const pw.TextStyle(
                  fontSize: 10,
                ),
              ),
            ),
            pw.Spacer(),
            pw.Center(
              child: pw.Text(
                'RUDRA SURVEYOR',
                style:
                    pw.TextStyle(
                  fontWeight:
                      pw.FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final dir =
        await getApplicationDocumentsDirectory();

    final file = File(
      '${dir.path}/RUDRA_SURVEY_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );

    await file.writeAsBytes(
      await doc.save(),
    );

    return file;
  }

  static pw.Widget _row(
    String title,
    dynamic value,
  ) {
    return pw.Padding(
      padding:
          const pw.EdgeInsets.only(
        bottom: 10,
      ),
      child: pw.Row(
        crossAxisAlignment:
            pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 145,
            child: pw.Text(
              title,
              style:
                  pw.TextStyle(
                fontWeight:
                    pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value?.toString() ??
                  '-',
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> preview(
    Map<String, dynamic> r,
  ) async {
    final file =
        await createReport(r);

    final bytes =
        await file.readAsBytes();

    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
    );
  }

  static Future<void> share(
    Map<String, dynamic> r,
  ) async {
    final file =
        await createReport(r);

    await Share.shareXFiles(
      [XFile(file.path)],
      text:
          'RUDRA SURVEYOR Report',
    );
  }
}

/* =========================================================
   DASHBOARD
========================================================= */

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() =>
      _DashboardState();
}

class _DashboardState
    extends State<Dashboard> {
  int tab = 0;

  void open(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => page,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _home(),
      HistoryPage(
        onHome: () {
          setState(() {
            tab = 0;
          });
        },
      ),
      const GpsPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      body: SafeArea(
        child: pages[tab],
      ),
      bottomNavigationBar:
          NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) {
          setState(() {
            tab = i;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(
              Icons.home_outlined,
            ),
            selectedIcon:
                Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon:
                Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.location_on_outlined,
            ),
            selectedIcon: Icon(
              Icons.location_on,
            ),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.person_outline,
            ),
            selectedIcon: Icon(
              Icons.person,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _home() {
    return FutureBuilder<
        List<Map<String, dynamic>>>(
      future: HistoryStore.records(),
      builder: (context, snap) {
        final records =
            snap.data ?? [];

        final payment =
            records.fold<double>(
          0,
          (sum, r) =>
              sum +
              (double.tryParse(
                    '${r['payment'] ?? 0}',
                  ) ??
                  0),
        );

        return ListView(
          padding:
              const EdgeInsets.fromLTRB(
            16,
            16,
            16,
            24,
          ),
          children: [
            _header(),

            const SizedBox(height: 18),

            _welcomeCard(),

            const SizedBox(height: 18),

            const Text(
              'Operations',
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            _opCard(
              'OP1',
              'Land Entry',
              'Owner, land and payment details',
              Icons.edit_document,
              const Color(
                0xFF1565C0,
              ),
              () {
                open(
                  const LandEntryPage(),
                );
              },
            ),

            _opCard(
              'OP2',
              'GPS Survey',
              'GPS survey tools',
              Icons.gps_fixed,
              const Color(
                0xFF00897B,
              ),
              () {
                open(
                  const GpsPage(),
                );
              },
            ),

            _opCard(
              'OP3',
              'Unit Conversion',
              'Length and land-area units',
              Icons.swap_horiz,
              const Color(
                0xFF7B1FA2,
              ),
              () {
                open(
                  const UnitPage(),
                );
              },
            ),

            _opCard(
              'OP4',
              'Area Calculator',
              'Length × Width = m²',
              Icons.calculate,
              const Color(
                0xFFEF6C00,
              ),
              () {
                open(
                  const AreaPage(),
                );
              },
            ),

            const SizedBox(height: 12),

            Card(
              child: ListTile(
                leading:
                    const CircleAvatar(
                  child: Icon(
                    Icons.folder,
                  ),
                ),
                title: const Text(
                  'Saved Files',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                subtitle:
                    const Text(
                  'Browse uploaded files saved inside the app',
                ),
                trailing:
                    const Icon(
                  Icons.chevron_right,
                ),
                onTap: () {
                  open(
                    const SavedFilesPage(),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(
                  18,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.history,
                      size: 35,
                      color:
                          Color(0xFF1565C0),
                    ),
                    const SizedBox(
                      width: 14,
                    ),
                    Expanded(
                      child: Text(
                        '${records.length} Saved Records',
                        style:
                            const TextStyle(
                          fontSize: 17,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      '₹${payment.toStringAsFixed(0)}',
                      style:
                          const TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _header() {
    return FutureBuilder<
        Map<String, dynamic>?>(
      future:
          AccountStore.currentAccount(),
      builder:
          (context, snapshot) {
        final account =
            snapshot.data;

        final name =
            account?['name']
                ?.toString();

        return Row(
          children: [
            ClipRRect(
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
              child: Image.asset(
                'assets/rudra_logo.jpg',
                width: 58,
                height: 58,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(
              width: 12,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'RUDRA SURVEYOR',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  Text(
                    name == null ||
                            name.isEmpty
                        ? 'Professional Land Survey Tools'
                        : 'Welcome, $name',
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _welcomeCard() {
    return Container(
      padding:
          const EdgeInsets.all(20),
      decoration:
          BoxDecoration(
        borderRadius:
            BorderRadius.circular(
          22,
        ),
        gradient:
            const LinearGradient(
          colors: [
            Color(0xFF1565C0),
            Color(0xFF42A5F5),
          ],
        ),
      ),
      child: const Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            'RUDRA SURVEYOR',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Fast • Simple • Professional',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _opCard(
    String no,
    String title,
    String sub,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 7,
        ),
        leading: CircleAvatar(
          backgroundColor:
              color.withOpacity(.12),
          foregroundColor: color,
          child: Icon(icon),
        ),
        title: Text(
          '$no • $title',
          style:
              const TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        subtitle: Text(sub),
        trailing:
            const Icon(
          Icons.chevron_right,
        ),
        onTap: onTap,
      ),
    );
  }
}

/* =========================================================
   OP1 LAND ENTRY
========================================================= */

class LandEntryPage extends StatefulWidget {
  const LandEntryPage({super.key});

  @override
  State<LandEntryPage> createState() =>
      _LandEntryPageState();
}

class _LandEntryPageState
    extends State<LandEntryPage> {
  final owner =
      TextEditingController();

  final mobile =
      TextEditingController();

  final village =
      TextEditingController();

  final taluka =
      TextEditingController();

  final survey =
      TextEditingController();

  final payment =
      TextEditingController();

  DateTime date =
      DateTime.now();

  File? selectedFile;
  String? selectedFileName;

  bool saving = false;

  @override
  void dispose() {
    owner.dispose();
    mobile.dispose();
    village.dispose();
    taluka.dispose();
    survey.dispose();
    payment.dispose();
    super.dispose();
  }

  Future<void> chooseDate() async {
    final d =
        await showDatePicker(
      context: context,
      initialDate: date,
      firstDate:
          DateTime(2000),
      lastDate:
          DateTime(2100),
    );

    if (d != null) {
      setState(() {
        date = d;
      });
    }
  }

  Future<void> pickFile() async {
    final result =
        await FilePicker.platform.pickFiles(
      withData: false,
      allowMultiple: false,
    );

    if (result == null ||
        result.files.single.path ==
            null) {
      return;
    }

    final picked = File(
      result.files.single.path!,
    );

    final dir =
        await getApplicationDocumentsDirectory();

    final saveDir =
        Directory(
      '${dir.path}/SavedFiles',
    );

    if (!await saveDir.exists()) {
      await saveDir.create(
        recursive: true,
      );
    }

    final safeName =
        '${DateTime.now().millisecondsSinceEpoch}_${result.files.single.name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')}';

    final saved =
        await picked.copy(
      '${saveDir.path}/$safeName',
    );

    setState(() {
      selectedFile = saved;
      selectedFileName =
          result.files.single.name;
    });
  }

  Future<void> save() async {
    if (owner.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'માલિકનું નામ દાખલ કરો',
          ),
        ),
      );
      return;
    }

    setState(() {
      saving = true;
    });

    try {
      String? savedPath;

      if (selectedFile != null) {
        savedPath =
            selectedFile!.path;

        await HistoryStore.addFile({
          'name':
              selectedFileName ??
                  selectedFile!
                      .uri
                      .pathSegments
                      .last,
          'path': savedPath,
          'date': DateTime.now()
              .toIso8601String(),
        });
      }

      final record = {
        'owner':
            owner.text.trim(),
        'mobile':
            mobile.text.trim(),
        'village':
            village.text.trim(),
        'taluka':
            taluka.text.trim(),
        'survey':
            survey.text.trim(),
        'date':
            '${date.day}/${date.month}/${date.year}',
        'payment':
            payment.text.trim(),
        'fileName':
            selectedFileName ?? '',
        'filePath':
            savedPath ?? '',
      };

      await HistoryStore.addRecord(
        record,
      );

      final pdf =
          await PdfService.createReport(
        record,
      );

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (_) =>
            AlertDialog(
          title: const Text(
            'Saved Successfully',
          ),
          content: Text(
            selectedFileName == null
                ? 'Record saved. PDF report is ready.'
                : 'Record and file saved. PDF report is ready.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                );

                Printing.layoutPdf(
                  onLayout:
                      (_) async =>
                          pdf.readAsBytes(),
                );
              },
              child: const Text(
                'Preview PDF',
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                );

                Share.shareXFiles(
                  [XFile(pdf.path)],
                  text:
                      'RUDRA SURVEYOR Report',
                );
              },
              child: const Text(
                'Share',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                );
              },
              child:
                  const Text('Done'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content:
                Text('Save error: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'OP1 • Land Entry',
        ),
      ),
      body: ListView(
        padding:
            const EdgeInsets.all(16),
        children: [
          AppField(
            controller: owner,
            label: 'માલિકનું નામ',
            icon: Icons.person,
          ),
          AppField(
            controller: mobile,
            label: 'મોબાઇલ નંબર',
            icon: Icons.phone,
            keyboard:
                TextInputType.phone,
          ),
          AppField(
            controller: village,
            label: 'ગામ',
            icon:
                Icons.location_city,
          ),
          AppField(
            controller: taluka,
            label: 'તાલુકો',
            icon:
                Icons.location_on,
          ),
          AppField(
            controller: survey,
            label: 'સર્વે નંબર',
            icon: Icons.numbers,
          ),
          InkWell(
            onTap: chooseDate,
            child:
                InputDecorator(
              decoration:
                  const InputDecoration(
                labelText:
                    'માપણીની તારીખ',
                prefixIcon:
                    Icon(
                  Icons.calendar_month,
                ),
                border:
                    OutlineInputBorder(),
              ),
              child: Text(
                '${date.day}/${date.month}/${date.year}',
              ),
            ),
          ),
          const SizedBox(
            height: 14,
          ),
          AppField(
            controller: payment,
            label:
                'કુલ પેમેન્ટ (₹)',
            icon:
                Icons.currency_rupee,
            keyboard:
                const TextInputType.numberWithOptions(
              decimal: true,
            ),
          ),
          const SizedBox(
            height: 14,
          ),
          OutlinedButton.icon(
            onPressed: pickFile,
            icon: const Icon(
              Icons.upload_file,
            ),
            label: Text(
              selectedFileName ==
                      null
                  ? 'Upload a File'
                  : 'Selected: $selectedFileName',
            ),
          ),
          if (selectedFileName !=
              null) ...[
            const SizedBox(
              height: 8,
            ),
            Text(
              'File will be saved inside the app.',
              style: TextStyle(
                color:
                    Colors.grey.shade700,
              ),
            ),
          ],
          const SizedBox(
            height: 20,
          ),
          SizedBox(
            height: 54,
            child:
                FilledButton.icon(
              onPressed:
                  saving
                      ? null
                      : save,
              icon: saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                        color:
                            Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.save,
                    ),
              label: Text(
                saving
                    ? 'Saving...'
                    : 'Save + PDF Report',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* =========================================================
   HISTORY PAGE
========================================================= */

class HistoryPage extends StatefulWidget {
  final VoidCallback onHome;

  const HistoryPage({
    super.key,
    required this.onHome,
  });

  @override
  State<HistoryPage> createState() =>
      _HistoryPageState();
}

class _HistoryPageState
    extends State<HistoryPage> {
  List<Map<String, dynamic>>
      records = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final r =
        await HistoryStore.records();

    if (mounted) {
      setState(() {
        records =
            r.reversed.toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text(
          'Saved History',
        ),
      ),
      body: records.isEmpty
          ? const Center(
              child: Text(
                'No saved records',
              ),
            )
          : ListView.builder(
              padding:
                  const EdgeInsets.all(
                12,
              ),
              itemCount:
                  records.length,
              itemBuilder: (_, i) {
                final r =
                    records[i];

                return Card(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(
                      14,
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          r['owner']
                                  ?.toString() ??
                              '-',
                          style:
                              const TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Survey: ${r['survey'] ?? '-'}  •  ${r['date'] ?? '-'}',
                        ),
                        Text(
                          'Village: ${r['village'] ?? '-'}  •  Taluka: ${r['taluka'] ?? '-'}',
                        ),
                        Text(
                          'Payment: ₹${r['payment'] ?? '0'}',
                        ),
                        if ((r['fileName'] ??
                                '')
                            .toString()
                            .isNotEmpty)
                          Text(
                            'File: ${r['fileName']}',
                          ),
                        const SizedBox(
                          height: 8,
                        ),
                        Wrap(
                          spacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () =>
                                  PdfService
                                      .preview(
                                r,
                              ),
                              icon:
                                  const Icon(
                                Icons
                                    .picture_as_pdf,
                              ),
                              label:
                                  const Text(
                                'PDF',
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: () =>
                                  PdfService
                                      .share(
                                r,
                              ),
                              icon:
                                  const Icon(
                                Icons.share,
                              ),
                              label:
                                  const Text(
                                'Share',
                              ),
                            ),
                            IconButton(
                              onPressed:
                                  () async {
                                await HistoryStore
                                    .deleteRecord(
                                  records.length -
                                      1 -
                                      i,
                                );

                                await load();
                              },
                              icon:
                                  const Icon(
                                Icons
                                    .delete_outline,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

/* =========================================================
   SAVED FILES
========================================================= */

class SavedFilesPage
    extends StatefulWidget {
  const SavedFilesPage({
    super.key,
  });

  @override
  State<SavedFilesPage>
      createState() =>
          _SavedFilesPageState();
}

class _SavedFilesPageState
    extends State<SavedFilesPage> {
  List<Map<String, dynamic>>
      files = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final f =
        await HistoryStore.files();

    if (mounted) {
      setState(() {
        files =
            f.reversed.toList();
      });
    }
  }

  Future<void> shareFile(
      Map<String, dynamic>
          item) async {
    final path =
        item['path']?.toString();

    if (path == null) {
      return;
    }

    final f = File(path);

    if (await f.exists()) {
      await Share.shareXFiles(
        [XFile(path)],
        text:
            item['name']
                    ?.toString() ??
                'RUDRA SURVEYOR file',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text(
          'Saved Files',
        ),
      ),
      body: files.isEmpty
          ? const Center(
              child: Text(
                'No uploaded files saved yet',
              ),
            )
          : ListView.builder(
              itemCount:
                  files.length,
              padding:
                  const EdgeInsets.all(
                12,
              ),
              itemBuilder: (_, i) {
                final f =
                    files[i];

                return Card(
                  child: ListTile(
                    leading:
                        const CircleAvatar(
                      child: Icon(
                        Icons
                            .insert_drive_file,
                      ),
                    ),
                    title: Text(
                      f['name']
                              ?.toString() ??
                          'File',
                    ),
                    subtitle: Text(
                      f['date']
                              ?.toString()
                              .split(
                                'T',
                              )
                              .first ??
                          '',
                    ),
                    trailing: Wrap(
                      children: [
                        IconButton(
                          onPressed: () =>
                              shareFile(
                            f,
                          ),
                          icon:
                              const Icon(
                            Icons.share,
                          ),
                        ),
                        IconButton(
                          onPressed:
                              () async {
                            await HistoryStore
                                .deleteFile(
                              files.length -
                                  1 -
                                  i,
                            );

                            await load();
                          },
                          icon:
                              const Icon(
                            Icons
                                .delete_outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

/* =========================================================
   AREA CALCULATOR OP4
========================================================= */

class AreaPage
    extends StatefulWidget {
  const AreaPage({
    super.key,
  });

  @override
  State<AreaPage> createState() =>
      _AreaPageState();
}

class _AreaPageState
    extends State<AreaPage> {
  final length =
      TextEditingController();

  final width =
      TextEditingController();

  double area = 0;

  void calculate() {
    setState(() {
      area =
          (double.tryParse(
                    length.text,
                  ) ??
                  0) *
              (double.tryParse(
                    width.text,
                  ) ??
                  0);
    });
  }

  @override
  void dispose() {
    length.dispose();
    width.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text(
          'OP4 • Area Calculator',
        ),
      ),
      body: ListView(
        padding:
            const EdgeInsets.all(16),
        children: [
          AppField(
            controller: length,
            label:
                'લંબાઈ (મીટર)',
            icon:
                Icons.straighten,
            keyboard:
                const TextInputType.numberWithOptions(
              decimal: true,
            ),
          ),
          AppField(
            controller: width,
            label:
                'પહોળાઈ (મીટર)',
            icon:
                Icons.straighten,
            keyboard:
                const TextInputType.numberWithOptions(
              decimal: true,
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          FilledButton(
            onPressed: calculate,
            child:
                const Text(
              'Calculate Area',
            ),
          ),
          const SizedBox(
            height: 25,
          ),
          Center(
            child: Text(
              '${area.toStringAsFixed(2)} m²',
              style:
                  const TextStyle(
                fontSize: 32,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* =========================================================
   UNIT CONVERSION OP3
========================================================= */

class UnitPage
    extends StatefulWidget {
  const UnitPage({
    super.key,
  });

  @override
  State<UnitPage> createState() =>
      _UnitPageState();
}

class _UnitPageState
    extends State<UnitPage> {
  final input =
      TextEditingController();

  String from = 'Meter';
  String to = 'Feet';
  String result = '0';

  final units = const [
    'Meter',
    'Feet',
    'Inch',
    'Yard',
    'm²',
    'ft²',
    'yd²',
    'Acre',
    'Hectare',
    'Guntha',
  ];

  final areaUnits = const {
    'm²',
    'ft²',
    'yd²',
    'Acre',
    'Hectare',
    'Guntha',
  };

  double toBase(
    double v,
    String unit,
  ) {
    switch (unit) {
      case 'Feet':
        return v * 0.3048;

      case 'Inch':
        return v * 0.0254;

      case 'Yard':
        return v * 0.9144;

      case 'ft²':
        return v * 0.09290304;

      case 'yd²':
        return v * 0.83612736;

      case 'Acre':
        return v * 4046.8564224;

      case 'Hectare':
        return v * 10000;

      case 'Guntha':
        return v * 101.17141056;

      default:
        return v;
    }
  }

  double fromBase(
    double v,
    String unit,
  ) {
    switch (unit) {
      case 'Feet':
        return v / 0.3048;

      case 'Inch':
        return v / 0.0254;

      case 'Yard':
        return v / 0.9144;

      case 'ft²':
        return v / 0.09290304;

      case 'yd²':
        return v / 0.83612736;

      case 'Acre':
        return v / 4046.8564224;

      case 'Hectare':
        return v / 10000;

      case 'Guntha':
        return v / 101.17141056;

      default:
        return v;
    }
  }

  void convert() {
    final v =
        double.tryParse(
              input.text,
            ) ??
            0;

    final bothArea =
        areaUnits.contains(
              from,
            ) &&
            areaUnits.contains(
              to,
            );

    final bothLength =
        !areaUnits.contains(
              from,
            ) &&
            !areaUnits.contains(
              to,
            );

    if (!bothArea &&
        !bothLength) {
      setState(() {
        result =
            'Length અને Area units mix કરી શકાતા નથી';
      });
      return;
    }

    setState(() {
      result = fromBase(
        toBase(
          v,
          from,
        ),
        to,
      ).toStringAsFixed(4);
    });
  }

  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text(
          'OP3 • Unit Conversion',
        ),
      ),
      body: ListView(
        padding:
            const EdgeInsets.all(16),
        children: [
          AppField(
            controller: input,
            label: 'Value',
            icon:
                Icons.numbers,
            keyboard:
                const TextInputType.numberWithOptions(
              decimal: true,
            ),
          ),
          DropdownButtonFormField<
              String>(
            value: from,
            decoration:
                const InputDecoration(
              labelText: 'From',
              border:
                  OutlineInputBorder(),
            ),
            items: units
                .map(
                  (u) =>
                      DropdownMenuItem(
                    value: u,
                    child: Text(u),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) {
                setState(() {
                  from = v;
                });
              }
            },
          ),
          const SizedBox(
            height: 12,
          ),
          DropdownButtonFormField<
              String>(
            value: to,
            decoration:
                const InputDecoration(
              labelText: 'To',
              border:
                  OutlineInputBorder(),
            ),
            items: units
                .map(
                  (u) =>
                      DropdownMenuItem(
                    value: u,
                    child: Text(u),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) {
                setState(() {
                  to = v;
                });
              }
            },
          ),
          const SizedBox(
            height: 15,
          ),
          FilledButton(
            onPressed: convert,
            child:
                const Text('Convert'),
          ),
          const SizedBox(
            height: 20,
          ),
          Center(
            child: Text(
              '$result $to',
              style:
                  const TextStyle(
                fontSize: 26,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* =========================================================
   GPS OP2
========================================================= */

class GpsPage
    extends StatelessWidget {
  const GpsPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text(
          'OP2 • GPS Survey',
        ),
      ),
      body: const Center(
        child: Padding(
          padding:
              EdgeInsets.all(25),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment
                    .center,
            children: [
              Icon(
                Icons.gps_fixed,
                size: 80,
                color:
                    Color(0xFF00897B),
              ),
              SizedBox(
                height: 15,
              ),
              Text(
                'GPS Survey',
                style:
                    TextStyle(
                  fontSize: 24,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              SizedBox(
                height: 8,
              ),
              Text(
                'GPS tools can be connected here when location functionality is added.',
                textAlign:
                    TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* =========================================================
   PROFILE
========================================================= */

class ProfilePage
    extends StatefulWidget {
  const ProfilePage({
    super.key,
  });

  @override
  State<ProfilePage> createState() =>
      _ProfilePageState();
}

class _ProfilePageState
    extends State<ProfilePage> {
  Map<String, dynamic>?
      account;

  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final a =
        await AccountStore
            .currentAccount();

    if (mounted) {
      setState(() {
        account = a;
        loading = false;
      });
    }
  }

  Future<void> logout() async {
    await AccountStore.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const LoginPageWrapper(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    final name =
        account?['name']
                ?.toString() ??
            '';

    final mobile =
        account?['mobile']
                ?.toString() ??
            '';

    final photoPath =
        account?['photoPath']
                ?.toString() ??
            '';

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Profile'),
      ),
      body: ListView(
        padding:
            const EdgeInsets.all(20),
        children: [
          Center(
            child: CircleAvatar(
              radius: 55,
              backgroundImage:
                  photoPath.isNotEmpty
                      ? FileImage(
                          File(photoPath),
                        )
                      : null,
              child: photoPath.isEmpty
                  ? const Icon(
                      Icons.person,
                      size: 55,
                    )
                  : null,
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          Center(
            child: Text(
              name.isEmpty
                  ? 'RUDRA SURVEYOR'
                  : name,
              style:
                  const TextStyle(
                fontSize: 24,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),

          if (mobile.isNotEmpty) ...[
            const SizedBox(
              height: 6,
            ),
            Center(
              child: Text(
                mobile,
                style:
                    const TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                ),
              ),
            ),
          ],

          const SizedBox(
            height: 8,
          ),

          const Center(
            child: Text(
              'Professional Land Survey Tools',
            ),
          ),

          const SizedBox(
            height: 35,
          ),

          Card(
            child: ListTile(
              leading:
                  const Icon(
                Icons.security,
                color:
                    Color(0xFF1565C0),
              ),
              title:
                  const Text(
                'Account Data',
                style:
                    TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              subtitle:
                  const Text(
                'Your History and Saved Files are separated by account.',
              ),
            ),
          ),

          const SizedBox(
            height: 18,
          ),

          SizedBox(
            height: 52,
            child:
                OutlinedButton.icon(
              onPressed: logout,
              icon: const Icon(
                Icons.logout,
              ),
              label: const Text(
                'Logout',
                style:
                    TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* =========================================================
   LOGIN WRAPPER
========================================================= */

class LoginPageWrapper
    extends StatelessWidget {
  const LoginPageWrapper({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return LoginPage(
      onLogin: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const Dashboard(),
          ),
        );
      },
    );
  }
}

/* =========================================================
   APP FIELD
========================================================= */

class AppField
    extends StatelessWidget {
  final TextEditingController
      controller;

  final String label;
  final IconData icon;

  final TextInputType? keyboard;
  final int? maxLength;

  const AppField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboard,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 14,
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        maxLength: maxLength,
        decoration:
            InputDecoration(
          labelText: label,
          prefixIcon:
              Icon(icon),
          border:
              const OutlineInputBorder(),
          counterText:
              maxLength != null
                  ? ''
                  : null,
        ),
      ),
    );
  }
}
