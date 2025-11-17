import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:oil_connect/backend/controllers/truckownerController.dart';
import 'package:oil_connect/backend/models/order_model.dart';
import 'package:oil_connect/utils/colors.dart';
import 'package:google_fonts/google_fonts.dart';

class NewOrdersScreen extends StatelessWidget {
  final TruckOwnerController controller = Get.put(TruckOwnerController());

  NewOrdersScreen({super.key});

  String formatNumber(dynamic number) {
    if (number == null) return "N/A";
    return NumberFormat("#,###").format(number);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0A0A0A)
          : const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Get.back(),
                        icon: Icon(
                          Icons.arrow_back_ios_rounded,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : const Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "New Orders",
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : const Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Available orders for your trucks",
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : const Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            ),

            // Orders List
            Expanded(
              child: RefreshIndicator(
                color: AppColors.rectangleColor,
        onRefresh: () async {
          await controller.fetchOrders();
        },
        child: Obx(() {
          if (controller.orders.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: controller.orders.length,
                    itemBuilder: (context, index) {
                      var order = controller.orders[index];
                      return _buildOrderCard(context, order);
                    },
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1A1A1A)
                  : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.local_shipping_rounded,
              size: 60,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white60
                  : Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "No New Orders",
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "There are no new orders available at the moment.\nPull down to refresh.",
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white60
                  : const Color(0xFF666666),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Order order) {
    bool isShared = order.routeWay == 'shared';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1A1A)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF2A2A2A)
              : const Color(0xFFE1E5E9),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
                onTap: () => _showOrderDetails(context, order),
          borderRadius: BorderRadius.circular(16),
                  child: Padding(
            padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                // Header Row
                Row(
                  children: [
                    // Price
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                            "Price",
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white60
                                  : const Color(0xFF666666),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Tsh. ${formatNumber(order.price)}",
                            style: GoogleFonts.inter(
                              fontSize: 24,
                                fontWeight: FontWeight.bold,
                              color: AppColors.rectangleColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Order Type Badge
                            Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                        color: isShared 
                            ? Colors.orange.withOpacity(0.1)
                            : Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isShared ? Colors.orange : Colors.blue,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isShared ? Icons.group_rounded : Icons.person_rounded,
                            size: 16,
                            color: isShared ? Colors.orange : Colors.blue,
                          ),
                          const SizedBox(width: 4),
                          Text(
                                order.routeWay.capitalizeFirst ?? '',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isShared ? Colors.orange : Colors.blue,
                            ),
                          ),
                        ],
                              ),
                            ),
                          ],
                        ),

                const SizedBox(height: 20),

                // Depot Information
                _buildInfoRow(
                  context,
                  Icons.business_rounded,
                  "Depot",
                  "${order.companyName} (${order.source}, ${order.depot})",
                ),

                const SizedBox(height: 12),

                // Destination Information
                if (isShared) ...[
                  _buildInfoRow(
                    context,
                    Icons.location_on_rounded,
                    "Destinations",
                    "${order.customers.length} locations",
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(order.customers.length, (i) {
                            final station = order.customers[i].stationDetails.isNotEmpty
                                ? order.customers[i].stationDetails[0]
                                : null;

                            return station != null
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              "• ${station.stationName} (${station.district}, ${station.region})",
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white70
                                    : const Color(0xFF666666),
                              ),
                            ),
                            )
                                : const SizedBox.shrink();
                          }),
                ] else ...[
                  _buildInfoRow(
                    context,
                    Icons.location_on_rounded,
                    "Destination",
                    "${order.stationName} (${order.district}, ${order.region})",
                  ),
                ],

                const SizedBox(height: 20),

                // Action Button
                Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.rectangleColor,
                        AppColors.rectangleColor.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton(
                    onPressed: () => _showOrderDetails(context, order),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.visibility_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "View Details",
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white60
              : const Color(0xFF666666),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white60
                      : const Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : const Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// ✅ Show Bottom Sheet with Order Details & Accept Button
  void _showOrderDetails(BuildContext context, Order order) {
    bool isShared = order.routeWay == 'shared';

    // Get vehicle identity from the matchingVehicles list if available
    String vehicleIdentity = order.matchingVehicles.isNotEmpty
        ? order.matchingVehicles[0].vehicleIdentity
        : order.vehicleId.isNotEmpty ? order.vehicleId : "N/A";

    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
          decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1A1A1A)
              : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
          ),
          child: Column(
          mainAxisSize: MainAxisSize.min,
            children: [
            // Handle Bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white30
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Order Type Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isShared 
                              ? Colors.orange.withOpacity(0.1)
                              : Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isShared ? Icons.group_rounded : Icons.person_rounded,
                          size: 24,
                          color: isShared ? Colors.orange : Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isShared ? "Shared Order" : "Private Order",
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : const Color(0xFF1A1A1A),
                              ),
                            ),
                            const SizedBox(height: 4),
                  Text(
                              "Order Details",
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white60
                                    : const Color(0xFF666666),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Price Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.rectangleColor,
                              AppColors.rectangleColor.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "Tsh. ${formatNumber(order.price)}",
                          style: GoogleFonts.inter(
                            fontSize: 16,
                      fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                    ),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // Order Information Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF0A0A0A)
                            : const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF2A2A2A)
                              : const Color(0xFFE1E5E9),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Order Information",
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : const Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 16),

              if (!isShared) ...[
                            _buildModernDetailRow(context, "Order ID", order.orderIdGenerated ?? order.orderId, Icons.receipt_rounded),
                            _buildModernDetailRow(context, "Fuel Type", order.fuelType, Icons.local_gas_station_rounded),
                            _buildModernDetailRow(context, "Volume", "${formatNumber(order.capacity)} L", Icons.opacity_rounded),
                            _buildModernDetailRow(context, "Vehicle ID", order.matchingVehicles.isNotEmpty ? order.matchingVehicles[0].vehicleIdentity : "N/A", Icons.local_shipping_rounded),
              ] else ...[
                            _buildModernDetailRow(context, "Group ID", order.sharedGroupId.isNotEmpty ? order.sharedGroupId : order.orderId, Icons.group_work_rounded),
                            _buildModernDetailRow(context, "Fuel Type", order.fuelType, Icons.local_gas_station_rounded),
                            _buildModernDetailRow(context, "Total Volume", "${formatNumber(order.capacity)} L", Icons.opacity_rounded),
                            _buildModernDetailRow(context, "Vehicle ID", vehicleIdentity, Icons.local_shipping_rounded),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Location Information Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF0A0A0A)
                            : const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF2A2A2A)
                              : const Color(0xFFE1E5E9),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Location Details",
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : const Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Depot Information
                          _buildLocationRow(
                            context,
                            Icons.business_rounded,
                            "Depot",
                            order.companyName,
                            "${order.source}, ${order.depot}",
                          ),

                          const SizedBox(height: 16),

                          // Destination Information
                          if (isShared) ...[
                            _buildLocationRow(
                              context,
                              Icons.location_on_rounded,
                              "Destinations",
                              "${order.customers.length} locations",
                              "",
                            ),
                            const SizedBox(height: 12),
                ...List.generate(order.customers.length, (i) {
                  final station = order.customers[i].stationDetails.isNotEmpty
                      ? order.customers[i].stationDetails[0]
                      : null;

                  return station != null
                                  ? _buildDestinationItem(
                    context,
                                      i + 1,
                                      station.stationName,
                                      "${station.district}, ${station.region}",
                  )
                      : const SizedBox.shrink();
                }),
                          ] else ...[
                            _buildLocationRow(
                              context,
                              Icons.location_on_rounded,
                              "Destination",
                              order.stationName,
                              "${order.district}, ${order.region}",
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Action Button
            Container(
              padding: const EdgeInsets.all(24),
              child: Obx(() => Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.rectangleColor,
                      AppColors.rectangleColor.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ElevatedButton(
                onPressed: controller.isLoading.value
                    ? null
                    : () async {
                  controller.isLoading.value = true;

                  if (controller.availableDrivers.isEmpty) {
                    await controller.fetchAvailableDrivers();
                  }

                  if (controller.availableDrivers.isEmpty) {
                    controller.isLoading.value = false;
                    Get.snackbar(
                      "No Drivers Available",
                        "Make sure you have available drivers.",
                      snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.orange,
                        colorText: Colors.white,
                    );
                    return;
                  }

                  final passedId = order.routeWay == 'shared'
                      ? order.sharedGroupId
                      : order.orderId;

                  await controller.acceptOrder(order);
                  controller.isLoading.value = false;
                  Get.back();
                  _showDriverSelection(context, passedId);
                },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: controller.isLoading.value
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "Processing...",
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Accept & Assign Driver",
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                  ),
                ),
              )),
            ),
            ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  /// ✅ Show Bottom Sheet for Driver Selection
  void _showDriverSelection(BuildContext context, String orderId) async {
    await controller.fetchAvailableDrivers();

    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1A1A1A)
              : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle Bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white30
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.rectangleColor,
                          AppColors.rectangleColor.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person_add_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Select Driver",
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : const Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Choose a driver to assign this order",
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white60
                                : const Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: Obx(() {
                if (controller.isLoadingDrivers.value) {
                  return Container(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: AppColors.rectangleColor,
                          strokeWidth: 3,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Loading drivers...",
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white70
                                : const Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (controller.availableDrivers.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.person_off_rounded,
                            size: 48,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No Available Drivers",
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : const Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Make sure you have available drivers in your fleet",
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white60
                                : const Color(0xFF666666),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF2A2A2A)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF3A3A3A)
                                  : const Color(0xFFE1E5E9),
                            ),
                          ),
                          child: ElevatedButton(
                            onPressed: () => Get.back(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              "Close",
                              style: GoogleFonts.inter(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : const Color(0xFF1A1A1A),
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: controller.availableDrivers.length,
                  itemBuilder: (context, index) {
                    var driver = controller.availableDrivers[index];
                    String driverId = driver["_id"] ?? "UNKNOWN_ID";
                    String driverName =
                    "${driver["firstname"] ?? "Unknown"} ${driver["lastname"] ?? ""}".trim();
                    String phone = driver["phoneNumber"]?.toString() ?? "N/A";

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF0A0A0A)
                            : const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF2A2A2A)
                              : const Color(0xFFE1E5E9),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.black.withOpacity(0.3)
                                : Colors.grey.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.rectangleColor,
                                AppColors.rectangleColor.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              driverName.isNotEmpty ? driverName[0].toUpperCase() : "U",
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          driverName,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : const Color(0xFF1A1A1A),
                          ),
                        ),
                        subtitle: Row(
                          children: [
                            Icon(
                              Icons.phone_rounded,
                              size: 16,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white60
                                  : const Color(0xFF666666),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              phone,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white60
                                    : const Color(0xFF666666),
                              ),
                            ),
                          ],
                        ),
                        trailing: Obx(() => Container(
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: controller.assigningDriverId.value == driverId
                                ? null
                                : LinearGradient(
                                    colors: [
                                      AppColors.rectangleColor,
                                      AppColors.rectangleColor.withOpacity(0.8),
                                    ],
                                  ),
                            color: controller.assigningDriverId.value == driverId
                                ? Colors.grey[300]
                                : null,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ElevatedButton(
                            onPressed: controller.assigningDriverId.value == driverId
                                ? null
                                : () {
                              _showAssignConfirmation(
                                  context, driverId, driverName, orderId);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: controller.assigningDriverId.value == driverId
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      color: Colors.grey[600],
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    "Assign",
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                          ),
                        )),
                      ),
                    );
                  },
                );
              }),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }


  /// ✅ Show Confirmation Dialog & Handle Assignment
  void _showAssignConfirmation(BuildContext context, String driverId,
      String driverName, String orderId) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1A1A1A)
                : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.rectangleColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.person_add_rounded,
                  size: 32,
                  color: AppColors.rectangleColor,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Title
              Text(
                "Confirm Assignment",
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : const Color(0xFF1A1A1A),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Message
              Text(
                "Are you sure you want to assign $driverName to this order?",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : const Color(0xFF666666),
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 24),
              
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF2A2A2A)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF3A3A3A)
                              : const Color(0xFFE1E5E9),
                        ),
                      ),
                      child: ElevatedButton(
                        onPressed: () => Get.back(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          "Cancel",
                          style: GoogleFonts.inter(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : const Color(0xFF1A1A1A),
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.rectangleColor,
                            AppColors.rectangleColor.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.rectangleColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          Get.back(); // Close confirmation
                          controller.assigningDriverId.value = driverId;
                          await controller.assignDriver(driverId, orderId);
                          controller.assigningDriverId.value = '';
                          Get.back(closeOverlays: true);
                          await controller.fetchAcceptedOrders();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          "Yes, Assign",
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          Text(
            value.isNotEmpty ? value : "N/A",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.blueAccent),
          ),
        ],
      ),
    );
  }

  Widget _buildModernDetailRow(BuildContext context, String title, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1A1A)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF2A2A2A)
              : const Color(0xFFE1E5E9),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.rectangleColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white60
                        : const Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isNotEmpty ? value : "N/A",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : const Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow(BuildContext context, IconData icon, String title, String mainText, String subText) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.rectangleColor,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white60
                      : const Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                mainText,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : const Color(0xFF1A1A1A),
                ),
              ),
              if (subText.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subText,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white60
                        : const Color(0xFF666666),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDestinationItem(BuildContext context, int index, String stationName, String location) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1A1A)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF2A2A2A)
              : const Color(0xFFE1E5E9),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.rectangleColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                "$index",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.rectangleColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stationName,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  location,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white60
                        : const Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}