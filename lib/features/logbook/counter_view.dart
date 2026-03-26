// counter_view.dart
import 'package:flutter/material.dart';
import 'package:logbook_app_001/features/logbook/counter_controller.dart';
import 'package:logbook_app_001/features/onboarding/onboarding_view.dart';

class CounterView extends StatefulWidget {
  final String username;

  const CounterView({super.key, required this.username});

  @override
  State<CounterView> createState() => _CounterViewState();
}

class _CounterViewState extends State<CounterView> {
  late CounterController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CounterController(widget.username);
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _controller.loadData();
    setState(() {});
  }

  String getGreeting() {
    final hour = DateTime.now().hour;

    if (hour >= 6 && hour < 12) {
      return "Selamat Pagi";
    } else if (hour >= 12 && hour < 15) {
      return "Selamat Siang";
    } else if (hour >= 15 && hour < 18) {
      return "Selamat Sore";
    } else {
      return "Selamat Malam";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Logbook: ${widget.username}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        const OnboardingView()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "${getGreeting()}, ${widget.username} 👋",
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text(
                "Total Hitungan Anda",
                style: TextStyle(fontSize: 16),
              ),
              Text(
                "${_controller.value}",
                style: Theme.of(context)
                    .textTheme
                    .headlineLarge,
              ),
              const SizedBox(height: 30),
              const Text(
                "Riwayat Aktivitas",
                style: TextStyle(
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: _controller.history.length,
                  itemBuilder: (context, index) {
                    return Card(
                      child: Padding(
                        padding:
                            const EdgeInsets.all(8),
                        child: Text(
                            _controller.history[index]),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),

      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerFloat,

      floatingActionButton: SizedBox(
        width: double.infinity,
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            FloatingActionButton(
              heroTag: "dec",
              onPressed: () async {
                await _controller.decrement();
                setState(() {});
              },
              child: const Icon(Icons.remove),
            ),
            const SizedBox(width: 15),
            FloatingActionButton(
              heroTag: "reset",
              backgroundColor: Colors.orange,
              onPressed: () async {
                await _controller.reset();
                setState(() {});
              },
              child: const Icon(Icons.refresh),
            ),
            const SizedBox(width: 15),
            FloatingActionButton(
              heroTag: "inc",
              onPressed: () async {
                await _controller.increment();
                setState(() {});
              },
              child: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }
}
