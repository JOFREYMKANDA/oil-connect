import 'package:get/get.dart';
import 'package:oil_connect/backend/models/resendOtp_modals.dart';
import 'package:oil_connect/utils/api_constants.dart';

class ResendOtpController extends GetxController {
  final RxString successMessage = ''.obs;
  final RxString errorMessage = ''.obs;

  Future<void> resendOtp({required String phoneNumber}) async {
    try {
      successMessage.value = '';
      errorMessage.value = '';

      final response = await ApiService.post(
        endpoint: ApiConstants.resendOtpUrl,
        data: {'phoneNumber': phoneNumber},
      );

      if (response['status'] == true) {
        successMessage.value = response['message'] ?? 'OTP resent successfully!';
      } else {
        errorMessage.value = response['message'] ?? 'Failed to resend OTP.';
      }
    } catch (e) {
      errorMessage.value = 'An error occurred while resending OTP: $e';
    }
  }
}
