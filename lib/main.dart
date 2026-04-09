import 'package:flutter/material.dart';
import 'package:get/get.dart';

void main() {
  runApp(MyApp());
}

class CounterController extends GetxController {
  var count = 0.obs;

  void increment() {
    count++;
    Get.snackbar(
      'Sukses',
      'Nilai bertambah menjadi $count',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green[100],
      duration: Duration(seconds: 1),
    );
  }

  void decrement() {
    if (count > 0) {
      count--;
    } else {
      Get.snackbar(
        'Peringatan',
        'Nilai sudah 0!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red[100],
      );
    }
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Counter GetX',
      debugShowCheckedModeBanner: false,
      home: CounterPage(),
    );
  }
}

class CounterPage extends StatelessWidget {
  CounterPage({super.key}) {
    Get.put(CounterController());
  }

  CounterController get controller => Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Counter GetX")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Counter dengan GetX"),
            SizedBox(height: 20),
            Obx(
              () => Text(
                "${controller.count}",
                style: TextStyle(fontSize: 60, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton(
                  onPressed: controller.decrement,
                  heroTag: "decrement",
                  backgroundColor: Colors.red,
                  child: Icon(Icons.remove),
                ),
                SizedBox(width: 20),
                FloatingActionButton(
                  onPressed: controller.increment,
                  heroTag: "increment",
                  backgroundColor: Colors.green,
                  child: Icon(Icons.add),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.back(),
        child: Icon(Icons.arrow_back),
      ),
    );
  }
}
