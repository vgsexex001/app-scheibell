import 'package:flutter/material.dart';

class TelaOnboarding2 extends StatelessWidget {
  const TelaOnboarding2({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/onboarding_screen.png'),
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            colorFilter: ColorFilter.matrix([
              0.9, 0.1, 0.0, 0, 0,
              0.1, 0.9, 0.0, 0, 0,
              0.1, 0.1, 0.8, 0, 0,
              0, 0, 0, 1, 0,
            ]),
          ),
        ),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.transparent,
                Colors.transparent,
                Colors.white.withOpacity(0.85),
                Colors.white,
              ],
              stops: const [0.0, 0.5, 0.6, 0.75, 0.88],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: TextButton(
                        onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                        child: const Text(
                          'Pular',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            shadows: [
                              Shadow(color: Colors.black45, blurRadius: 4),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'Chat inteligente ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                            shadows: [
                              Shadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 2)),
                            ],
                          ),
                        ),
                        TextSpan(
                          text: 'para suas dúvidas',
                          style: TextStyle(
                            color: Color(0xFF4F4A34),
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'Tire dúvidas 24/7 com nossa assistente virtual',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFF1A1A1A),
                        fontSize: size.width * 0.055,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pushReplacementNamed(context, '/onboarding'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF4F4A34),
                              side: const BorderSide(
                                color: Color(0xFF4F4A34),
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Anterior',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pushReplacementNamed(context, '/onboarding3'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4F4A34),
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Próximo',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
