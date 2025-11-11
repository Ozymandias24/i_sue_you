import 'package:flutter/material.dart';
import '../main.dart';


class SafeScreen extends StatelessWidget {
  const SafeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 상단 타이머 및 HD Voice
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text(
                '00:02',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              SizedBox(width: 8),
              Text(
                '|',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 14,
                ),
              ),
              SizedBox(width: 8),
              Text(
                'HD Voice',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // 프로필 아이콘
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFF3A3A3C),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.person,
            size: 40,
            color: Colors.white70,
          ),
        ),

        const SizedBox(height: 20),

        // 전화번호
        const Text(
          '010-',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w300,
          ),
        ),

        const SizedBox(height: 40),

        // 통계 정보
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

        const SizedBox(height: 24),

        // 알림 배너
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24.0),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: const Color(0xFF3A3A3C),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      '어보이드패싱 어플리케이션이 통화 상황을 분석 중입니다!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '통화 내용은 AI가 분석합니다. 만화, 음악 등 보이스피싱으로 추정되는 내용이 있을 경우 어보이드패싱에서 대처법을 알려드리겠습니다!',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const Spacer(),
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
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}