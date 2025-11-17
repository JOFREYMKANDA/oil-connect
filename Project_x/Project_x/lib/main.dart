import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:oil_connect/backend/controllers/authController.dart';
import 'package:oil_connect/backend/controllers/driverController.dart';
import 'package:oil_connect/backend/controllers/gpsController.dart';
import 'package:oil_connect/backend/controllers/internetConnectivityController.dart';
import 'package:oil_connect/backend/controllers/orderController.dart';
import 'package:oil_connect/backend/controllers/settingController.dart';
import 'package:oil_connect/backend/controllers/stationController.dart';
import 'package:oil_connect/utils/shared_pref_utils.dart';
import 'package:oil_connect/utils/themes/app_theme.dart';
import 'package:oil_connect/utils/themes/theme_controller.dart';
import 'package:oil_connect/utils/translation.dart';
import 'package:oil_connect/widget/bottom_navigation.dart';
import 'package:oil_connect/widget/splashscreen.dart';
import 'package:oil_connect/screens/customer%20screens/station_registration.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize essential services first
    await dotenv.load(fileName: ".env");
    await SharedPrefsUtil().init();
    await GetStorage.init();

    // Initialize controllers with error handling
    Get.put(RegisterController());
    Get.put(SettingsController());
    Get.put(StationController());
    Get.put(OrderController());
    Get.put(DriverOrderController());
    Get.put(ConnectivityController());
    Get.put(ThemeController());

    // Initialize GPS controller separately to avoid blocking
    final gpsController = Get.put(GpsController(), permanent: true);
    
    // Check user inactivity safely
    try {
      if(SharedPrefsUtil().isUserInactive()) {
        print("🔴 User inactive for 3+ months. Logging out...");
        await Get.find<RegisterController>().logout();
      }
    } catch (e) {
      print("⚠️ Error checking user inactivity: $e");
      //Continue with app even if user inactivity check fails
    }
    // Connect to socket in background with delay to avoid blocking startup
    Future.delayed(const Duration(seconds: 5), () {
      try {
        gpsController.connectToSocket();
      } catch (e) {
        print("⚠️ Socket connection failed: $e");
      }
    });

  } catch (e) {
    print("❌ Error during app initialization: $e");
    // Continue with app launch even if some services fail
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.put(ThemeController());

    final String? token = SharedPrefsUtil().getToken();
    final String? role = SharedPrefsUtil().getRole();

    Widget initialScreen = const SplashScreen();
    if (token != null && role != null && role.isNotEmpty) {
      final normalizedRole = role.trim();
      
      if (['Customer', 'Driver', 'TruckOwner', 'Admin', 'Staff'].contains(normalizedRole)) {
        initialScreen = RoleBasedBottomNavScreen(role: normalizedRole);
      } else {
        // Invalid role, go to splash screen to handle properly
        initialScreen = const SplashScreen();
      }
    }

    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return Obx(() => GetMaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeController.isDarkMode.value ? ThemeMode.dark : ThemeMode.light,
          translations: AppTranslations(),
          locale: const Locale('en'),
          fallbackLocale: const Locale('en'),
          home: initialScreen,

          getPages: [
            GetPage(
              name: '/station/register',
              page: () => const StationRegistration(),
            ),
            // Add other routes as needed
          ],
        ));
      },
    );
  }
}
