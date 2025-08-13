import 'package:flutter/material.dart';

class TaskBoardScreen extends StatelessWidget {
  const TaskBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('任务面板')),
      body: const Center(child: Text('任务面板 - 开发中')),
    );
  }
}
