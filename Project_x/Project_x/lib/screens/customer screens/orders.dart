import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oil_connect/backend/controllers/downloadController.dart';
import 'package:oil_connect/backend/controllers/orderController.dart';
import 'package:oil_connect/backend/models/order_model.dart';
import 'package:oil_connect/screens/customer%20screens/OrderDetailsPage.dart';
import 'package:oil_connect/utils/colors.dart';
import 'package:oil_connect/widget/AppBar.dart';
import 'package:oil_connect/widget/bottom_navigation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final OrderController orderController = Get.put(OrderController());
  final DownloadController downloadController = Get.put(DownloadController());
  final TextEditingController _searchController = TextEditingController();

  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    orderController.fetchOrders(); // initial fetch

    // Auto-refresh every 10 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      orderController.fetchOrders();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel(); // Cancel the timer to avoid memory leaks
    _searchController.dispose(); // Dispose the search controller
    super.dispose();
  }

  /// ✅ Function to Get Status Color Dynamically
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

/// ✅ Get Status Icon
IconData getStatusIcon(String status) {
  switch (status.toLowerCase()) {
    case "completed":
      return Icons.check_circle;
    case "approved":
      return Icons.verified; // Better for approved
    case "accepted":
      return Icons.thumb_up;
    case "assigned":
      return Icons.assignment;
    case "ondelivery":
      return Icons.local_shipping;
    case "pending":
      return Icons.schedule;
    case "requested":
      return Icons.pending_actions;
    case "cancelled":
      return Icons.cancel;
    default:
      return Icons.info;
  }
}



  // ✅ Function to format large numbers with commas
  String _formatNumber(dynamic number) {
    if (number == null) return "N/A";
    return NumberFormat("#,###").format(number);
  }

  /// ✅ Make a Phone Call
  void makePhoneCall() async {
    const phoneNumber = "+255759221066";
    final uri = Uri.parse("tel:$phoneNumber");

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      Get.snackbar(
        "Error",
        "Could not make a call",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? const Color(0xFF121212) 
          : const Color(0xFFFFFFFF),
      appBar: const BackAppBar(title: 'Orders'),
      body: SafeArea(
        child: Column(
          children: [
            /// ✅ Search Bar
            _buildSearchBar(),
            
            /// ✅ Fixed Horizontal Scrollable Status Filter
            _orderStatusFilter(),
        
            /// ✅ Order List
            Expanded(
                child: Obx(() {
                 // Show loading only when actually loading and no orders exist yet
                 if (orderController.isLoading.value && orderController.orders.isEmpty) {
                   return Center(
                     child: Column(
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                         CircularProgressIndicator(color: AppColors.rectangleColor),
                         const SizedBox(height: 16),
                         const Text("Loading orders...", style: TextStyle(fontSize: 16, color: Colors.grey)),
                       ],
                     ),
                   );
                 }
        
                // Show empty state when not loading and no filtered orders
                 if (orderController.filteredOrders.isEmpty) {
                   return _buildEmptyState();
                 }

                return RefreshIndicator(
                  color: AppColors.rectangleColor,
                  onRefresh: () async {
                    await orderController.fetchOrders();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: orderController.filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = orderController.filteredOrders[index];
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

  /// Enhanced Order Card
  Widget _buildOrderCard(Order order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? Colors.grey[900] 
            : const Color(0xfffafafa),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:const Color(0xfff5f5f5)

        )
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
          // Navigate to OrderDetailsPage with parameters
          Get.to(
            () => const Orderdetailspage(),
            arguments: {
              'orderId': order.orderIdGenerated,
              'orderData': order, // pass the entire order object if needed
            },
          );
        },
          child: Padding(
            padding: const EdgeInsets.all(20),
             child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Text(
                  "#${order.orderIdGenerated}",           
                 style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                  ),
                  Text(
                  order.getFormattedDate(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
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
                const SizedBox(height: 10),
                  Text(
                  "Tsh. ${_formatNumber(order.price)}/=",
                  style:const TextStyle(
                    fontSize: 20,
                    color: Colors.black,
                    fontWeight: FontWeight.w700
                  ),
                ),
                const SizedBox(height: 20),

                 // Order details
                Row(
                  children: [
                    Expanded(
                      child: _buildOrderDetail("Fuel Type", order.fuelType, Icons.local_gas_station),
                    ),
                    Expanded(
                      child: _buildOrderDetail("Volume", "${_formatNumber(order.capacity)}L", Icons.straighten),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildOrderDetail("From", '${order.companyName} (${order.depot})', Icons.business),
                    ),
                    Expanded(
                      child: _buildOrderDetail("To", '${order.populatedStations.isNotEmpty ? order.populatedStations[0].label : 'N/A'} (${order.stationName})', Icons.location_on),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
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

  /// Empty State
  Widget _buildEmptyState() {
    return Obx(() {
      bool isSearching = orderController.searchQuery.value.isNotEmpty;
      
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSearching ? Icons.search_off : Icons.receipt_long,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isSearching ? "No Search Results" : "No Orders Found",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearching 
                ? "No orders match your search criteria"
                : "There are no orders here yet",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
            ),
            if (isSearching) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  _searchController.clear();
                  orderController.clearSearch();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.rectangleColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Clear Search",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  /// ✅ Search Bar Widget
  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? Colors.grey[900] 
            : const Color(0xfffafafa),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xfff5f5f5)
        )
        
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: Colors.grey[600],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search orders by ID, fuel type, depot, station...",
                hintStyle: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                
              ),
              style: const TextStyle(fontSize: 14),
              onChanged: (value) {
                orderController.updateSearchQuery(value);
              },
            ),
          ),
          Obx(() => orderController.searchQuery.value.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    orderController.clearSearch();
                  },
                  child: Icon(
                    Icons.clear,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                )
              : const SizedBox.shrink()),
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
        
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: orderController.statusFilters.length,
              itemBuilder: (context, index) {
                String status = orderController.statusFilters[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Obx(() => ChoiceChip(
                    label: Text(
                      status,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: orderController.selectedFilter.value == status
                            ? Colors.white
                            : Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    selected: orderController.selectedFilter.value == status,
                    onSelected: (selected) {
                      orderController.selectedFilter.value = status;
                      orderController.filterOrders();
                    },
                    selectedColor: AppColors.rectangleColor,
                    checkmarkColor: Colors.white,
                    backgroundColor: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.grey[800] 
                        : Colors.grey[100],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: orderController.selectedFilter.value == status
                            ? Colors.transparent
                            : Colors.grey.shade300,
                      ),
                    ),
                  ),
                ),);
              }
          ),),
        ],
      ),
    );
  }
}