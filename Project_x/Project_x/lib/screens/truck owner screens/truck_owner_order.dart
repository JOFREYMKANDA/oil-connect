import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:oil_connect/backend/controllers/truckownerController.dart';
import 'package:oil_connect/backend/models/order_model.dart';
import 'package:oil_connect/utils/colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oil_connect/widget/primary_app_bar.dart';

class TruckOwnerOrdersScreen extends StatefulWidget {
  const TruckOwnerOrdersScreen({super.key});

  @override
  State<TruckOwnerOrdersScreen> createState() => _TruckOwnerOrdersScreenState();
}

class _TruckOwnerOrdersScreenState extends State<TruckOwnerOrdersScreen> {
  final TruckOwnerController controller = Get.put(TruckOwnerController(), permanent: true);

  @override
  void initState() {
    super.initState();
    // Only fetch if we don't have data yet to avoid setState during build
    if (controller.acceptedOrders.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.fetchAcceptedOrders();
      });
    }
  }

  void _showDriverSelection(BuildContext context, String orderId) async {
    await controller.fetchAvailableDrivers();

    Get.bottomSheet(
      Container(
        height: 420,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Obx(() {
          if (controller.isLoadingDrivers.value) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.green),
            );
          }

          if (controller.availableDrivers.isEmpty) {
            return const Center(
              child: Text("🚫 No Available Drivers Found",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.red)),
            );
          }

          return ListView.builder(
            itemCount: controller.availableDrivers.length,
            itemBuilder: (context, index) {
              var driver = controller.availableDrivers[index];
              String driverId = driver["_id"] ?? "UNKNOWN_ID";
              String driverName =
              "${driver["firstname"] ?? "Unknown"} ${driver["lastname"] ?? ""}".trim();
              String phone = driver["phoneNumber"]?.toString() ?? "N/A";

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white12
                        : Colors.grey.shade300,
                  ),
                ),
                child: ListTile(
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.shade700,
                    child: Text(
                      driverName.isNotEmpty ? driverName[0] : "U",
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(driverName,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  subtitle: Text("📞 $phone",
                      style: Theme.of(context).textTheme.bodySmall),
                  trailing: Obx(() {
                    final isLoading = controller.isLoadingAssignDriver.value;

                    return ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () {
                        controller.isLoadingAssignDriver.value = true;
                        _showAssignConfirmation(context, driverId, driverName, orderId);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.rectangleColor,
                        foregroundColor: AppColors.shapeColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      child: isLoading
                          ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.green.shade900,
                        ),
                      )
                          : const Text("Assign"),
                    );
                  }),
                ),
              );
            },
          );
        }),
      ),
      isScrollControlled: true,
    );
  }

  void _showAssignConfirmation(BuildContext context, String driverId, String driverName, String orderId) {
    Get.defaultDialog(
      title: "Confirm Assignment",
      middleText: "Are you sure you want to assign $driverName to this order?",
      textConfirm: "Yes, Assign",
      textCancel: "Cancel",
      confirmTextColor: Colors.white,
      buttonColor: Colors.green,
      onConfirm: () async {
        Get.back(); // ✅ Close confirmation dialog
        bool success = await controller.assignDriver(driverId, orderId);
        if (success) {
          Get.back(); // ✅ Close driver selection bottom sheet
          Get.back(); // ✅ Close order details bottom sheet (optional, if you want to auto-dismiss it too)
          // Defer fetchAcceptedOrders to avoid setState during build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            controller.fetchAcceptedOrders();
          });
        }
      },
    );
  }

  String formatNumber(dynamic number) {
    if (number == null) return "0";
    return NumberFormat("#,###").format(number);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? const Color(0xFF121212) 
          : const Color(0xFFF8F9FA),
      appBar: const PrimaryAppBar(
        title: "Truck Owner Orders",
        backgroundColor: Color(0xFFF8F9FA),
      ),
      body: SafeArea(
        child: Column(
        children: [
            /// ✅ Fixed Horizontal Scrollable Status Filter
            _orderStatusFilter(),

          /// ✅ Order List
          Expanded(
            child: Obx(() {
                 // Show loading only when actually loading and no orders exist yet
                 if (controller.isLoading.value && controller.filteredOrders.isEmpty) {
                   return Center(
                     child: Column(
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                         CircularProgressIndicator(color: AppColors.rectangleColor),
                         const SizedBox(height: 16),
                         Text(
                           "Loading orders...", 
                           style: GoogleFonts.inter(
                             fontSize: 16, 
                             color: Colors.grey,
                             fontWeight: FontWeight.w500,
                           ),
                         ),
                       ],
                     ),
                   );
                 }
        
                // Show empty state when not loading and no filtered orders
                 if (controller.filteredOrders.isEmpty) {
                   return _buildEmptyState();
                 }

              return RefreshIndicator(
                  color: AppColors.rectangleColor,
                  onRefresh: () async {
                    await controller.fetchAcceptedOrders();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: controller.filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = controller.filteredOrders[index];
                      return _buildOrderCard(order);
                    },
                  ),
                );
            }),
          ),
        ],
        ),
      ),
    );
  }

  /// ✅ Function to Show Order Details in Bottom Sheet (Prevents Overflow)
  void _showOrderDetails(BuildContext context, Order order) {
    bool isShared = order.routeWay == "shared";

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ✅ Title with Icon
              Row(
                children: [
                  Icon(isShared ? Icons.group : Icons.person,
                      color: isShared ? Colors.orange : Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    isShared ? "Shared Order Details" : "Private Order Details",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Divider(),

              // ✅ General Details
              _buildDetailRow(context, "Fuel Type", order.fuelType),
              _buildDetailRow(context, "Total Volume", "${formatNumber(order.capacity)} Liters"),
              _buildDetailRow(context, "Total Price", "Tsh. ${formatNumber(order.price?.toInt() ?? 0)}/="),
              _buildDetailRow(context, "Depot", "${order.companyName}, ${order.source}, ${order.depot}"),

              const SizedBox(height: 5),
              const Divider(),

              // ✅ Driver Info
              Text(
                "Assigned Driver",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              _buildDetailRow(context, "Name", order.driverName),
              _buildDetailRow(context, "Phone", order.driverPhone),
              _buildDetailRow(context, "Vehicle ID", order.vehicleId),

              if (isShared) ...[
                const SizedBox(height: 5),
                const Divider(),

                Text(
                  "Customer Details",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),

                ...List.generate(order.customers.length, (i) {
                  final c = order.customers[i];
                  final s = c.stationDetails.isNotEmpty ? c.stationDetails[0] : null;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Customer ${i + 1}",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          Text("Order ID: ${order.customers[i].orderId}",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.grey.shade600)),
                        ],
                      ),

                      _buildDetailRow(context, "Name", "${c.firstname} ${c.lastname}"),
                      _buildDetailRow(context, "Phone", c.phoneNumber),
                      _buildDetailRow(context, "Volume", "${formatNumber(c.capacity)} Liters"),
                      _buildDetailRow(context, "Price", "Tsh. ${formatNumber(c.price.toInt())}/="),
                      if (s != null)
                        _buildDetailRow(context, "Destination", "${s.stationName}, ${s.district}, ${s.region}"),
                      if (i != order.customers.length - 1) const Divider(thickness: 1),
                    ],
                  );
                }),
              ] else ...[
                const Divider(),
                Text(
                  "Customer Details",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildDetailRow(context, "Name", "${order.customerFirstName} ${order.customerLastName}"),
                _buildDetailRow(context, "Phone", order.customerPhone),
                _buildDetailRow(context, "Destination", "${order.stationName}, ${order.district}, ${order.region}"),
              ],

              const SizedBox(height: 16),

              if (order.status.toLowerCase() == "accepted") ...[
                const Divider(),
                Obx(() => ElevatedButton.icon(
                  onPressed: controller.isLoadingAssignDriver.value
                      ? null
                      : () => _showDriverSelection(context, order.orderId),
                  icon: controller.isLoadingAssignDriver.value
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Icon(Icons.person_add_alt),
                  label: controller.isLoadingAssignDriver.value
                      ? const Text("Assigning...")
                      : const Text("Assign Driver"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                )),
              ],

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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ Status Color Helper
  Color getStatusColor(String? status) {
    switch (status?.toLowerCase() ?? "") {
      case "pending":
        return const Color(0xFFFFB300);
      case "accepted":
        return const Color(0xFF42A5F5);
      case "assigned":
        return const Color(0xFF1E88E5);
      case "ondelivery":
        return const Color(0xFF43A047);
      case "completed":
        return const Color(0xFF2E7D32);
      case "cancelled":
        return const Color(0xFFE53935);
      default:
        return Colors.grey;
    }
  }

  /// ✅ Get Status Icon
  IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case "pending":
        return Icons.schedule;
      case "accepted":
        return Icons.check_circle_outline;
      case "assigned":
        return Icons.assignment;
      case "ondelivery":
        return Icons.local_shipping;
      case "completed":
        return Icons.check_circle;
      case "cancelled":
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  /// Enhanced Order Card
  Widget _buildOrderCard(Order order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? Colors.grey[900] 
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showOrderDetails(context, order),
          child: Padding(
            padding: const EdgeInsets.all(20),
             child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with status and date
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.routeWay == "shared"
                                ? "Group: ${order.sharedGroupId}"
                                : "Order #${order.orderIdGenerated}",
                            style: GoogleFonts.inter(
                              fontSize: 18,
                    fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            order.getFormattedDate(),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: getStatusColor(order.status).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: getStatusColor(order.status).withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            getStatusIcon(order.status),
                            size: 16,
                            color: getStatusColor(order.status),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            order.status,
                            style: GoogleFonts.inter(
                              color: getStatusColor(order.status),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                 // Order details
                Row(
                  children: [
                    Expanded(
                      child: _buildOrderDetail("Fuel Type", order.fuelType, Icons.local_gas_station),
                    ),
                    Expanded(
                      child: _buildOrderDetail("Volume", "${formatNumber(order.capacity)}L", Icons.straighten),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildOrderDetail("From", order.depot, Icons.business),
                    ),
                    Expanded(
                      child: _buildOrderDetail("To", order.stationName, Icons.location_on),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Driver info and action button
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 16,
                              color: Colors.blue[700],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Driver",
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    order.driverName,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (order.status.toLowerCase() == "pending" || order.status.toLowerCase() == "requested")
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.check_circle_outline, size: 20),
                        label: Text(
                          "Accept Order",
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () async {
                          await controller.acceptOrder(order);
                          // Defer fetch calls to avoid setState during build
                          WidgetsBinding.instance.addPostFrameCallback((_) async {
                            await controller.fetchOrders();
                            await controller.fetchAcceptedOrders();
                          });
                        },
                      ),
                    const SizedBox(width: 12),
                    if (order.status.toLowerCase() == "accepted")
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.rectangleColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.person_add, size: 20),
                        label: Text(
                          "Assign Driver", 
                          style: GoogleFonts.inter(
                            fontSize: 14, 
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () => _showDriverSelection(context, order.orderId),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
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
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
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

  /// Empty State
  Widget _buildEmptyState() {
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
          Text(
            "No Orders Found",
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "There are no orders here yet",
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  /// Enhanced Status Filter
  Widget _orderStatusFilter() {
    return Container(
      margin: const EdgeInsets.all(2),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? Colors.grey[900] 
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: controller.statusFilters.length,
              itemBuilder: (context, index) {
                String status = controller.statusFilters[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Obx(() {
                    bool isSelected = controller.selectedFilter.value == status;
                    return GestureDetector(
                      onTap: () {
                        controller.selectFilterAndUpdate(status);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.rectangleColor : (Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[100]),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? Colors.transparent : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected)
                              const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              ),
                            if (isSelected) const SizedBox(width: 4),
                            Text(
                              status,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: isSelected
                                    ? Colors.white
                                    : Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                );
              }
            ),
          ),
        ],
      ),
    );
  }
}

