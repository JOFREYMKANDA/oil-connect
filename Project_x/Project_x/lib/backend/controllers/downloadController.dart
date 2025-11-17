import 'package:get/get.dart';
import 'package:oil_connect/backend/services/downloadService.dart';

class DownloadController extends GetxController {
  RxBool isDownloadingDriverLicense = false.obs;
  RxBool isDownloadingTruckCard = false.obs;

  void downloadTruckCard(String truckId) async {
    isDownloadingTruckCard.value = true;
    await DownloadService.downloadTruckCard(truckId);
    isDownloadingTruckCard.value = false;
  }

  void downloadDriverLicense(String orderId) async {
    isDownloadingDriverLicense.value = true;
    await DownloadService.downloadDriverLicense(orderId);
    isDownloadingDriverLicense.value = false;
  }
}

