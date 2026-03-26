// onboarding_view.dart
import 'package:flutter/material.dart';
import 'package:logbook_app_001/features/auth/login_view.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() =>
      _OnboardingViewState();
}

class _OnboardingViewState
    extends State<OnboardingView> {
  int currentPage = 0;

  final List<Map<String, String>> pages = [
    {
      "image": "assets/images/Doraemon.jpeg",
      "title": "Catat Aktivitas",
      "desc":
          "Simpan semua aktivitas harian Anda dengan mudah."
    },
    {
      "image": "assets/images/Spongebob.jpeg",
      "title": "Pantau Progress",
      "desc":
          "Lihat perkembangan aktivitas Anda setiap hari."
    },
    {
      "image": "assets/images/UpinIpin.jpeg",
      "title": "Lebih Produktif",
      "desc":
          "Bangun kebiasaan baik untuk masa depan."
    },
  ];

  void _next() {
    if (currentPage < pages.length - 1) {
      setState(() {
        currentPage++;
      });
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                const LoginView()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = pages[currentPage];

    return Scaffold(
      body: Center(
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Image.asset(
                page["image"]!,
                height: 250,
              ),
              const SizedBox(height: 30),
              Text(
                page["title"]!,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              Text(
                page["desc"]!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // PAGE INDICATOR
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: List.generate(
                  pages.length,
                  (index) => Container(
                    margin:
                        const EdgeInsets.symmetric(
                            horizontal: 4),
                    width: currentPage == index
                        ? 12
                        : 8,
                    height: currentPage == index
                        ? 12
                        : 8,
                    decoration: BoxDecoration(
                      color: currentPage ==
                              index
                          ? Colors.blue
                          : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _next,
                child: const Text("Lanjut"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
