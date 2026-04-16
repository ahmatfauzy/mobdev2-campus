import 'package:get/get.dart';
import '../../../data/models/biodata_model.dart';

class HomeController extends GetxController {
  final biodata = biodataAhmatFauzi.obs;

  void goToBiodata() {
    Get.toNamed('/biodata');
  }

  void goToPengalaman() {
    Get.toNamed('/pengalaman');
  }
}