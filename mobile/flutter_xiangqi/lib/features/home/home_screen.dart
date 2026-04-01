import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xiangqi'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            context.push('/new-game');
          },
          child: const Text('New Game'),
        ),
      ),
    );
  }
}
