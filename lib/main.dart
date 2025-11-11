import 'package:flutter/material.dart';
import '../Pages/Danger_page.dart';
import '../Pages/Safe_page.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'dart:async'; 
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Call Screen',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1C1C1E),
      ),
      home: const CallScreen(),
    );
  }
}

// ========== 메인 통화 화면 (Safe/Danger 전환) ==========
class CallScreen extends StatefulWidget {
  const CallScreen({Key? key}) : super(key: key);

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  bool isDangerMode = false;
  bool isSerious = false;
  String condition = "0";
  void toggleMode() {
    if (condition == "1") {
      setState(() {
        isDangerMode = true;
      });
    }
    if (condition == "2") {
      setState(() {
        isDangerMode = true;
        isSerious = true;
      });
    }
    
  }

  void tabMode() {
    setState(() {
      isDangerMode = !isDangerMode;
    });    
  }

  final AudioRecorder audioRecorder = AudioRecorder();

  String? recordingPath;
  bool isRecording = false;
  bool isUploading = false;
  int number = 0;
  Timer? _recordingTimer; 

  @override
  void initState() {
    super.initState();

    // 5초마다 녹음 및 업로드 함수 실행
    _recordingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _recordAndUpload();
    });
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    super.dispose();
  }

  /// 🔹 기존 FloatingActionButton의 로직을 함수로 분리
  Future<void> _recordAndUpload() async {
    if (isUploading) return; // 업로드 중이면 중복 실행 방지

    if (isRecording) {
      // 녹음 중이면 중단하고 업로드
      audioRecorder.stop().then((filePath) {
        if (filePath != null) {
          setState(() {
            isRecording = false;
            recordingPath = filePath;
            number += 1;
          });

          debugPrint('녹음 종료 및 업로드 시작: $filePath');

          // 비동기 업로드, await 없이 실행
          sendAudioToServer(filePath);
        }
      });
    } else {
      // 녹음 시작
      if (await audioRecorder.hasPermission()) {
        final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
        final String fileName = "$number.mp3";
        final String filePath = p.join(appDocumentsDir.path, fileName);

        debugPrint("녹음 시작: $filePath");

        
        audioRecorder.start(
          const RecordConfig(),
          path: filePath,
        );

        setState(() {
          isRecording = true;
          recordingPath = null;
        });
      }
    }
  }

  // 🔹 기존 build 함수에는 FloatingActionButton 제거
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ========== 상단 모드 전환 버튼 ==========
            Container(
              width: double.infinity,
              margin:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: ElevatedButton(
                onPressed: tabMode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDangerMode ? Colors.red : Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                ),
                child: Text(
                  isDangerMode
                      ? '🚨 DANGER 모드 (탭하여 SAFE로 전환)'
                      : '✅ SAFE 모드 (탭하여 DANGER로 전환)',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),

            // ========== 조건부 렌더링 ==========
            Expanded(
              child: isDangerMode
                  ? DangerScreen()
                  : const SafeScreen(),
            ),

            // ========== 하단 공통 버튼 ==========
            _buildCommonFooter(),
          ],
        ),
      ),
    );
  }

  Future<void> sendAudioToServer(String filePath) async {
    setState(() {
      isUploading = true;
    });

    try {
      final uri = Uri.parse('http://192.168.35.3:8000/uploadAudio');

      var request = http.MultipartRequest('POST', uri);
      var audioFile = await http.MultipartFile.fromPath(
        'file',
        filePath,
        filename: p.basename(filePath),
      );
      request.files.add(audioFile);

      request.fields['recording_number'] = number.toString();
      request.fields['timestamp'] = DateTime.now().toIso8601String();

      var response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = response.stream.bytesToString();
        debugPrint('✅ 업로드 성공: $responseBody');
        setState(() {
          condition = responseBody.toString();
        });
        toggleMode(); //모드전환 검토
      } else {
        debugPrint('❌ 업로드 실패: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('🚨 업로드 중 오류: $e');
    } finally {
      if (mounted) {
        setState(() {
          isUploading = false;
        });
      }
    }
  }

  // 공통 하단 영역
  Widget _buildCommonFooter() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 20,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white38,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildControlButton(Icons.volume_up, '스피커'),
              _buildControlButton(Icons.bluetooth, '블루투스'),
              _buildControlButton(Icons.dialpad, '키패드'),
              _buildControlButton(Icons.voicemail, '00:01', isRecording: true),
              _buildControlButton(Icons.mic_off, '차단'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: 60,
          height: 60,
          decoration: const BoxDecoration(
            color: Color(0xFFE85D5D),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.call_end,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildControlButton(IconData icon, String label,
      {bool isRecording = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isRecording
                ? const Color(0xFF4A5568)
                : const Color(0xFF3A3A3C),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}
