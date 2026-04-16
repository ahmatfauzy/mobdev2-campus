import 'package:get/get.dart';
import '../controllers/biodata_controller.dart';

class BiodataBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BiodataController>(() => BiodataController());
  }
}