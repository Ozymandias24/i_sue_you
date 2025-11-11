import 'package:flutter/material.dart';
import '../Pages/Danger_page.dart';
import '../Pages/Safe_page.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
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
  bool isDangerMode = false; // false = Safe 모드, true = Danger 모드

  // 백엔드 신호를 시뮬레이션하는 함수 (나중에 실제 API로 교체)
  void toggleMode() {
    setState(() {
      isDangerMode = !isDangerMode;
    });
  }

  final AudioRecorder audioRecorder = AudioRecorder();

  String? recordingPath;
  bool isRecording = false;
  bool isUploading = false;
  int number = 0;



  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: isUploading ? null : () async {
        if (isRecording) {
          String? filePath = await audioRecorder.stop();
          if (filePath != null) {
            setState(() {
              isRecording = false;
              recordingPath = filePath;
              number += 1;
            });

            debugPrint(number.toString());
            // Send the recorded file to server
            await sendAudioToServer(filePath);
          }
        }
        else {
          if (await audioRecorder.hasPermission()) {

            final Directory appDocumentsDir =
            await getApplicationDocumentsDirectory();
            debugPrint("file "+appDocumentsDir.path);

            // Use unique filename with timestamp
            final String fileName = "${number}.mp3";
            final String filePath = p.join(appDocumentsDir.path, fileName);



            debugPrint("file "+fileName+" saved at: "+filePath);

            await audioRecorder.start(
              const RecordConfig(),
              path: filePath,
            );

            setState(() {
              isRecording = true;
              recordingPath = null;
            });
          }
        }
      },
      child: Icon(
        isRecording ? Icons.stop : Icons.mic,
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ========== 상단 모드 전환 버튼 (테스트용) ==========
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: ElevatedButton(
                onPressed: toggleMode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDangerMode ? Colors.red : Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                ),
                child: Text(
                  isDangerMode ? '🚨 DANGER 모드 (탭하여 SAFE로 전환)' : '✅ SAFE 모드 (탭하여 DANGER로 전환)',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),

            // ========== 조건부 렌더링: Safe 또는 Danger 화면 ==========
            Expanded(
              child: isDangerMode
                  ?  DangerScreen() // Danger 모드
                  : const SafeScreen(),  // Safe 모드
            ),

            // ========== 공통 하단 버튼들 ==========
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
      // Replace with your server URL
      final uri = Uri.parse('http://192.168.1.164:8000/uploadAudio');

      // Create multipart request
      var request = http.MultipartRequest('POST', uri);

      // Add the audio file
      var audioFile = await http.MultipartFile.fromPath(
        'file', // Field name expected by your server
        filePath,
        filename: p.basename(filePath),
      );
      request.files.add(audioFile);

      // Add additional fields if needed
      request.fields['recording_number'] = number.toString();
      request.fields['timestamp'] = DateTime.now().toIso8601String();

      // Optional: Add authentication headers
      // request.headers['Authorization'] = 'Bearer YOUR_TOKEN';

      // Send the request
      var response = await request.send();

      if (response.statusCode == 200) {
        // Success
        final responseBody = await response.stream.bytesToString();
        debugPrint('Upload successful: $responseBody');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Audio uploaded successfully!')),
          );
        }
      } else {
        // Error
        debugPrint('Upload failed: ${response.statusCode}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Upload failed: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error uploading audio: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isUploading = false;
        });
      }
    }
  }

  // 공통 하단 영역 (페이지 인디케이터, 컨트롤 버튼, 종료 버튼)
  Widget _buildCommonFooter() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 페이지 인디케이터
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

        // 하단 컨트롤 버튼
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

        // 종료 버튼
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

  Widget _buildControlButton(IconData icon, String label, {bool isRecording = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isRecording ? const Color(0xFF4A5568) : const Color(0xFF3A3A3C),
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

