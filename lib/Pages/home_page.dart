import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const HomeScreen();
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 화면 크기 1080x2220 기준
    return Scaffold(
      body: Container(
        width: 1080,
        height: 2220,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF3E5F5), // 연한 핑크
              Color(0xFFE1BEE7), // 연한 보라
              Color(0xFFCE93D8), // 보라
              Color(0xFFBA68C8), // 진한 보라
              Color(0xFF9575CD), // 보라-블루
              Color(0xFF7986CB), // 블루-보라
              Color(0xFF64B5F6), // 밝은 블루
              Color(0xFF42A5F5), // 블루
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [


              // 로고 이미지
              Container(
                alignment: Alignment.topCenter,
                padding: const EdgeInsets.all(16.0),
                child: Image.asset(
                  'assets/avoidphishing_logo.png',
                  width: 300, // 로고 크기 조정 가능
                  height: 300,
                  fit: BoxFit.contain,
                ),
              ),
              
              // 설명 텍스트
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: const Text(
                  '어보이드피싱은 접근성이 높고 간편한\n 보이스피싱 예방 프로그램입니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 23,
                    color: Colors.white,
                    height: 1.5,
                    shadows: [
                      Shadow(
                        color: Colors.black12,
                        offset: Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 48),

              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/call');
                },
                child: Row(
                  children: [
                    Icon(Icons.phone),
                    const Text(
                      '통화화면으로 이동',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        height: 1.0,
                        shadows: [
                          Shadow(
                            color: Colors.black12,
                            offset: Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 70,),

              // 하단 푸터
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Developed by team SA',
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),

                    Image(image: AssetImage('assets/SADA_logo.png'), width: 120),
                  ],
                ),
              ),

            ],
          ),
        ),
      ),


    );
  }
}