import 'package:get/get.dart';
import '../../../data/models/biodata_model.dart';

class BiodataController extends GetxController {
  final biodata = biodataAhmatFauzi.obs;

  void goBack() {
    Get.back();
  }
}