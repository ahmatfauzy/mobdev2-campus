import 'package:get/get.dart';

import '../modules/biodata/bindings/biodata_binding.dart';
import '../modules/biodata/views/biodata_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/pengalaman/bindings/pengalaman_binding.dart';
import '../modules/pengalaman/views/pengalaman_view.dart';
import 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.HOME;

  static final routes = [
    GetPage(
      name: _Paths.HOME,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.BIODATA,
      page: () => const BiodataView(),
      binding: BiodataBinding(),
      children: [
        GetPage(
          name: _Paths.BIODATA,
          page: () => const BiodataView(),
          binding: BiodataBinding(),
        ),
      ],
    ),
    GetPage(
      name: _Paths.PENGALAMAN,
      page: () => const PengalamanView(),
      binding: PengalamanBinding(),
      children: [
        GetPage(
          name: _Paths.PENGALAMAN,
          page: () => const PengalamanView(),
          binding: PengalamanBinding(),
        ),
      ],
    ),
  ];
}

abstract class _Paths {
  static const HOME = Routes.HOME;
  static const BIODATA = Routes.BIODATA;
  static const PENGALAMAN = Routes.PENGALAMAN;
}
