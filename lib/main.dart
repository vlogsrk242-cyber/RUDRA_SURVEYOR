import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';

void main() {
  runApp(const RudraSurveyorApp());
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool loading = true;
  bool loggedIn = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    // APK starts with Login screen every time.
    await AccountStore.clearCurrentUser();
    if (!mounted) return;
    setState(() => loading = false);
  }

  void _loginSuccess() {
    if (mounted) setState(() => loggedIn = true);
  }

  Future<void> _logout() async {
    await AccountStore.clearCurrentUser();
    if (mounted) setState(() => loggedIn = false);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (loggedIn) {
      return Dashboard(onLogout: _logout);
    }
    return LoginPage(onAuthenticated: _loginSuccess);
  }
}

class LoginPage extends StatefulWidget {
  final VoidCallback onAuthenticated;

  const LoginPage({super.key, required this.onAuthenticated});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final mobileController = TextEditingController();
  final passwordController = TextEditingController();
  bool busy = false;
  bool obscure = true;

  @override
  void dispose() {
    mobileController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (mobileController.text.trim().isEmpty ||
        passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mobile અને Password નાખો.')),
      );
      return;
    }

    setState(() => busy = true);
    final error = await AccountStore.login(
      mobileController.text,
      passwordController.text,
    );
    if (!mounted) return;
    setState(() => busy = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    await HistoryStore.migrateLegacyToCurrent();
    widget.onAuthenticated();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'assets/rudra_logo.jpg',
                      width: 130,
                      height: 130,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'RUDRA SURVEYOR',
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF123B68),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text('Login to continue'),
                  const SizedBox(height: 28),
                  TextField(
                    controller: mobileController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Mobile Number',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: passwordController,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => obscure = !obscure),
                        icon: Icon(
                          obscure ? Icons.visibility : Icons.visibility_off,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: busy ? null : login,
                      child: busy
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('LOGIN'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: busy
                        ? null
                        : () async {
                            final created = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SignupPage(),
                              ),
                            );
                            if (created == true && mounted) {
                              widget.onAuthenticated();
                            }
                          },
                    child: const Text('Create New Account / Sign Up'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final nameController = TextEditingController();
  final mobileController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  String? photoPath;
  bool busy = false;
  bool obscure = true;

  @override
  void dispose() {
    nameController.dispose();
    mobileController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  Future<void> pickPhoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: false,
    );
    if (result == null || result.files.isEmpty) return;

    final source = result.files.single.path;
    if (source == null) return;

    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/ProfilePhotos');
    await dir.create(recursive: true);

    final ext = result.files.single.extension ?? 'jpg';
    final target = File(
      '${dir.path}/profile_${DateTime.now().millisecondsSinceEpoch}.$ext',
    );
    final saved = await File(source).copy(target.path);

    if (!mounted) return;
    setState(() => photoPath = saved.path);
  }

  Future<void> signup() async {
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name નાખો.')),
      );
      return;
    }
    if (passwordController.text != confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Confirm Password match થતો નથી.')),
      );
      return;
    }

    setState(() => busy = true);
    final error = await AccountStore.signup(
      name: nameController.text,
      mobile: mobileController.text,
      password: passwordController.text,
      photoPath: photoPath,
    );

    if (!mounted) return;
    setState(() => busy = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    await HistoryStore.migrateLegacyToCurrent();
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              GestureDetector(
                onTap: pickPhoto,
                child: photoPath != null
                    ? CircleAvatar(
                        radius: 52,
                        backgroundImage: FileImage(File(photoPath!)),
                      )
                    : const CircleAvatar(
                        radius: 52,
                        child: Icon(Icons.add_a_photo, size: 34),
                      ),
              ),
              const SizedBox(height: 8),
              const Text('Profile Photo (optional)'),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: mobileController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: passwordController,
                obscureText: obscure,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => obscure = !obscure),
                    icon: Icon(
                      obscure ? Icons.visibility : Icons.visibility_off,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: confirmController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: busy ? null : signup,
                  child: busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('CREATE ACCOUNT'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// APP
// ============================================================

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

// ============================================================
// STORAGE
// ============================================================

class AccountStore {
  static const String accountsKey = 'rudra_accounts';
  static const String currentUserKey = 'rudra_current_user';

  static String normalizeMobile(String value) =>
      value.replaceAll(RegExp(r'\D'), '');

  static Future<List<Map<String, dynamic>>> accounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(accountsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<Map<String, dynamic>?> findByMobile(String mobile) async {
    final id = normalizeMobile(mobile);
    for (final account in await accounts()) {
      if (normalizeMobile(account['mobile']?.toString() ?? '') == id) {
        return account;
      }
    }
    return null;
  }

  static Future<String?> signup({
    required String name,
    required String mobile,
    required String password,
    String? photoPath,
  }) async {
    final id = normalizeMobile(mobile);
    if (id.length < 10) return 'યોગ્ય Mobile Number નાખો.';
    if (password.length < 4) return 'Password ઓછામાં ઓછો 4 અક્ષરનો હોવો જોઈએ.';
    if (await findByMobile(id) != null) return 'આ Mobile Number પહેલેથી નોંધાયેલ છે.';

    final list = await accounts();
    list.add({
      'mobile': id,
      'name': name.trim(),
      'password': password,
      'photoPath': photoPath ?? '',
      'createdAt': DateTime.now().toIso8601String(),
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(accountsKey, jsonEncode(list));
    await setCurrentUser(id);
    return null;
  }

  static Future<String?> login(String mobile, String password) async {
    final account = await findByMobile(mobile);
    if (account == null) return 'Account મળ્યું નથી. પહેલા Sign Up કરો.';
    if ((account['password']?.toString() ?? '') != password) {
      return 'Mobile અથવા Password ખોટો છે.';
    }
    await setCurrentUser(normalizeMobile(mobile));
    return null;
  }

  static Future<void> setCurrentUser(String mobile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(currentUserKey, normalizeMobile(mobile));
  }

  static Future<void> clearCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(currentUserKey);
  }

  static Future<String?> currentMobile() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(currentUserKey);
  }

  static Future<Map<String, dynamic>?> currentAccount() async {
    final mobile = await currentMobile();
    if (mobile == null || mobile.isEmpty) return null;
    return findByMobile(mobile);
  }
}

class HistoryStore {
  static const String legacyRecordsKey = 'land_records';
  static const String legacyFilesKey = 'saved_files';

  static Future<String> _recordsKey() async {
    final mobile = await AccountStore.currentMobile();
    return (mobile == null || mobile.isEmpty)
        ? legacyRecordsKey
        : 'land_records_$mobile';
  }

  static Future<String> _filesKey() async {
    final mobile = await AccountStore.currentMobile();
    return (mobile == null || mobile.isEmpty)
        ? legacyFilesKey
        : 'saved_files_$mobile';
  }

  static Future<List<Map<String, dynamic>>> getRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(await _recordsKey()) ?? [];
    final records = <Map<String, dynamic>>[];

    for (final item in list) {
      try {
        final decoded = jsonDecode(item);
        if (decoded is Map) {
          records.add(Map<String, dynamic>.from(decoded));
        }
      } catch (_) {}
    }
    return records;
  }

  static Future<void> addRecord(Map<String, dynamic> record) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _recordsKey();
    final list = prefs.getStringList(key) ?? [];
    list.add(jsonEncode(record));
    await prefs.setStringList(key, list);
  }

  static Future<void> deleteRecord(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _recordsKey();
    final list = prefs.getStringList(key) ?? [];
    if (index >= 0 && index < list.length) {
      list.removeAt(index);
      await prefs.setStringList(key, list);
    }
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(await _recordsKey());
  }

  static Future<void> addSavedFilePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _filesKey();
    final list = prefs.getStringList(key) ?? [];
    if (!list.contains(path)) list.add(path);
    await prefs.setStringList(key, list);
  }

  static Future<void> removeSavedFilePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _filesKey();
    final list = prefs.getStringList(key) ?? [];
    list.remove(path);
    await prefs.setStringList(key, list);
  }

  static Future<void> migrateLegacyToCurrent() async {
    final mobile = await AccountStore.currentMobile();
    if (mobile == null || mobile.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final recordsKey = 'land_records_$mobile';
    final filesKey = 'saved_files_$mobile';

    final oldRecords = prefs.getStringList(legacyRecordsKey) ?? [];
    final oldFiles = prefs.getStringList(legacyFilesKey) ?? [];
    final newRecords = prefs.getStringList(recordsKey) ?? [];
    final newFiles = prefs.getStringList(filesKey) ?? [];

    if (newRecords.isEmpty && oldRecords.isNotEmpty) {
      await prefs.setStringList(recordsKey, List<String>.from(oldRecords));
    }
    if (newFiles.isEmpty && oldFiles.isNotEmpty) {
      await prefs.setStringList(filesKey, List<String>.from(oldFiles));
    }
  }
}

// ============================================================
// SAVED FILES SERVICE
// ============================================================

class SavedFileService {
  static Future<Directory> _directory() async {
    final base = await getApplicationDocumentsDirectory();
    final mobile = await AccountStore.currentMobile();
    final safeId = (mobile == null || mobile.isEmpty)
        ? 'guest'
        : mobile.replaceAll(RegExp(r'[^0-9]'), '');
    final dir = Directory('${base.path}/saved_files/$safeId');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<File?> pickAndSave() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.isEmpty) return null;

    final picked = result.files.single;
    final sourcePath = picked.path;
    if (sourcePath == null) return null;

    final dir = await _directory();
    final safeName = picked.name.isEmpty
        ? 'file_${DateTime.now().millisecondsSinceEpoch}'
        : picked.name;
    final destination = File('${dir.path}/$safeName');

    var target = destination;
    if (await target.exists()) {
      final dot = safeName.lastIndexOf('.');
      final baseName = dot > 0 ? safeName.substring(0, dot) : safeName;
      final extension = dot > 0 ? safeName.substring(dot) : '';
      target = File(
        '${dir.path}/${baseName}_${DateTime.now().millisecondsSinceEpoch}$extension',
      );
    }

    final saved = await File(sourcePath).copy(target.path);
    await HistoryStore.addSavedFilePath(saved.path);
    return saved;
  }

  static Future<List<File>> getFiles() async {
    final dir = await _directory();
    final items = await dir.list().toList();
    final files = items.whereType<File>().toList();
    files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    return files;
  }

  static Future<void> deleteFile(File file) async {
    await HistoryStore.removeSavedFilePath(file.path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}

// ============================================================
// SAVED FILES PAGE
// ============================================================

class SavedFilesPage extends StatefulWidget {
  const SavedFilesPage({super.key});

  @override
  State<SavedFilesPage> createState() => _SavedFilesPageState();
}

class _SavedFilesPageState extends State<SavedFilesPage> {
  List<File> files = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadFiles();
  }

  Future<void> loadFiles() async {
    final result = await SavedFileService.getFiles();
    if (!mounted) return;
    setState(() {
      files = result;
      loading = false;
    });
  }

  Future<void> shareFile(File file) async {
    await Share.shareXFiles([XFile(file.path)], text: file.path.split(Platform.pathSeparator).last);
  }

  Future<void> deleteFile(File file) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('File Delete?'),
        content: const Text('શું તમે આ file delete કરવા માંગો છો?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      await SavedFileService.deleteFile(file);
      await loadFiles();
    }
  }

  String fileSize(File file) {
    try {
      final bytes = file.lengthSync();
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Files'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : files.isEmpty
              ? RefreshIndicator(
                  onRefresh: loadFiles,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 180),
                      Icon(Icons.folder_open, size: 70, color: Colors.grey),
                      SizedBox(height: 15),
                      Center(child: Text('હજુ કોઈ Saved File નથી.')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadFiles,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(15),
                    itemCount: files.length,
                    itemBuilder: (context, index) {
                      final file = files[index];
                      final name = file.path.split(Platform.pathSeparator).last;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFE3F2FD),
                            child: Icon(Icons.insert_drive_file, color: Color(0xFF1565C0)),
                          ),
                          title: Text(name, maxLines: 2, overflow: TextOverflow.ellipsis),
                          subtitle: Text(fileSize(file)),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'share') shareFile(file);
                              if (value == 'delete') deleteFile(file);
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'share', child: Text('Share')),
                              PopupMenuItem(value: 'delete', child: Text('Delete')),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await SavedFileService.pickAndSave();
          await loadFiles();
        },
        icon: const Icon(Icons.upload_file),
        label: const Text('Upload File'),
      ),
    );
  }
}

// ============================================================
// PDF SERVICE
// ============================================================

class PdfService {
  static Future<File> createPdf(
    Map<String, dynamic> record,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  'RUDRA SURVEYOR',
                  style: pw.TextStyle(
                    fontSize: 26,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Center(
                child: pw.Text(
                  'LAND SURVEY MEASUREMENT REPORT',
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 15),

              _pdfRow(
                'Owner Name',
                record['owner']?.toString() ?? '-',
              ),
              _pdfRow(
                'Mobile Number',
                record['mobile']?.toString() ?? '-',
              ),
              _pdfRow(
                'Village',
                record['village']?.toString() ?? '-',
              ),
              _pdfRow(
                'Taluka',
                record['taluka']?.toString() ?? '-',
              ),
              _pdfRow(
                'Survey Number',
                record['survey']?.toString() ?? '-',
              ),
              _pdfRow(
                'Survey Date',
                record['date']?.toString() ?? '-',
              ),

              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.SizedBox(height: 10),
              _pdfRow(
                'Total Payment',
                'Rs. ${record['payment'] ?? '0'}',
              ),
              if ((record['attachedFileName']?.toString() ?? '').isNotEmpty)
                _pdfRow(
                  'Attached File',
                  record['attachedFileName']!.toString(),
                ),

              pw.SizedBox(height: 30),

              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: PdfColors.grey,
                  ),
                ),
                child: pw.Text(
                  'This report is generated by RUDRA SURVEYOR application.',
                  style: const pw.TextStyle(
                    fontSize: 10,
                  ),
                ),
              ),

              pw.Spacer(),

              pw.Center(
                child: pw.Text(
                  'RUDRA SURVEYOR',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    final directory =
        await getApplicationDocumentsDirectory();

    final fileName =
        'RUDRA_SURVEY_${DateTime.now().millisecondsSinceEpoch}.pdf';

    final file = File(
      '${directory.path}/$fileName',
    );

    await file.writeAsBytes(
      await pdf.save(),
    );

    return file;
  }

  static pw.Widget _pdfRow(
    String title,
    String value,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Row(
        crossAxisAlignment:
            pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 150,
            child: pw.Text(
              title,
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value),
          ),
        ],
      ),
    );
  }

  static Future<void> previewPdf(
    Map<String, dynamic> record,
  ) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(30),
          build: (context) {
            return pw.Column(
              crossAxisAlignment:
                  pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    'RUDRA SURVEYOR',
                    style: pw.TextStyle(
                      fontSize: 26,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Center(
                  child: pw.Text(
                    'LAND SURVEY MEASUREMENT REPORT',
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Divider(),
                pw.SizedBox(height: 15),

                _pdfRow(
                  'Owner Name',
                  record['owner']?.toString() ?? '-',
                ),
                _pdfRow(
                  'Mobile Number',
                  record['mobile']?.toString() ?? '-',
                ),
                _pdfRow(
                  'Village',
                  record['village']?.toString() ?? '-',
                ),
                _pdfRow(
                  'Taluka',
                  record['taluka']?.toString() ?? '-',
                ),
                _pdfRow(
                  'Survey Number',
                  record['survey']?.toString() ?? '-',
                ),
                _pdfRow(
                  'Date',
                  record['date']?.toString() ?? '-',
                ),

                pw.SizedBox(height: 10),
                pw.Divider(),
                pw.SizedBox(height: 10),
                _pdfRow(
                  'Payment',
                  'Rs. ${record['payment'] ?? '0'}',
                ),
                if ((record['attachedFileName']?.toString() ?? '').isNotEmpty)
                  _pdfRow(
                    'Attached File',
                    record['attachedFileName']!.toString(),
                  ),

                pw.Spacer(),

                pw.Center(
                  child: pw.Text(
                    'Generated by RUDRA SURVEYOR',
                  ),
                ),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (format) async {
          return pdf.save();
        },
      );
    } catch (e) {
      debugPrint('PDF Preview Error: $e');
    }
  }

  static Future<void> sharePdf(
    Map<String, dynamic> record,
  ) async {
    try {
      final file = await createPdf(record);

      await Share.shareXFiles(
        [
          XFile(
            file.path,
            mimeType: 'application/pdf',
          ),
        ],
        subject: 'RUDRA SURVEYOR Land Survey Report',
        text: 'Land Survey Report - RUDRA SURVEYOR',
      );
    } catch (e) {
      debugPrint('PDF Share Error: $e');
    }
  }
}

// ============================================================
// DASHBOARD
// ============================================================

class Dashboard extends StatefulWidget {
  final Future<void> Function()? onLogout;

  const Dashboard({super.key, this.onLogout});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int currentIndex = 0;
  int totalRecords = 0;
  double totalPayment = 0;

  @override
  void initState() {
    super.initState();
    loadStats();
  }

  Future<void> loadStats() async {
    final records = await HistoryStore.getRecords();

    double payment = 0;

    for (final record in records) {
      payment +=
          double.tryParse(
                record['payment']?.toString() ?? '0',
              ) ??
              0;
    }

    if (!mounted) return;

    setState(() {
      totalRecords = records.length;
      totalPayment = payment;
    });
  }

  Future<void> openPage(Widget page) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => page,
      ),
    );

    await loadStats();
  }

  @override
  Widget build(BuildContext context) {
    if (currentIndex == 1) {
      return HistoryPage(
        onHome: () {
          setState(() {
            currentIndex = 0;
          });
          loadStats();
        },
      );
    }

    if (currentIndex == 2) {
      return MapPage(
        onHome: () {
          setState(() {
            currentIndex = 0;
          });
        },
      );
    }

    if (currentIndex == 3) {
      return ProfilePage(
        onHome: () {
          setState(() {
            currentIndex = 0;
          });
        },
        onLogout: widget.onLogout,
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'RUDRA SURVEYOR',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF123B68),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.settings_outlined,
              color: Color(0xFF123B68),
            ),
            onPressed: () {
              openPage(
                const SettingsPage(),
              );
            },
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: loadStats,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(24),
                gradient:
                    const LinearGradient(
                  colors: [
                    Color(0xFF1565C0),
                    Color(0xFF42A5F5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    padding:
                        const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(18),
                    ),
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(13),
                      child: Image.asset(
                        'assets/rudra_logo.jpg',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  const SizedBox(width: 15),

                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'નમસ્તે! 👋',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'RUDRA SURVEYOR માં આપનું સ્વાગત છે.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon:
                        Icons.description_outlined,
                    title: 'Records',
                    value:
                        '$totalRecords',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon:
                        Icons.currency_rupee,
                    title: 'Payment',
                    value:
                        '₹${totalPayment.toStringAsFixed(0)}',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            const Text(
              'Survey Operations',
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
                color:
                    Color(0xFF173A5E),
              ),
            ),

            const SizedBox(height: 12),

            OperationCard(
              number: 'OP1',
              title: 'જમીન માપણી નોંધ',
              description:
                  'માલિક, મોબાઇલ, ગામ, તાલુકો, સર્વે નંબર, તારીખ અને પેમેન્ટ નોંધો.',
              icon: Icons.edit_document,
              colors: const [
                Color(0xFF1565C0),
                Color(0xFF42A5F5),
              ],
              onTap: () {
                openPage(
                  const LandEntryPage(),
                );
              },
            ),

            const SizedBox(height: 12),

            OperationCard(
              number: 'OP2',
              title: 'GPS Survey',
              description:
                  'GPS દ્વારા સ્થાન અને survey સંબંધિત માહિતી.',
              icon: Icons.gps_fixed,
              colors: const [
                Color(0xFF00897B),
                Color(0xFF26A69A),
              ],
              onTap: () {
                openPage(
                  const GpsPage(),
                );
              },
            ),

            const SizedBox(height: 12),

            OperationCard(
              number: 'OP3',
              title: 'Unit Conversion',
              description:
                  'Length units અને જમીનના area units જેમ કે m² convert કરો.',
              icon: Icons.swap_horiz,
              colors: const [
                Color(0xFF7B1FA2),
                Color(0xFFAB47BC),
              ],
              onTap: () {
                openPage(
                  const UnitPage(),
                );
              },
            ),

            const SizedBox(height: 12),

            OperationCard(
              number: 'OP4',
              title: 'Area Calculator',
              description:
                  'લંબાઈ અને પહોળાઈ પરથી area ગણો.',
              icon: Icons.calculate,
              colors: const [
                Color(0xFFEF6C00),
                Color(0xFFFFA726),
              ],
              onTap: () {
                openPage(
                  const AreaPage(),
                );
              },
            ),

            const SizedBox(height: 12),

            OperationCard(
              number: 'FILES',
              title: 'Saved Files',
              description: 'Phoneમાં save કરેલી uploaded files જુઓ અને share કરો.',
              icon: Icons.folder_copy,
              colors: const [
                Color(0xFF37474F),
                Color(0xFF607D8B),
              ],
              onTap: () {
                openPage(const SavedFilesPage());
              },
            ),

            const SizedBox(height: 24),

            const Text(
              'Saved History',
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
                color:
                    Color(0xFF173A5E),
              ),
            ),

            const SizedBox(height: 12),

            InkWell(
              borderRadius:
                  BorderRadius.circular(22),
              onTap: () {
                setState(() {
                  currentIndex = 1;
                });
              },
              child: Container(
                padding:
                    const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        color:
                            const Color(0xFFE3F2FD),
                        borderRadius:
                            BorderRadius.circular(
                          16,
                        ),
                      ),
                      child: const Icon(
                        Icons.history,
                        color:
                            Color(0xFF1565C0),
                        size: 30,
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$totalRecords Records',
                            style:
                                const TextStyle(
                              fontSize: 17,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Total Payment: ₹${totalPayment.toStringAsFixed(0)}',
                            style:
                                const TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),

      bottomNavigationBar:
          NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected:
            (index) {
          setState(() {
            currentIndex = index;
          });

          if (index == 0) {
            loadStats();
          }
        },
        destinations: const [
          NavigationDestination(
            icon:
                Icon(Icons.home_outlined),
            selectedIcon:
                Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon:
                Icon(Icons.history_outlined),
            selectedIcon:
                Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon:
                Icon(Icons.map_outlined),
            selectedIcon:
                Icon(Icons.map),
            label: 'Map',
          ),
          NavigationDestination(
            icon:
                Icon(Icons.person_outline),
            selectedIcon:
                Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STAT CARD
// ============================================================

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color:
                  const Color(0xFFE3F2FD),
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color:
                  const Color(0xFF1565C0),
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                      const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// OPERATION CARD
// ============================================================

class OperationCard extends StatelessWidget {
  final String number;
  final String title;
  final String description;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  const OperationCard({
    super.key,
    required this.number,
    required this.title,
    required this.description,
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius:
          BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient:
              LinearGradient(
            colors: colors,
            begin:
                Alignment.topLeft,
            end:
                Alignment.bottomRight,
          ),
          borderRadius:
              BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color:
                    Colors.white.withOpacity(
                  0.20,
                ),
                borderRadius:
                    BorderRadius.circular(17),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 30,
              ),
            ),

            const SizedBox(width: 15),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    number,
                    style:
                        const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    title,
                    style:
                        const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style:
                        const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            const CircleAvatar(
              backgroundColor:
                  Colors.white,
              child: Icon(
                Icons.arrow_forward,
                color:
                    Color(0xFF1565C0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// OP1 - LAND ENTRY
// ============================================================

class LandEntryPage extends StatefulWidget {
  const LandEntryPage({super.key});

  @override
  State<LandEntryPage> createState() => _LandEntryPageState();
}

class _LandEntryPageState extends State<LandEntryPage> {
  final formKey = GlobalKey<FormState>();
  final owner = TextEditingController();
  final mobile = TextEditingController();
  final village = TextEditingController();
  final taluka = TextEditingController();
  final survey = TextEditingController();
  final payment = TextEditingController();

  DateTime date = DateTime.now();
  bool saving = false;
  String? selectedFileName;
  String? selectedFilePath;

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
    final result = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (result != null) {
      setState(() => date = result);
    }
  }

  Future<void> chooseFile() async {
    try {
      final file = await SavedFileService.pickAndSave();
      if (!mounted || file == null) return;
      setState(() {
        selectedFilePath = file.path;
        selectedFileName = file.path.split(Platform.pathSeparator).last;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File save error: $e')),
      );
    }
  }

  Future<void> save() async {
    if (saving) return;
    if (!formKey.currentState!.validate()) return;

    final pay = double.tryParse(payment.text.trim());
    if (pay == null || pay < 0) {
      _showMessage('પેમેન્ટ યોગ્ય રીતે લખો.');
      return;
    }

    setState(() => saving = true);

    final record = <String, dynamic>{
      'owner': owner.text.trim(),
      'mobile': mobile.text.trim(),
      'village': village.text.trim(),
      'taluka': taluka.text.trim(),
      'survey': survey.text.trim(),
      'payment': pay.toString(),
      'date': '${date.day}/${date.month}/${date.year}',
      'attachedFileName': selectedFileName ?? '',
      'attachedFilePath': selectedFilePath ?? '',
      'createdAt': DateTime.now().toIso8601String(),
    };

    try {
      await HistoryStore.addRecord(record);
      if (!mounted) return;
      setState(() => saving = false);

      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Save Successful ✅'),
          content: const Text('જમીન માપણીની નોંધ Saved History માં સાચવાઈ ગઈ છે.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      if (mounted) await showReportOptions(record);
    } catch (e) {
      if (!mounted) return;
      setState(() => saving = false);
      _showMessage('Record save કરવામાં error આવ્યો.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> showReportOptions(Map<String, dynamic> record) async {
    await showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Land Survey Report',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: const Text('PDF બનાવો / Preview'),
                onTap: () async {
                  Navigator.pop(context);
                  await PdfService.previewPdf(record);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share, color: Colors.green),
                title: const Text('PDF WhatsApp / Share'),
                onTap: () async {
                  Navigator.pop(context);
                  await PdfService.sharePdf(record);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('જમીન માપણી નોંધ'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const InfoBox(
              text: 'માહિતી Save કર્યા પછી Saved History માં રહેશે અને PDF Report બનાવી શકાશે.',
            ),
            const SizedBox(height: 16),
            AppField(controller: owner, label: 'માલિકનું નામ', icon: Icons.person),
            AppField(controller: mobile, label: 'મોબાઇલ નંબર', icon: Icons.phone, keyboard: TextInputType.phone),
            AppField(controller: village, label: 'ગામ', icon: Icons.location_city),
            AppField(controller: taluka, label: 'તાલુકો', icon: Icons.location_on),
            AppField(controller: survey, label: 'સર્વે નંબર', icon: Icons.numbers),
            const SizedBox(height: 5),
            InkWell(
              onTap: chooseDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'માપણીની તારીખ',
                  prefixIcon: Icon(Icons.calendar_month),
                  border: OutlineInputBorder(),
                ),
                child: Text('${date.day}/${date.month}/${date.year}'),
              ),
            ),
            const SizedBox(height: 15),
            AppField(
              controller: payment,
              label: 'કુલ પેમેન્ટ (₹)',
              icon: Icons.currency_rupee,
              keyboard: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.attach_file, color: Color(0xFF1565C0)),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Upload a File',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: chooseFile,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Upload'),
                  ),
                ],
              ),
            ),
            if (selectedFileName != null)
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(selectedFileName!, maxLines: 2, overflow: TextOverflow.ellipsis),
                    ),
                    IconButton(
                      onPressed: () => setState(() {
                        selectedFileName = null;
                        selectedFilePath = null;
                      }),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            SizedBox(
              height: 55,
              child: ElevatedButton.icon(
                onPressed: saving ? null : save,
                icon: saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  saving ? 'Saving...' : 'Save + PDF Report',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// HISTORY
// ============================================================

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
    final data =
        await HistoryStore.getRecords();

    if (!mounted) return;

    setState(() {
      records =
          data.reversed.toList();
    });
  }

  Future<void> delete(
    int displayIndex,
  ) async {
    final confirm =
        await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text(
            'Record Delete?',
          ),
          content: const Text(
            'શું તમે આ saved record delete કરવા માંગો છો?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child:
                  const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child:
                  const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    final originalIndex =
        records.length -
            1 -
            displayIndex;

    await HistoryStore
        .deleteRecord(
      originalIndex,
    );

    await load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text(
          'Saved History',
        ),
        backgroundColor:
            const Color(0xFF1565C0),
        foregroundColor:
            Colors.white,
        leading: IconButton(
          icon:
              const Icon(
            Icons.arrow_back,
          ),
          onPressed:
              widget.onHome,
        ),
      ),

      body: records.isEmpty
          ? const Center(
              child: Padding(
                padding:
                    EdgeInsets.all(30),
                child: Text(
                  'હજુ કોઈ જમીન માપણી નોંધ નથી.\n\nOP1 માં જઈને પ્રથમ record Save કરો.',
                  textAlign:
                      TextAlign.center,
                  style:
                      TextStyle(
                    fontSize: 18,
                  ),
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: load,
              child:
                  ListView.builder(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.all(
                  15,
                ),
                itemCount:
                    records.length,
                itemBuilder:
                    (context, index) {
                  final r =
                      records[index];

                  return Card(
                    margin:
                        const EdgeInsets.only(
                      bottom: 12,
                    ),
                    child:
                        Padding(
                      padding:
                          const EdgeInsets.all(
                        15,
                      ),
                      child:
                          Column(
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                backgroundColor:
                                    Color(
                                  0xFFE3F2FD,
                                ),
                                child:
                                    Icon(
                                  Icons.landscape,
                                  color:
                                      Color(
                                    0xFF1565C0,
                                  ),
                                ),
                              ),

                              const SizedBox(
                                width: 12,
                              ),

                              Expanded(
                                child:
                                    Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r['owner']
                                              ?.toString() ??
                                          '-',
                                      style:
                                          const TextStyle(
                                        fontSize:
                                            17,
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Survey No: ${r['survey'] ?? '-'}',
                                    ),
                                  ],
                                ),
                              ),

                              IconButton(
                                icon:
                                    const Icon(
                                  Icons.delete_outline,
                                  color:
                                      Colors.red,
                                ),
                                onPressed:
                                    () {
                                  delete(
                                    index,
                                  );
                                },
                              ),
                            ],
                          ),

                          const Divider(),

                          _historyRow(
                            'Location',
                            '${r['village'] ?? '-'}, ${r['taluka'] ?? '-'}',
                          ),

                          _historyRow(
                            'Area',
                            '${r['area'] ?? '0'} m²',
                          ),

                          _historyRow(
                            'Payment',
                            '₹${r['payment'] ?? '0'}',
                          ),

                          _historyRow(
                            'Date',
                            '${r['date'] ?? '-'}',
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          Row(
                            children: [
                              Expanded(
                                child:
                                    OutlinedButton.icon(
                                  onPressed:
                                      () {
                                    PdfService
                                        .previewPdf(
                                      r,
                                    );
                                  },
                                  icon:
                                      const Icon(
                                    Icons.picture_as_pdf,
                                  ),
                                  label:
                                      const Text(
                                    'PDF',
                                  ),
                                ),
                              ),

                              const SizedBox(
                                width: 10,
                              ),

                              Expanded(
                                child:
                                    ElevatedButton.icon(
                                  onPressed:
                                      () {
                                    PdfService
                                        .sharePdf(
                                      r,
                                    );
                                  },
                                  icon:
                                      const Icon(
                                    Icons.share,
                                  ),
                                  label:
                                      const Text(
                                    'Share',
                                  ),
                                  style:
                                      ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Colors.green,
                                    foregroundColor:
                                        Colors.white,
                                  ),
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
            ),
    );
  }

  Widget _historyRow(
    String title,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 7,
      ),
      child: Row(
        children: [
          Text(
            '$title: ',
            style:
                const TextStyle(
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          Expanded(
            child:
                Text(value),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// OP4 - AREA CALCULATOR
// ============================================================

class AreaPage extends StatefulWidget {
  const AreaPage({super.key});

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
    final l =
        double.tryParse(
              length.text,
            ) ??
            0;

    final w =
        double.tryParse(
              width.text,
            ) ??
            0;

    setState(() {
      area = l * w;
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
          'Area Calculator',
        ),
        backgroundColor:
            const Color(0xFFEF6C00),
        foregroundColor:
            Colors.white,
      ),

      body: ListView(
        padding:
            const EdgeInsets.all(16),
        children: [
          AppField(
            controller:
                length,
            label:
                'લંબાઈ (મીટર)',
            icon:
                Icons.straighten,
            keyboard:
                const TextInputType
                    .numberWithOptions(
              decimal: true,
            ),
          ),

          AppField(
            controller:
                width,
            label:
                'પહોળાઈ (મીટર)',
            icon:
                Icons.straighten,
            keyboard:
                const TextInputType
                    .numberWithOptions(
              decimal: true,
            ),
          ),

          const SizedBox(height: 10),

          ElevatedButton(
            onPressed:
                calculate,
            style:
                ElevatedButton.styleFrom(
              backgroundColor:
                  const Color(
                0xFFEF6C00,
              ),
              foregroundColor:
                  Colors.white,
            ),
            child:
                const Text(
              'Calculate Area',
            ),
          ),

          const SizedBox(height: 25),

          Center(
            child: Text(
              '${area.toStringAsFixed(2)} m²',
              style:
                  const TextStyle(
                fontSize: 32,
                fontWeight:
                    FontWeight.bold,
                color:
                    Color(0xFFEF6C00),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// OP3 - UNIT CONVERSION
// ============================================================

class UnitPage extends StatefulWidget {
  const UnitPage({super.key});

  @override
  State<UnitPage> createState() => _UnitPageState();
}

class _UnitPageState extends State<UnitPage> {
  final input = TextEditingController();
  String category = 'Area';
  String from = 'm²';
  String to = 'ft²';
  String result = '0';

  final lengthUnits = ['Meter', 'Feet', 'Inch', 'Yard'];
  final areaUnits = ['m²', 'ft²', 'Yard²', 'Acre', 'Hectare', 'Guntha'];

  double lengthToMeter(double value, String unit) {
    switch (unit) {
      case 'Feet': return value * 0.3048;
      case 'Inch': return value * 0.0254;
      case 'Yard': return value * 0.9144;
      default: return value;
    }
  }

  double meterToLength(double value, String unit) {
    switch (unit) {
      case 'Feet': return value / 0.3048;
      case 'Inch': return value / 0.0254;
      case 'Yard': return value / 0.9144;
      default: return value;
    }
  }

  double areaToSquareMeter(double value, String unit) {
    switch (unit) {
      case 'ft²': return value * 0.09290304;
      case 'Yard²': return value * 0.83612736;
      case 'Acre': return value * 4046.8564224;
      case 'Hectare': return value * 10000;
      case 'Guntha': return value * 101.17141056;
      default: return value;
    }
  }

  double squareMeterToArea(double value, String unit) {
    switch (unit) {
      case 'ft²': return value / 0.09290304;
      case 'Yard²': return value / 0.83612736;
      case 'Acre': return value / 4046.8564224;
      case 'Hectare': return value / 10000;
      case 'Guntha': return value / 101.17141056;
      default: return value;
    }
  }

  void convert() {
    final value = double.tryParse(input.text.trim()) ?? 0;
    double converted;
    if (category == 'Area') {
      final sqm = areaToSquareMeter(value, from);
      converted = squareMeterToArea(sqm, to);
    } else {
      final meters = lengthToMeter(value, from);
      converted = meterToLength(meters, to);
    }
    setState(() => result = converted.toStringAsFixed(4));
  }

  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final units = category == 'Area' ? areaUnits : lengthUnits;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unit Conversion'),
        backgroundColor: const Color(0xFF7B1FA2),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'Area', label: Text('Area'), icon: Icon(Icons.square_foot)),
              ButtonSegment(value: 'Length', label: Text('Length'), icon: Icon(Icons.straighten)),
            ],
            selected: {category},
            onSelectionChanged: (selection) {
              setState(() {
                category = selection.first;
                if (category == 'Area') {
                  from = 'm²';
                  to = 'ft²';
                } else {
                  from = 'Meter';
                  to = 'Feet';
                }
                result = '0';
              });
            },
          ),
          const SizedBox(height: 15),
          AppField(
            controller: input,
            label: 'Value',
            icon: Icons.numbers,
            keyboard: const TextInputType.numberWithOptions(decimal: true),
          ),
          DropdownButtonFormField<String>(
            value: from,
            decoration: const InputDecoration(labelText: 'From', border: OutlineInputBorder()),
            items: units.map((u) => DropdownMenuItem<String>(value: u, child: Text(u))).toList(),
            onChanged: (v) { if (v != null) setState(() => from = v); },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: to,
            decoration: const InputDecoration(labelText: 'To', border: OutlineInputBorder()),
            items: units.map((u) => DropdownMenuItem<String>(value: u, child: Text(u))).toList(),
            onChanged: (v) { if (v != null) setState(() => to = v); },
          ),
          const SizedBox(height: 15),
          ElevatedButton(onPressed: convert, child: const Text('Convert')),
          const SizedBox(height: 20),
          Center(
            child: Text(
              '$result $to',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF7B1FA2)),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// OP2 - GPS
// ============================================================

class GpsPage extends StatelessWidget {
  const GpsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text(
          'GPS Survey',
        ),
        backgroundColor:
            const Color(0xFF00897B),
        foregroundColor:
            Colors.white,
      ),

      body: Center(
        child: Padding(
          padding:
              const EdgeInsets.all(25),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.gps_fixed,
                size: 80,
                color:
                    Color(0xFF00897B),
              ),

              const SizedBox(
                  height: 15),

              const Text(
                'GPS Survey',
                style:
                    TextStyle(
                  fontSize: 24,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                  height: 10),

              const Text(
                'GPS boundary અને live location module આગળ connect કરી શકાય છે.',
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

// ============================================================
// MAP
// ============================================================

class MapPage extends StatelessWidget {
  final VoidCallback onHome;

  const MapPage({
    super.key,
    required this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Map'),
        backgroundColor:
            const Color(0xFF1565C0),
        foregroundColor:
            Colors.white,
        leading: IconButton(
          icon:
              const Icon(
            Icons.arrow_back,
          ),
          onPressed:
              onHome,
        ),
      ),

      body: const Center(
        child: Padding(
          padding:
              EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Icon(
                Icons.map,
                size: 80,
                color:
                    Color(0xFF1565C0),
              ),
              SizedBox(
                  height: 15),
              Text(
                'Survey Map Module',
                style:
                    TextStyle(
                  fontSize: 24,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              SizedBox(
                  height: 10),
              Text(
                'Map અને survey boundary module આગળ connect કરી શકાય છે.',
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

// ============================================================
// PROFILE
// ============================================================

class ProfilePage extends StatefulWidget {
  final VoidCallback onHome;
  final Future<void> Function()? onLogout;

  const ProfilePage({
    super.key,
    required this.onHome,
    this.onLogout,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? account;

  @override
  void initState() {
    super.initState();
    loadAccount();
  }

  Future<void> loadAccount() async {
    final data = await AccountStore.currentAccount();
    if (!mounted) return;
    setState(() => account = data);
  }

  @override
  Widget build(BuildContext context) {
    final name = account?['name']?.toString() ?? 'RUDRA SURVEYOR User';
    final mobile = account?['mobile']?.toString() ?? '';
    final photoPath = account?['photoPath']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onHome,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: photoPath.isNotEmpty && File(photoPath).existsSync()
                ? CircleAvatar(
                    radius: 62,
                    backgroundImage: FileImage(File(photoPath)),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset(
                      'assets/rudra_logo.jpg',
                      width: 120,
                      height: 120,
                      fit: BoxFit.contain,
                    ),
                  ),
          ),
          const SizedBox(height: 15),
          Center(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF123B68),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (mobile.isNotEmpty) ...[
            const SizedBox(height: 6),
            Center(
              child: Text(
                mobile,
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
          ],
          const SizedBox(height: 25),
          const ListTile(
            leading: Icon(Icons.support_agent),
            title: Text('Customer Care'),
            subtitle: Text('8487847474'),
          ),
          const ListTile(
            leading: Icon(Icons.person),
            title: Text('Customer Care Name'),
            subtitle: Text('Y.M. DHUNDHALAVA'),
          ),
          const SizedBox(height: 18),
          if (widget.onLogout != null)
            ElevatedButton.icon(
              onPressed: () async {
                await widget.onLogout!();
              },
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// SETTINGS
// ============================================================

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text(
          'Settings',
        ),
        backgroundColor:
            const Color(0xFF1565C0),
        foregroundColor:
            Colors.white,
      ),

      body: ListView(
        children: [
          ListTile(
            leading:
                Icon(
              Icons.language,
            ),
            title:
                Text(
              'Language',
            ),
            subtitle:
                Text(
              'ગુજરાતી / English',
            ),
          ),

          ListTile(
            leading:
                Icon(
              Icons.info_outline,
            ),
            title:
                Text(
              'About RUDRA SURVEYOR',
            ),
            subtitle:
                Text(
              'Professional Land Surveyor App',
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// APP FIELD
// ============================================================

class AppField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboard;
  final ValueChanged<String>? onChanged;

  const AppField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboard,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 14,
      ),
      child:
          TextFormField(
        controller:
            controller,
        keyboardType:
            keyboard,
        onChanged:
            onChanged,
        validator:
            (value) {
          if (value ==
                  null ||
              value
                  .trim()
                  .isEmpty) {
            return '$label લખો';
          }

          return null;
        },
        decoration:
            InputDecoration(
          labelText:
              label,
          prefixIcon:
              Icon(icon),
          border:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(
              14,
            ),
          ),
          filled:
              true,
          fillColor:
              Colors.white,
        ),
      ),
    );
  }
}

// ============================================================
// INFO BOX
// ============================================================

class InfoBox extends StatelessWidget {
  final String text;

  const InfoBox({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(15),
      decoration:
          BoxDecoration(
        color:
            const Color(0xFFE3F2FD),
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color:
                Color(0xFF1565C0),
          ),
          const SizedBox(
              width: 10),
          Expanded(
            child:
                Text(text),
          ),
        ],
      ),
    );
  }
}
