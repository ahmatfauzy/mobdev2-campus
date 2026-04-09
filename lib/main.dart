import 'package:flutter/material.dart';
import 'package:get/get_state_manager/get_state_manager.dart';
import 'package:get/instance_manager.dart';
import 'package:get/route_manager.dart';
import 'package:get/state_manager.dart';

void main() {
  runApp(MyApp());
}

class CounterController extends GetxController {
  var count = 0.obs;

  void increment() {
    count++;
  }
}

class MyApp extends StatelessWidget {
  CounterController counterController = Get.put(CounterController());

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(home: CounterPage());
  }
}

class CounterPage extends StatelessWidget {
  const CounterPage({super.key});

  CounterController get controller => Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Counter PAge")),
      body: Center(child: Obx(() => Text("Nilai : ${controller.count}"))),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.increment,
        child: Icon(Icons.add),
      ),
    );
  }
}
