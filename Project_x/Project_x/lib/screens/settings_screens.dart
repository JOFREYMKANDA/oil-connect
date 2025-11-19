import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:oil_connect/backend/controllers/settingController.dart';
import 'package:oil_connect/utils/colors.dart';
import 'package:oil_connect/utils/themes/theme_controller.dart';

class SettingsScreen extends StatelessWidget {
  SettingsScreen({super.key});

  final GetStorage _storage = GetStorage();
  final SettingsController settingsController = Get.find<SettingsController>();

  final mapType = MapType.normal.obs;
  final language = 'en'.obs;

  /// **Load Preferences from Storage**
  void _loadPreferences() {
    language.value = _storage.read('language') ?? 'en';
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

  /// **Change Language and Apply Globally**
  void changeLanguage(String lang) {
    language.value = lang;
    _storage.write('language', lang);
    Get.updateLocale(Locale(lang)); // Apply language change globally
  }

  @override
  Widget build(BuildContext context) {
    _loadPreferences();
    final ThemeController themeController = Get.isRegistered<ThemeController>()
        ? Get.find<ThemeController>()
        : Get.put(ThemeController());

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.rectangleColor,
        title: const Text(
          "Settings",
          style: TextStyle(color: AppColors.shapeColor),
        ),
        iconTheme: const IconThemeData(color: AppColors.shapeColor),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ Theme Toggle (With Dynamic Icon)
              Obx(() {
                bool isDarkMode = themeController.isDarkMode.value;
                return ListTile(
                  leading: Icon(
                    isDarkMode ? Icons.wb_sunny : Icons.dark_mode, // 🔥 Dynamic Icon
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  title: const Text("Theme Mode"),
                  trailing: Switch(
                    value: isDarkMode,
                    onChanged: (value) {
                      themeController.toggleTheme();
                    },
                  ),
                );
              }),
              const Divider(),

              // ✅ Language Selector
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text("Language"),
                trailing: Obx(() {
                  return DropdownButton<String>(
                    value: language.value,
                    items: ['en', 'sw'].map((lang) {
                      return DropdownMenuItem(
                        value: lang,
                        child: Text(lang == 'en' ? 'English' : 'Swahili'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        changeLanguage(value);
                      }
                    },
                  );
                }),
              ),
              const Divider(),

              // ✅ Map Type Selector
              ListTile(
                leading: const Icon(Icons.layers),
                title: const Text("Map Type"),
                trailing: Obx(() {
                  return DropdownButton<MapType>(
                    value: settingsController.mapType.value,
                    items: const [
                      DropdownMenuItem(value: MapType.normal, child: Text("Normal")),
                      DropdownMenuItem(value: MapType.satellite, child: Text("Satellite")),
                      DropdownMenuItem(value: MapType.terrain, child: Text("Terrain")),
                      DropdownMenuItem(value: MapType.hybrid, child: Text("Hybrid")),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        settingsController.setMapType(value);
                      }
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

