import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:oil_connect/backend/controllers/driverController.dart';
import 'package:oil_connect/backend/models/order_model.dart';
import 'package:oil_connect/utils/colors.dart';
import 'package:oil_connect/screens/driver screens/delivery_completion_screen.dart';
import 'package:oil_connect/widget/AppBar.dart';

class DriverOrdersScreen extends StatelessWidget {
  final DriverOrderController controller = Get.put(DriverOrderController());

  DriverOrdersScreen({super.key}) {
    controller.fetchAssignedOrders(); // ✅ Fetch orders when screen loads
  }

  String formatWithCommas(int number) {
    final formatter = NumberFormat("#,###");
    return formatter.format(number);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BackAppBar(title: 'Orders'),
      // AppBar(
      //   backgroundColor: AppColors.rectangleColor,
      //   elevation: 0,
      //   iconTheme: const IconThemeData(color: AppColors.shapeColor),
      //   centerTitle: true,
      //   title: const Text(
      //     "Assigned Orders",
      //     style: TextStyle(color: AppColors.shapeColor, fontWeight: FontWeight.bold),
      //   ),
      // ),
      body: Column(
        children: [
          /// ✅ Order Status Filter
          _OrderStatusFilter(),

          /// ✅ Order List with Loading Indicator
          Expanded(
            child: Stack(
              children: [
                Obx(() {
                  if (controller.isLoading.value) {
                    //return Center(child: CircularProgressIndicator(color: AppColors.rectangleColor));
                  }

                  if (controller.filteredOrders.isEmpty) {
                    return Center(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                          Icon(
                            Icons.receipt_long,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text("No Orders Found",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text("There are no orders here yet",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[500],
                            ),
                          )
                        ]));
                  }

                  return RefreshIndicator(
                    color: AppColors.rectangleColor,
                    onRefresh: () async {
                      await controller.fetchAssignedOrders();
                      // Show success feedback
                      Get.snackbar(
                        "Refreshed",
                        "Orders updated successfully",
                        backgroundColor: Colors.green,
                        colorText: Colors.white,
                        snackPosition: SnackPosition.BOTTOM,
                        duration: const Duration(seconds: 2),
                      );
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 12),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: controller.filteredOrders.length,
                      itemBuilder: (context, index) {
                        final order = controller.filteredOrders[index];

                        final isShared = order.routeWay == "shared";
                        final sharedOrders = isShared
                            ? controller.getGroupOrders(order.sharedGroupId)
                            : [];

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                              side:const BorderSide(
                                color: Color(0xfff5f5f5), // Border color
                                 // Border width
                              ),
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                          color:const Color(0xfffafafa),
                          
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                  Text(
                                  isShared
                                      ? "Shared Order"
                                      : "#${order.orderIdGenerated ?? order.orderId}",          
                                  style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                  overflow: TextOverflow.ellipsis,
                                    ),
                               
                                  const SizedBox(height: 10),

                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: getStatusColor(order.status).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: getStatusColor(order.status).withOpacity(0.3)),
                                    ),
                                    child: Text(
                                          order.status,
                                          style: TextStyle(
                                            color: getStatusColor(order.status),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                  ),

                                const SizedBox(height: 12),

                                 _buildOrderDetail("Depot", "${order.companyName} (${order.source}, ${order.depot})", Icons.business),

                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      size: 20,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: isShared
                                          ? Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Destination 1',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      "${order.populatedStations.isNotEmpty ? order.populatedStations[0].label : 'No station'}(${order.stationName}) - ${order.district}, ${order.region}",
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                                if (sharedOrders.length > 1) ...[
                                                  const SizedBox(height: 4),
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        'Destination 2',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.grey[600],
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        "${sharedOrders[1].populatedStations.isNotEmpty ? sharedOrders[1].populatedStations[0].label : 'No station'}(${sharedOrders[1].stationName}) - ${sharedOrders[1].district}, ${sharedOrders[1].region}",
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ],
                                            )
                                          : Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Destination',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '${order.populatedStations.isNotEmpty ? order.populatedStations[0].label : 'No station'}(${order.stationName}) - ${order.district}, ${order.region}',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          )
                                    ),
                                  ],
                                ),


                                
                                const SizedBox(height: 12),
                                 _buildQuickActionButton(order),

                                /// ✅ Action Button Row
                               
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }


   /// Order Detail Item
  Widget _buildOrderDetail(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey[600],
        ),

        const SizedBox(width: 8),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }



  

  /// ✅ Show Order Details in Bottom Sheet
  void _showOrderDetails(BuildContext context, Order order) {
    final DriverOrderController controller = Get.find<DriverOrderController>();

    // Check if it's a shared group
    final isShared = order.routeWay == "shared";
    final groupOrders =
        isShared ? controller.getGroupOrders(order.sharedGroupId) : [order];

    final totalVolume = groupOrders.fold<int>(0, (sum, o) => sum + o.capacity);

    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              /// ✅ ORDER SUMMARY (Common Info)
              Center(
                child: Text(
                  "Order Summary",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),

              const SizedBox(height: 8),
              _buildDetailRow(context, "Fuel Type", order.fuelType),
              _buildDetailRow(context, "Total Volume",
                  "${formatWithCommas(totalVolume)} Liters"),
              _buildDetailRow(context, "Depot",
                  "${order.depot}, ${order.source}, ${order.companyName}"),

              const SizedBox(height: 16),
              const Divider(),

              /// ✅ CUSTOMER DETAILS
              ...groupOrders.asMap().entries.map((entry) {
                final index = entry.key + 1;
                final o = entry.value;

                final station = o.stationName.isNotEmpty
                    ? "${o.stationName}, ${o.district}, ${o.region}"
                    : "N/A";

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        "Customer $index",
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildDetailRow(
                        context, "Order ID", o.orderIdGenerated ?? o.orderId),
                    _buildDetailRow(context, "Name",
                        "${o.customerFirstName} ${o.customerLastName}"),
                    _buildDetailRow(context, "Destination", station),
                    _buildDetailRow(context, "Volume",
                        "${formatWithCommas(o.capacity)} Liters"),
                    if (index < groupOrders.length) ...[
                      const SizedBox(height: 12),
                      const Divider(),
                    ],
                  ],
                );
              }),

              const SizedBox(height: 20),

              /// ✅ ACTION BUTTONS
              _buildActionButtons(context, order),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  /// ✅ Helper Widget for Order Detail Rows
  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: 14,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              maxLines: 3,
            ),
          ),
        ],
      ),
    );
  }

 

  /// ✅ Quick Action Button for List View
  Widget _buildQuickActionButton(Order order) {
    final DriverOrderController controller = Get.find<DriverOrderController>();

    return Obx(() {
      final isLoadingStart = controller.isStartingTrip.value;
      final isLoadingComplete = controller.isCompletingDelivery.value;

      if (order.status.toLowerCase() == "assigned") {
        return SizedBox(
          height: 36,
          child: ElevatedButton.icon(
            onPressed: isLoadingStart
                ? null
                : () => _startDelivery(Get.context!, order),
            icon: isLoadingStart
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.play_arrow, size: 16),
            label: Text(
              isLoadingStart ? "Starting..." : "Start",
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        );
      }

      if (order.status.toLowerCase() == "ondelivery") {
        return SizedBox(
          height: 36,
          child: ElevatedButton.icon(
            onPressed: isLoadingComplete
                ? null
                : () => _completeDelivery(Get.context!, order),
            icon: isLoadingComplete
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.check_circle, size: 16),
            label: Text(
              isLoadingComplete ? "Completing..." : "Complete",
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        );
      }

      if (order.status.toLowerCase() == "completed") {
        return Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade700, size: 14),
              const SizedBox(width: 4),
              Text(
                "iompleted",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
        );
      }

      return const SizedBox.shrink();
    });
  }

  /// ✅ Action Buttons Widget
  Widget _buildActionButtons(BuildContext context, Order order) {
    final DriverOrderController controller = Get.find<DriverOrderController>();

    return Obx(() {
      final isLoadingStart = controller.isStartingTrip.value;
      final isLoadingComplete = controller.isCompletingDelivery.value;

      return Column(
        children: [
          if (order.status.toLowerCase() == "assigned") ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLoadingStart
                    ? null
                    : () => _startDelivery(context, order),
                icon: isLoadingStart
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(
                  isLoadingStart ? "Starting..." : "Start Delivery",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
          if (order.status.toLowerCase() == "ondelivery") ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLoadingComplete
                    ? null
                    : () => _completeDelivery(context, order),
                icon: isLoadingComplete
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.check_circle),
                label: Text(
                  isLoadingComplete ? "Completing..." : "Complete Delivery",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
          if (order.status.toLowerCase() == "completed") ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle,
                      color: Colors.green.shade700, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    "Delivery Completed",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    });
  }

  /// ✅ Start Delivery Action
  void _startDelivery(BuildContext context, Order order) async {
    final DriverOrderController controller = Get.find<DriverOrderController>();

    // Show confirmation dialog
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text("Start Delivery"),
        content: const Text(
            "Are you sure you want to start delivery for this order?"),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text("Start"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await controller.startDelivery(order.orderId);

      // Show success message
      Get.snackbar(
        "Delivery Started",
        "You have successfully started the delivery",
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    }
  }

  /// ✅ Complete Delivery Action
  void _completeDelivery(BuildContext context, Order order) async {
    // Navigate to delivery completion screen
    Get.to(() => DeliveryCompletionScreen(order: order));
  }

  /// ✅ Status Color Helper
  Color getStatusColor(String status) {
  switch (status.toLowerCase()) {
    case "completed":
      return const Color(0xFF4CAF50); // Green
    case "approved":
      return const Color(0xFF3F51B5); // Indigo
    case "accepted":
      return const Color(0xFF2196F3); // Blue
    case "assigned":
      return const Color(0xFF03A9F4); // Sky
    case "ondelivery":
      return const Color(0xFF00BCD4); // Cyan
    case "pending":
      return const Color(0xFFFFC107); // Amber
    case "requested":
      return const Color(0xFFFF9800); // Orange
    case "cancelled":
      return const Color(0xFFF44336); // Red
    default:
      return const Color(0xFF9E9E9E); // Grey
  }
}

}

/// ✅ **Order Status Filter Component**
class _OrderStatusFilter extends StatelessWidget {
  final DriverOrderController controller = Get.find<DriverOrderController>();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SizedBox(
        height: 50,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: controller.statusFilters.length,
          itemBuilder: (context, index) {
            String status = controller.statusFilters[index];

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Obx(() => ChoiceChip(
                    label: Text(
                      status,
                      style: TextStyle(
                        color: controller.selectedFilter.value == status
                            ? Colors.white
                            : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    selected: controller.selectedFilter.value == status,
                    onSelected: (selected) {
                      controller.selectedFilter.value = status;
                      controller.filterOrders();
                    },
                    selectedColor: AppColors.rectangleColor,
                    checkmarkColor: Colors.white,
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          32), // ✅ Correct way to add borderRadius
                    ),
                  )),
            );
          },
        ),
      ),
    );
  }
}
