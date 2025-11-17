import '../backend/api/api_config.dart';

class ApiConstants {
  // Auth activity
  static String get registerWithEmailUrl => '${Config.baseUrl}/app/auth/register';
  static String get sendOtpUrl => '${Config.baseUrl}/app/auth/login';
  static String get resendOtpUrl => '${Config.baseUrl}/app/auth/resend-otp';
  static String get loginWithEmailUrl => '${Config.baseUrl}/app/auth/login';
  static String get verifyEmailOtpUrl => '${Config.baseUrl}/app/auth/verify-email';
  static String get resendEmailOtpUrl => '${Config.baseUrl}/app/auth/resend-otp';
  static String get userDetailsUrl => '${Config.baseUrl}/auth/current-user';
  static String get userProfile => '${Config.baseUrl}/users/profile';
  static String get driverUpdatesProfile => '${Config.baseUrl}/drivers/update';

  // Password management
  static String get forgotPasswordUrl => '${Config.baseUrl}/app/auth/forgot-password';
  static String get resetPasswordUrl => '${Config.baseUrl}/app/auth/reset-password';
  static String get updatePasswordUrl => '${Config.baseUrl}/app/auth/update-password';

  // Truck owner activity
  static String get vehicleRegisterUrl  => '${Config.baseUrl}/vehicles/register';
  static String get registerDriverUrl => '${Config.baseUrl}/trucks/add-driver';
  static String get driverDetailsUrl => '${Config.baseUrl}/trucks/all-drivers';
  static String get deleteDriverUrl => '${Config.baseUrl}/trucks/delete/:driverId';
  static String get updateDriverUrl => '${Config.baseUrl}/trucks/edit/:driverId';
  static String get allVehiclesUrl => '${Config.baseUrl}/vehicles/get-all-trucks';
  static String get getOrderUrl => '${Config.baseUrl}/orders/view-all-orders';
  static String get acceptOrderUrl => '${Config.baseUrl}/orders/accept-order/:orderId';
  static String get seeAvailableDriverUrl => '${Config.baseUrl}/drivers/available';
  static String get assignDriverUrl => '${Config.baseUrl}/orders/assign-driver/:orderId/:driverId';
  static String get seeAcceptedOrderUrl => '${Config.baseUrl}/orders/all-orders';
  static String get truckImageUrl => '${Config.baseUrl}/documents/get-images/:imageId';
  static String get messageCountUrl => '${Config.baseUrl}/messages/count-all';
  static String get messageUrl => '${Config.baseUrl}/messages/history';
  static String readMessageUrl(String id) => '${Config.baseUrl}/messages/read/$id';

  //Customer activity
  static String get stationRegisterUrl => '${Config.baseUrl}/orders/register-station';
  static String get allStationsUrl => '${Config.baseUrl}/customer/all-stations';
  static String get allDepotsUrl => '${Config.baseUrl}/customer/all-depot';
  static String get placeOrderUrl => '${Config.baseUrl}/orders/place-order';
  static String get seeOrderUrl => '${Config.baseUrl}/orders/my-orders';
  static String get getOrderByIdUrl => '${Config.baseUrl}/orders/getOrderId';
  static String get driverLicenseUrl => '${Config.baseUrl}/documents/driver-license/:orderId';
  static String get truckCardUrl => '${Config.baseUrl}/documents/vehicles/:vehicleId';

  //shared
  static String get searchSharedUrl => '${Config.baseUrl}/customer/search-shared-orders';
  // static String get matchNotFoundSaveUrl => '${Config.baseUrl}/orders/place-order';
  // static String get matchFoundFilterUrl => '${Config.baseUrl}/customer/filter-shared-orders';
  static String get sharedOrderUrl => '${Config.baseUrl}/customer/place-shared-order';

  //driver
  static String get driverAssignedTask => '${Config.baseUrl}/drivers/assigned-order';
  static String get startDeliveryUrl => '${Config.baseUrl}/drivers/start-trip/:orderId';
  static String get completeDeliveryUrl => '${Config.baseUrl}/drivers/end-trip/:orderId';
  static String get uploadsLicenceUrl => '${Config.baseUrl}/drivers/upload-license';

  // GPS and truck location
  static String get allGpsDataUrl => '${Config.baseUrl}/gps/all-gps';
  static String get configuredGpsUrl => '${Config.baseUrl}/gps/configured';
}
