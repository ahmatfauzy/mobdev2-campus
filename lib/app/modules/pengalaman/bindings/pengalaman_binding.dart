import 'package:get/get.dart';
import '../controllers/pengalaman_controller.dart';

class PengalamanBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PengalamanController>(() => PengalamanController());
  }
}
