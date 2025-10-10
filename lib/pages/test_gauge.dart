import 'dart:math';
import 'package:flutter/material.dart';
import '../shared/widgets/stat_gauge.dart';

class TestGaugePage extends StatefulWidget {
  const TestGaugePage({Key? key}) : super(key: key);

  @override
  State<TestGaugePage> createState() => _TestGaugePageState();
}

class _TestGaugePageState extends State<TestGaugePage> {
  double _percentage = 0;

  @override
  void initState() {
    super.initState();
    _refreshGauge();
  }

  void _refreshGauge() {
    setState(() {
      _percentage = Random().nextInt(90) + 10; // random 2 digit percentage (10-99)
    });
  }

  @override
  Widget build(BuildContext context) {
    // Match the gauge size from dashboard_page.dart (e.g., 240x240)
    return Scaffold(
      appBar: AppBar(title: const Text('Test StatGauge Needle Position')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300, width: 2),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.grey.shade100,
                            Colors.grey.shade300,
                          ],
                        ),
                      ),
                      child: StatGauge(value: _percentage),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Current: ${_percentage.toStringAsFixed(2)}%', style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _refreshGauge,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh Gauge'),
            ),
          ],
        ),
      ),
    );
  }
}
