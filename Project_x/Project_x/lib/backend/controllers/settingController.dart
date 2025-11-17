import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SettingsController extends GetxController {
  final GetStorage _storage = GetStorage();

  var mapType = MapType.normal.obs;

  @override
  void onInit() {
    super.onInit();
    _loadPreferences();
  }

  void _loadPreferences() {
    String? storedMapType = _storage.read('mapType');
    switch (storedMapType) {
      case 'satellite':
        mapType.value = MapType.satellite;
        break;
      case 'terrain':
        mapType.value = MapType.terrain;
        break;
      case 'hybrid':
        mapType.value = MapType.hybrid;
        break;
      default:
        mapType.value = MapType.normal;
    }
  }

  void setMapType(MapType newType) {
    mapType.value = newType;
    _storage.write('mapType', newType.toString().split('.').last);
  }
}
