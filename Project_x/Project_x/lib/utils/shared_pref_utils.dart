import 'package:get/get.dart';
import 'package:oil_connect/screens/login%20screens/login.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsUtil {
  static final SharedPrefsUtil _instance = SharedPrefsUtil._internal();
  late SharedPreferences _prefs;

  factory SharedPrefsUtil() => _instance;

  SharedPrefsUtil._internal();

  /// ✅ Initialize SharedPreferences
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// ✅ Save Token & Login Time
  Future<void> saveToken(String token, String phoneNumber)  async {
    print("📝 Saving Token: $token");
    print("📝 Phone Number: $phoneNumber");
    await _prefs.setString('jwtToken', token);
    await _prefs.setString('lastUsedPhoneNumber', phoneNumber);
    await _prefs.setInt('lastLoginTime', DateTime.now().millisecondsSinceEpoch); // Save login time
  }

  Future<void> saveLastUsedPhoneNumber(String phoneNumber) async {
    await _prefs.setString('lastUsedPhoneNumber', phoneNumber);
  }

  /// save driver status
  Future<void> saveUserStatus(String status) async {
    await _prefs.setString('userStatus', status);
  }

  String? getUserStatus() {
    return _prefs.getString('userStatus');
  }

  /// Save license submission status
  Future<void> saveLicenseSubmitted(bool submitted) async {
    await _prefs.setBool('licenseSubmitted', submitted);
  }

  /// Retrieve submission status
  bool isLicenseSubmitted() {
    return _prefs.getBool('licenseSubmitted') ?? false;
  }

  /// ✅ Retrieve Token
  String? getToken() {
    String? token = _prefs.getString('jwtToken');
    print("📌 Retrieved Token: $token");
    return token;
  }

  /// ✅ Retrieve Last Used Phone Number
  String? getLastUsedPhoneNumber() {
    return _prefs.getString('lastUsedPhoneNumber');
  }

  /// ✅ Save User ID
  Future<void> saveUserId(String userId) async {
    print("📝 Saving User ID: $userId");
    await _prefs.setString('userId', userId);
  }

  /// ✅ Retrieve User ID
  String? getUserId() {
    String? userId = _prefs.getString('userId');
    print("📌 Retrieved User ID: $userId");
    return userId;
  }

  /// ✅ Save Role
  Future<void> saveRole(String role) async {
    print("📝 Saving Role: $role");
    await _prefs.setString('userRole', role);
  }

  /// ✅ Retrieve Role
  String? getRole() {
    String? role = _prefs.getString('userRole');
    print("📌 Retrieved Role: $role");
    return role;
  }

  /// ✅ Save Last Login Time
  Future<void> saveLoginTime() async {
    await _prefs.setInt('lastLoginTime', DateTime.now().millisecondsSinceEpoch);
  }

  /// ✅ Retrieve Last Login Time
  int? getLastLoginTime() {
    return _prefs.getInt('lastLoginTime');
  }

  /// ✅ Check if user is inactive (3 months)
  bool isUserInactive() {
    int? lastLogin = _prefs.getInt('lastLoginTime');
    if (lastLogin == null) return true; // If no record, treat as inactive

    DateTime lastLoginDate = DateTime.fromMillisecondsSinceEpoch(lastLogin);
    DateTime threeMonthsAgo = DateTime.now().subtract(const Duration(days: 120));

    return lastLoginDate.isBefore(threeMonthsAgo);
  }

  /// ✅ Check if user is logged in
  bool isLoggedIn() {
    return getToken() != null && !isUserInactive();
  }

  /// ✅ Clear Token & Role (Logout)
  Future<void> clearData() async {
    print("🗑 Clearing Token & Role...");
    await _prefs.remove('jwtToken');
    await _prefs.remove('userRole');
    await _prefs.remove('lastLoginTime');
  }

  /// ✅ Logout: Clear Token, Role & Exit App
  Future<void> logout() async {
    print("🔴 Logging Out...");
    await _prefs.remove('jwtToken');
    await _prefs.remove('userRole');
    await _prefs.remove('lastLoginTime');

    print("✅ Redirecting to Login Screen...");

    Future.delayed(const Duration(milliseconds: 300), () {
      Get.offAll(() => const LoginScreen()); // ✅ Redirect to login screen properly
    });
  }
}
