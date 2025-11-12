import 'package:flutter/material.dart';
import '../Pages/Danger_page.dart';
import '../Pages/Safe_page.dart';
import '../Pages/home_page.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'dart:async'; 
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:audioplayers/audioplayers.dart';

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
      home: const HomePage(), // 시작 페이지
      routes: {
        '/call': (context) => const CallScreen(),
      },
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
  final AudioPlayer _fx = AudioPlayer(); // 효과음용 단일 플레이어


  Future<void> _playToggleFx({required bool toDanger, required bool isSerious}) async {
    try {
      // 이전 재생 중이면 정지 후 재생 (겹침 방지)
      await _fx.stop();
      // 필요하면 볼륨 조정 (0.0 ~ 1.0)
      await _fx.setVolume(1.0);

      String assetPath;
      if (toDanger||isSerious) {
        assetPath = 'assets/Dangerous.mp3';
      }
      else{
        assetPath = 'assets/Safe.mp3';
      }


      await _fx.play(AssetSource(assetPath.replaceFirst('assets/', '')));
      // 참고: AssetSource 는 pubspec에 등록된 경로 기준(assets/는 빼고 적음)
      // 위에서 replaceFirst로 자동 변환
    } catch (e) {
      debugPrint('🎵 효과음 재생 실패: $e');
    }
  }

  void toggleMode() {
    // 🔸 현재 상태 저장
    final wasDanger = isDangerMode;
    final wasSerious = isSerious;

    // 🔸 조건->다음 상태 계산 (화면 전환 로직과 동일)
    bool nextDanger = false;
    bool nextSerious = false;

    if (condition == "1") {
      nextDanger = true;
      nextSerious = false;
    } else if (condition == "2") {
      nextDanger = true;
      nextSerious = true;
    } else if (condition == "0") {
      nextDanger = false;
      nextSerious = false;
    }

    // 🔸 실제 상태 반영
    setState(() {
      isDangerMode = nextDanger;
      isSerious   = nextSerious;
    });

    // 🔸 "전환"이 발생했을 때만 효과음 재생
    final changed = (wasDanger != nextDanger) || (wasSerious != nextSerious);
    if (changed) {
      _playToggleFx(toDanger: nextDanger, isSerious: nextSerious);
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
  // 상단 import 유지
// import 'package:path_provider/path_provider.dart';
// import 'package:path/path.dart' as p;
// import 'dart:io';

  Future<void> _rotate() async {
    // 1) 권한 확인
    final granted = await audioRecorder.hasPermission();
    debugPrint("🎤 녹음 권한 상태: $granted");
    if (!granted) {
      debugPrint("🚫 녹음 권한 없음 - 에뮬레이터 마이크/권한 설정 확인 필요");
      return;
    }

    // 2) 안전한 저장 경로(앱 임시 디렉토리) + 올바른 확장자/인코딩
    final dir = await getTemporaryDirectory();
    final nextPath = p.join(dir.path, "${number + 1}.m4a");

    // 3) 회전 로직
    if (isRecording) {
      final prevPath = await audioRecorder.stop();

      // 바로 다음 세그먼트 시작 (공백 최소화)
      await audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc, // ✔ AAC
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: nextPath,
      );

      setState(() {
        isRecording = true;
        recordingPath = nextPath;
        number += 1;
      });

      // 이전 세그먼트 업로드 (파일 크기 확인)
      if (prevPath != null) {
        final f = File(prevPath);
        final len = await f.length();
        debugPrint("업로드 전 파일 크기: $len bytes - $prevPath");
        if (len > 1024) {
          // 1KB 이하(사실상 빈 파일)면 업로드 생략
          sendAudioToServer(prevPath);
        } else {
          debugPrint("⚠️ 파일이 비어 업로드 생략: $prevPath");
        }
      }
    } else {
      await audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: nextPath,
      );

      setState(() {
        isRecording = true;
        recordingPath = nextPath;
        number += 1;
      });
    }





    @override
    void dispose() {
      _recordingTimer?.cancel();
      _fx.dispose(); // 🔹 리소스 정리
      super.dispose();
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
    if (mounted) {
      setState(() => isUploading = true);
    }

    try {
      final f = File(filePath);
      if (!await f.exists()) {
        debugPrint("❌ 파일 없음: $filePath");
        return;
      }
      final len = await f.length();
      if (len <= 1024) {
        debugPrint("⚠️ 너무 작은 파일(빈 파일로 간주) 업로드 생략: $len bytes");
        return;
      }

      final uri = Uri.parse('http://192.168.35.3:8000/uploadAudio');
      final request = http.MultipartRequest('POST', uri);

      // 확장자 .m4a로 보낼 것
      final mf = await http.MultipartFile.fromPath(
        'file',
        filePath,
        filename: p.basename(filePath),
        // contentType 힌트를 주면 일부 서버에서 인식이 더 안정적
        // import 'package:http_parser/http_parser.dart';
        contentType: MediaType('audio', 'mp4'), // m4a는 컨테이너가 mp4 계열
      );

      request.files.add(mf);
      request.fields['recording_number'] = number.toString();
      request.fields['timestamp'] = DateTime.now().toIso8601String();

      final response = await request.send();
      if (response.statusCode == 200) {
        final body = await response.stream.bytesToString();
        debugPrint('✅ 업로드 성공: $body');
        if (mounted) {
          setState(() => condition = body.toString());
          toggleMode();
        }
      } else {
        debugPrint('❌ 업로드 실패: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('🚨 업로드 중 오류: $e');
    } finally {
      if (mounted) setState(() => isUploading = false);
    }
  }


  Future<void> sttGet(BuildContext context) async {
  try {
    final uri_stt = Uri.parse('http://192.168.35.3:8000/sttGet');
    final response = await http.get(uri_stt);

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
        // 끊기 버튼
        GestureDetector(
          onTap: () {
            Navigator.pop(context); // 홈으로 돌아감
          },
          child: Container(
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
        )

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


