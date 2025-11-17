import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:oil_connect/backend/api/api_config.dart';
import 'package:oil_connect/utils/shared_pref_utils.dart';

class DownloadService {
  /// ✅ Generic File Downloader with permission dialog
  static Future<void> _downloadAndSaveFile({
    required String url,
    required String fileNamePrefix,
    required String fileId,
  }) async {
    final token = await SharedPrefsUtil().getToken();

    if (token == null || token.isEmpty) {
      Get.snackbar("Authentication Error", "Please login again.",
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    // 🔐 Check storage permission
    final status = await Permission.manageExternalStorage.status;
    if (!status.isGranted) {
      final result = await Get.dialog<bool>(
        AlertDialog(
          title: const Text("Storage Permission Required"),
          content: const Text(
            "This app needs permission to access storage in order to download and open documents.",
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              child: const Text("Allow"),
            ),
          ],
        ),
      );

      if (result != true) {
        Get.snackbar("Cancelled", "Download cancelled by user.",
            backgroundColor: Colors.orange, colorText: Colors.white);
        return;
      }

      final permissionResult = await Permission.manageExternalStorage.request();
      if (!permissionResult.isGranted) {
        Get.snackbar("Permission Denied", "Cannot proceed without storage access.",
            backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }
    }

    try {
      print("📦 Fetching from: $url");
      final response = await http.get(Uri.parse(url), headers: {
        'Authorization': 'Bearer $token',
      });

      final contentType = response.headers['content-type'];
      if (response.statusCode == 200 && contentType != null) {
        // 📄 Determine extension
        String extension = '.file';
        if (contentType.contains('pdf')) {
          extension = '.pdf';
        } else if (contentType.contains('jpeg') || contentType.contains('jpg')) {
          extension = '.jpg';
        } else if (contentType.contains('png')) {
          extension = '.png';
        }

        // 📂 Save to Downloads
        final downloadsDir = Directory('/storage/emulated/0/Download');
        if (!downloadsDir.existsSync()) downloadsDir.createSync(recursive: true);

        final filePath = '${downloadsDir.path}/${fileNamePrefix}_$fileId$extension';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        await OpenFile.open(filePath);
      } else {
        print("❌ Invalid response: ${response.body}");
        Get.snackbar("Failed", "Invalid file or unauthorized.",
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      print("❌ Exception: $e");
      Get.snackbar("Error", "Something went wrong.",
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  /// ✅ Download Truck Card
  static Future<void> downloadTruckCard(String truckId) async {
    final url = '${Config.baseUrl}/documents/vehicles/$truckId';
    await _downloadAndSaveFile(
      url: url,
      fileNamePrefix: "truck_card",
      fileId: truckId,
    );
  }

  /// ✅ Download Driver License
  static Future<void> downloadDriverLicense(String orderId) async {
    final url = '${Config.baseUrl}/documents/driver-license/$orderId';
    await _downloadAndSaveFile(
      url: url,
      fileNamePrefix: "driver_license",
      fileId: orderId,
    );
  }
}

