import 'package:flutter/material.dart';

class TodayCheckoutsScreen extends StatelessWidget {
  const TodayCheckoutsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Today's Check-outs"),
      ),
      body: const Center(
        child: Text(
          "Today's Check-outs will appear here.",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}