import 'package:flutter/material.dart';
import '../Pages/Danger_page.dart';
import '../Pages/Safe_page.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'dart:async'; 
import 'dart:convert';
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
    if (condition == "0") {
      setState(() {
        isDangerMode = false;
        isSerious = false;
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

  // 최초 1회 즉시 시작 → 틱 사이 공백 제거
  _rotate(); 

  // 이후 주기적으로 "종료→즉시 재시작" 수행
  _recordingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
    _rotate();
  });
}

  @override
  void dispose() {
    _recordingTimer?.cancel();
    super.dispose();
  }

  
  /// 녹음 세그먼트 회전: (1) 진행 중이면 stop → 즉시 새 파일로 start, 이전 파일 업로드
  ///                   (2) 미진행이면 즉시 start
  void _rotate() {
    if (isRecording) {
      audioRecorder.stop().then((prevPath) {
        if (prevPath != null) {
          // 다음 세그먼트 즉시 시작 (공백 0)
          final String dirPath = '/storage/emulated/0/Download'; // 필요시 변경
          final String nextName = "${number + 1}.mp3";
          final String nextPath = p.join(dirPath, nextName);

          audioRecorder
              .start(const RecordConfig(), path: nextPath)
              .then((_) {
            setState(() {
              isRecording = true;
              recordingPath = null;
              number += 1;
            });
          });

          // 이전 세그먼트 업로드는 병렬 처리
          sendAudioToServer(prevPath);
        } else {
          // stop 실패 시 안전하게 재시작 시도
          final String dirPath = '/storage/emulated/0/Download';
          final String nextName = "${number + 1}.mp3";
          final String nextPath = p.join(dirPath, nextName);
          audioRecorder.hasPermission().then((granted) {
            if (!granted) return;
            audioRecorder.start(const RecordConfig(), path: nextPath).then((_) {
              setState(() {
                isRecording = true;
                recordingPath = null;
                number += 1;
              });
            });
          });
        }
      });
    } 
    else {
      audioRecorder.hasPermission().then((granted) {
        if (!granted) return;
        final String dirPath = '/storage/emulated/0/Download';
        final String fileName = "${number + 1}.mp3";
        final String filePath = p.join(dirPath, fileName);

        audioRecorder.start(const RecordConfig(), path: filePath).then((_) {
          setState(() {
            isRecording = true;
            recordingPath = null;
            number += 1;
          });
        });
      });
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

  void sendAudioToServer(String filePath) {
    if (mounted) {
      setState(() {
        isUploading = true;
      });
    }

    try {
      final uri = Uri.parse('http://192.168.35.3:8000/uploadAudio');

      // MultipartRequest 객체 생성 (동기)
      var request = http.MultipartRequest('POST', uri);

      // 파일 추가 (비동기 Future)
      http.MultipartFile.fromPath(
        'file',
        filePath,
        filename: p.basename(filePath),
      ).then((audioFile) {
        request.files.add(audioFile);

        request.fields['recording_number'] = number.toString();
        request.fields['timestamp'] = DateTime.now().toIso8601String();

        // 실제 전송 (비동기)
        request.send().then((response) {
          if (response.statusCode == 200) {
            response.stream.bytesToString().then((responseBody) {
              debugPrint('✅ 업로드 성공: $responseBody');
              if (mounted) {
                setState(() {
                  condition = responseBody.toString();
                });
                toggleMode(); // 모드 전환
              }
            });
          } else {
            debugPrint('❌ 업로드 실패: ${response.statusCode}');
          }
        });
      });
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


Future<void> sttGet(BuildContext context) async {
  try {
    final uri = Uri.parse('http://192.168.35.3:8000/sttGet');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      // 서버에서 받은 텍스트를 디코딩 (utf-8 고려)
      final String sttText = utf8.decode(response.bodyBytes);

      // 새 페이지로 이동
      
    } else {
      debugPrint('❌ STT 요청 실패: ${response.statusCode}');
      _showSnackBar(context, '서버 응답 오류: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('🚨 STT 요청 중 예외 발생: $e');
    _showSnackBar(context, '서버 연결 실패: $e');
  }
}


void _showSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.redAccent,
    ),
  );
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
