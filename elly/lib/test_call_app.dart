import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

/// Standalone test application for verifying direct ACTION_CALL and tel: launcher behavior.
///
/// To execute this standalone test file independently:
///   flutter run -t lib/test_call_app.dart
void main() {
  runApp(const TestCallApp());
}

class TestCallApp extends StatelessWidget {
  const TestCallApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ACTION_CALL Direct Test',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF38BDF8),
          surface: Color(0xFF1E293B),
        ),
      ),
      home: const TestCallScreen(),
    );
  }
}

class TestCallScreen extends StatefulWidget {
  const TestCallScreen({super.key});

  @override
  State<TestCallScreen> createState() => _TestCallScreenState();
}

class _TestCallScreenState extends State<TestCallScreen> {
  static const MethodChannel _channel = MethodChannel('com.elly.elly/test_call');
  final TextEditingController _numberController = TextEditingController(text: '9876543210');

  String _statusMessage = 'Ready. Select a test action below.';
  bool _isPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionStatus();
  }

  Future<void> _checkPermissionStatus() async {
    final status = await Permission.phone.status;
    setState(() {
      _isPermissionGranted = status.isGranted;
    });
  }

  Future<void> _requestPhonePermission() async {
    final status = await Permission.phone.request();
    setState(() {
      _isPermissionGranted = status.isGranted;
      _statusMessage = 'Phone Permission status: ${status.name}';
    });
  }

  /// Direct Native Android Intent(Intent.ACTION_CALL) via MethodChannel
  Future<void> _testDirectActionCall(String number) async {
    setState(() {
      _statusMessage = 'Executing Native Intent.ACTION_CALL for $number...';
    });

    try {
      final String? result = await _channel.invokeMethod('makeCall', {
        'phoneNumber': number,
      });
      setState(() {
        _statusMessage = 'SUCCESS: $result';
      });
    } on PlatformException catch (e) {
      setState(() {
        _statusMessage = 'ERROR [${e.code}]: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'EXCEPTION: $e';
      });
    }
  }

  /// Flutter url_launcher tel: scheme test
  Future<void> _testUrlLauncherCall(String number) async {
    final Uri uri = Uri.parse('tel:$number');
    setState(() {
      _statusMessage = 'Launching url_launcher for $uri...';
    });

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        setState(() {
          _statusMessage = 'SUCCESS: Launched tel:$number via url_launcher';
        });
      } else {
        setState(() {
          _statusMessage = 'ERROR: Cannot launch tel:$number';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'EXCEPTION: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ACTION_CALL Direct Test'),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              color: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isPermissionGranted ? Icons.check_circle : Icons.warning_amber_rounded,
                          color: _isPermissionGranted ? Colors.green : Colors.amber,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Permission CALL_PHONE: ${_isPermissionGranted ? "GRANTED" : "NOT GRANTED"}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _isPermissionGranted ? Colors.green : Colors.amber,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Status Log:',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _statusMessage,
                      style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Number Input
            TextField(
              controller: _numberController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number to Call',
                hintText: 'Enter phone number (e.g. 9876543210 or 112)',
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _numberController.clear(),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Permission Button
            ElevatedButton.icon(
              onPressed: _requestPhonePermission,
              icon: const Icon(Icons.security),
              label: const Text('1. Request CALL_PHONE Permission'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.amber.shade700,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Option A: Direct Native ACTION_CALL (Bypasses Dialer)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF38BDF8)),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _testDirectActionCall(_numberController.text.trim()),
              icon: const Icon(Icons.call),
              label: Text('Native ACTION_CALL: "${_numberController.text.trim()}"'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () => _testDirectActionCall('112'),
              icon: const Icon(Icons.emergency),
              label: const Text('Native ACTION_CALL: "112" (Emergency)'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Option B: Standard url_launcher (ACTION_DIAL)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF38BDF8)),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _testUrlLauncherCall(_numberController.text.trim()),
              icon: const Icon(Icons.dialpad),
              label: Text('url_launcher tel: "${_numberController.text.trim()}"'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                side: const BorderSide(color: Color(0xFF38BDF8)),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _testUrlLauncherCall('112'),
              icon: const Icon(Icons.emergency_outlined),
              label: const Text('url_launcher tel: "112"'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                side: const BorderSide(color: Colors.redAccent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
