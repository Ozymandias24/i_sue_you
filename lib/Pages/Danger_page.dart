import 'package:flutter/material.dart';

// ========== DANGER 모드 화면 ==========
class DangerScreen extends StatefulWidget {
  const DangerScreen({Key? key}) : super(key: key);

  @override
  State<DangerScreen> createState() => _DangerScreenState();
}

class _DangerScreenState extends State<DangerScreen> {
  final List<String> _protocols = [
    '1. 주민등록번호, 카드번호, 계좌번호 등을 물어본다면, 이러한 개인정보가 어디에 쓰이는지 질문하세요.',
    '2. 자신이 가족 구성원이라고 주장한다면, 가족들과 알고 있는 비밀을 물어서 정말 가족인지 확인하세요.',
    '3. 법적에 연루된 경우에는 전화로 연락하지 않습니다. 경찰서에 방문하겠다고 말하세요.',
    '4. 가족을 폭행했거나 납치했다고 말한다면, 즉시 경찰에게 신고하세요. 지시에 따르지 마세요.',
    '5. 알 수 없는 앱을 설치하라고 지시한다면, 앱의 용도를 묻고, 지시에 따르지 마세요.',
    '6. 은행 직원이 현금을 받기 위해 직접 방문하지는 않습니다. 현금을 제공하지 마세요.',
  ];

  int _currentIndex = 0;

  void _nextProtocol() {
    setState(() {
      _currentIndex = (_currentIndex + 1) % _protocols.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 상단 타이머 및 HD Voice (축소)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text(
                '00:02',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              SizedBox(width: 6),
              Text(
                '|',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                ),
              ),
              SizedBox(width: 6),
              Text(
                'HD Voice',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        // 프로필 및 전화번호 (가로 배치)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF3A3A3C),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  size: 28,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                '010-',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 통계 정보 (축소)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem('최근 6개월 통화', '0회'),
              _buildStatItem('마지막 통화', '8개월 전'),
              _buildStatItem('평균 통화시간', '1분 이내'),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 경고 알림 배너
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24.0),
          padding: const EdgeInsets.all(14.0),
          decoration: BoxDecoration(
            color: const Color(0xFF3A3A3C),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.dangerous,
                  color: Colors.redAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      '통화내용이 보이스피싱으로 의심됩니다.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      '통화 내용은 AI가 분석합니다. 통화내용에서 보이스피싱으로 추정되는 내용이 있을 경우 어보이드피싱에서 대처법을 알려드리겠습니다!',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 보이스피싱 대처 프로토콜 박스
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24.0),
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: const Color(0xFF5C2C2C),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                // 탭 가능한 프로토콜 표시 영역
                Expanded(
                  child: GestureDetector(
                    onTap: _nextProtocol,
                    child: Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7D3F3F),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          _protocols[_currentIndex],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 페이지 인디케이터
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _protocols.length,
                        (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentIndex == index
                            ? Colors.white
                            : Colors.white38,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),


              ],
            ),
          ),
        ),

        const SizedBox(height: 5),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 9,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}