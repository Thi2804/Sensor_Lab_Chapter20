import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:light_sensor/light_sensor.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sensor Lab Chapter 20',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

// Màn hình chính chứa Menu
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const MotionTracker(),
    const ExplorerTool(),
    const LightMeter(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.vibration), label: 'Motion'),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explorer'),
          BottomNavigationBarItem(icon: Icon(Icons.light_mode), label: 'Light'),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// BÀI 1: MOTION TRACKER (Đo chuyển động)
// ---------------------------------------------------------
class MotionTracker extends StatefulWidget {
  const MotionTracker({super.key});
  @override
  State<MotionTracker> createState() => _MotionTrackerState();
}

class _MotionTrackerState extends State<MotionTracker> {
  int _shakeCount = 0;
  static const double _shakeThreshold = 15.0;
  DateTime _lastShakeTime = DateTime.now();
  Color _bgColor = Colors.blueGrey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(title: const Text("Motion Tracker"), backgroundColor: Colors.transparent, elevation: 0),
      body: StreamBuilder<UserAccelerometerEvent>(
        stream: userAccelerometerEventStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: Text("Đang chờ cảm biến...", style: TextStyle(color: Colors.white)));
          }

          final event = snapshot.data!;
          double acceleration = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

          if (acceleration > _shakeThreshold) {
            final now = DateTime.now();
            if (now.difference(_lastShakeTime).inMilliseconds > 500) {
              _lastShakeTime = now;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _shakeCount++;
                    _bgColor = Colors.primaries[Random().nextInt(Colors.primaries.length)];
                  });
                }
              });
            }
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.vibration, size: 80, color: Colors.white),
                const SizedBox(height: 20),
                Text("SHAKE COUNT: $_shakeCount",
                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 20),
                Text("Gia tốc: ${acceleration.toStringAsFixed(2)} m/s²",
                    style: const TextStyle(color: Colors.white70)),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------
// BÀI 2: EXPLORER TOOL (GPS + La bàn)
// ---------------------------------------------------------
class ExplorerTool extends StatefulWidget {
  const ExplorerTool({super.key});
  @override
  State<ExplorerTool> createState() => _ExplorerToolState();
}

class _ExplorerToolState extends State<ExplorerTool> {
  String _locationMessage = "Đang lấy vị trí...";

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) setState(() => _locationMessage = "Hãy bật GPS!");
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) setState(() => _locationMessage = "Quyền vị trí bị từ chối.");
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    if (mounted) {
      setState(() {
        _locationMessage =
        "Lat: ${position.latitude.toStringAsFixed(4)}\nLong: ${position.longitude.toStringAsFixed(4)}\nAlt: ${position.altitude.toStringAsFixed(1)}m";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text("Explorer Tool"), backgroundColor: Colors.grey[900], foregroundColor: Colors.white),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            color: Colors.blueGrey[900],
            child: Text(_locationMessage,
                style: const TextStyle(color: Colors.greenAccent, fontSize: 18, fontFamily: 'monospace'),
                textAlign: TextAlign.center),
          ),
          Expanded(
            child: StreamBuilder<MagnetometerEvent>(
              stream: magnetometerEventStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final event = snapshot.data!;
                double heading = atan2(event.y, event.x);
                double headingDegrees = heading * 180 / pi;
                if (headingDegrees < 0) headingDegrees += 360;

                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("${headingDegrees.toStringAsFixed(0)}°",
                          style: const TextStyle(color: Colors.white, fontSize: 50, fontWeight: FontWeight.bold)),
                      const Text("HƯỚNG BẮC", style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 30),
                      Transform.rotate(
                        angle: -heading, // Xoay la bàn
                        child: const Icon(Icons.navigation, size: 150, color: Colors.redAccent),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// BÀI 3: LIGHT METER (Đã sửa để test trên máy ảo)
// ---------------------------------------------------------
class LightMeter extends StatefulWidget {
  const LightMeter({super.key});
  @override
  State<LightMeter> createState() => _LightMeterState();
}

class _LightMeterState extends State<LightMeter> {
  int _luxValue = 0;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  void _startListening() async {
    try {
      final hasSensor = await LightSensor.hasSensor();
      if (hasSensor) {
        _subscription = LightSensor.luxStream().listen((lux) {
          if (mounted) setState(() => _luxValue = lux);
        });
      }
    } catch (e) {
      debugPrint("Lỗi cảm biến ánh sáng: $e");
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  String getLightStatus(int lux) {
    if (lux < 10) return "TỐI OM (Phòng kín)";
    if (lux < 500) return "SÁNG VỪA (Trong nhà)";
    return "RẤT SÁNG (Ngoài trời)";
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = _luxValue < 50;

    // SỬA: Bọc GestureDetector để giả lập ánh sáng khi chạm vào màn hình
    return Scaffold(
      backgroundColor: isDark ? Colors.black87 : Colors.white,
      appBar: AppBar(
        title: const Text("Light Meter"),
        backgroundColor: isDark ? Colors.black : Colors.blue,
        foregroundColor: isDark ? Colors.white : Colors.black,
      ),
      body: GestureDetector(
        onTap: () {
          // LOGIC GIẢ LẬP: Bấm vào thì đổi giá trị LUX
          setState(() {
            if (_luxValue == 0) {
              _luxValue = 800; // Giả vờ ra ngoài trời
            } else {
              _luxValue = 0;   // Giả vờ tắt đèn
            }
          });
        },
        child: Container(
          color: Colors.transparent, // Để bắt sự kiện chạm toàn màn hình
          width: double.infinity,
          height: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lightbulb, size: 100, color: isDark ? Colors.grey : Colors.orangeAccent),
              const SizedBox(height: 20),
              Text("$_luxValue LUX",
                  style: TextStyle(fontSize: 60, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
              Text(getLightStatus(_luxValue),
                  style: TextStyle(fontSize: 24, color: isDark ? Colors.white70 : Colors.black54)),
              const SizedBox(height: 40),
              const Text(
                "(Chạm màn hình để đổi Sáng/Tối)",
                style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}