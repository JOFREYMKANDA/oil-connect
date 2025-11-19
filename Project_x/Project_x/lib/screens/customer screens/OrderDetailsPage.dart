import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:intl/intl.dart';
import 'package:oil_connect/backend/controllers/downloadController.dart';
import 'package:oil_connect/backend/controllers/orderController.dart';
import 'package:oil_connect/screens/customer%20screens/live_location.dart';
import 'package:oil_connect/utils/colors.dart';
import 'package:oil_connect/widget/AppBar.dart';
import 'package:oil_connect/backend/models/order_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class Orderdetailspage extends StatefulWidget {
  const Orderdetailspage({super.key});

  @override
  State<Orderdetailspage> createState() => _OrderWidgetState();
}

class _OrderWidgetState extends State<Orderdetailspage> {
  final OrderController _orderController = Get.put(OrderController());
  Order? order;
  bool isLoading = true;

  // Get the controller (use find if already registered elsewhere)
final DownloadController downloadController = 
    Get.isRegistered<DownloadController>() 
      ? Get.find<DownloadController>() 
      : Get.put(DownloadController());

  @override
  void initState() {
    super.initState();
    _fetchOrder();
  }

  Future<void> _fetchOrder() async {
    final args = Get.arguments;
    final orderId = args['orderId'];

    print("Fetching order details for: $orderId");

    Order? fetched = await _orderController.fetchOrderById(orderId);
    if (mounted) {
      setState(() {
        order = fetched;
        isLoading = false;
      });
    }

    if (fetched != null) {
      final orderJson =
          const JsonEncoder.withIndent('  ').convert(fetched.toJson());
      print("Fetched Order Data:\n$orderJson");
    }
  }

  // Example function to launch a download URL
  // void _downloadFile(String url) async {
  //   if (await canLaunch(url)) {
  //     await launch(url);
  //   } else {
  //     Get.snackbar("Error", "Cannot open file URL");
  //   }
  // }

    // ✅ Function to format large numbers with commas
  String _formatNumber(dynamic number) {
    if (number == null) return "N/A";
    return NumberFormat("#,###").format(number);
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


/// Download driver license — pass the ORDER id (not driver id)
void _downloadDriverLicense() {
  final orderId = order?.orderId;
  if (orderId != null && orderId.toString().isNotEmpty) {
    // controller expects orderId (String)
    downloadController.downloadDriverLicense(orderId.toString());
  } else {
    Get.snackbar("Error", "Order id not available");
  }
}

/// Download vehicle (truck) card — pass the vehicle/truck id
void _downloadVehicleCard() {
  final vehicleId = order?.populatedVehicle?.id;
  if (vehicleId != null && vehicleId.toString().isNotEmpty) {
    downloadController.downloadTruckCard(vehicleId.toString());
  } else {
    Get.snackbar("Error", "Vehicle card not available");
  }
}   


/// ✅ Share downloaded Driver License
Future<void> _shareDriverLicense() async {
  final orderId = order?.orderId;
  if (orderId == null || orderId.toString().isEmpty) {
    Get.snackbar("Error", "Order id not available");
    return;
  }

  try {
    // assume your DownloadService saves files locally (update path accordingly)
    final Directory dir = await getApplicationDocumentsDirectory();
    final filePath = "${dir.path}/driver_license_$orderId.pdf";

    final file = File(filePath);
    if (await file.exists()) {
      await Share.shareXFiles([XFile(file.path)], text: "Driver License for order #$orderId");
    } else {
      Get.snackbar("Not Found", "Please download the Driver License first");
    }
  } catch (e) {
    Get.snackbar("Error", "Failed to share: $e");
  }
}

/// ✅ Share downloaded Vehicle Card
Future<void> _shareVehicleCard() async {
  final vehicleId = order?.populatedVehicle?.id;
  if (vehicleId == null || vehicleId.toString().isEmpty) {
    Get.snackbar("Error", "Vehicle ID not available");
    return;
  }

  try {
    final Directory dir = await getApplicationDocumentsDirectory();
    final filePath = "${dir.path}/vehicle_card_$vehicleId.pdf";

    final file = File(filePath);
    if (await file.exists()) {
      await Share.shareXFiles([XFile(file.path)], text: "Vehicle Card for vehicle #$vehicleId");
    } else {
      Get.snackbar("Not Found", "Please download the Vehicle Card first");
    }
  } catch (e) {
    Get.snackbar("Error", "Failed to share: $e");
  }
}


  // Secondary button style for less important actions
  ButtonStyle _getSecondaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.primaryColor,
      elevation: 1,
      // shadowColor: Colors.black12,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side:const BorderSide(color: AppColors.primaryColor, width: 1.5),
      ),
    );
  }

  // Outline button style for tracking action
  ButtonStyle _getTrackingButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.primaryColor.withOpacity(0.3), width: 1),
      ),
    );
  }

  // Success button style for support actions
  ButtonStyle _getSupportButtonStyle(Color color) {
    return ElevatedButton.styleFrom(
      backgroundColor: color.withOpacity(0.1),
      foregroundColor: color,
      elevation: 0,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: color.withOpacity(0.3), width: 1),
      ),
    );
  }




// Function to call support
  void _callSupport() async {
    const supportPhone = "+255759221066"; // Replace with actual support number
    const url = 'tel:$supportPhone';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      Get.snackbar("Error", "Cannot make a call");
    }
  }

  // Function to WhatsApp support
  void _whatsAppSupport() async {
    const supportPhone = "+255759221066"; // Replace with actual support number
    const message = "Hello, I need help with my pending order";
    final url = 'https://wa.me/$supportPhone?text=${Uri.encodeComponent(message)}';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      Get.snackbar("Error", "Cannot open WhatsApp");
    }
  }


  // Function to navigate to order tracking
void _goToOrderTracking() {
  if (order == null) {
    Get.snackbar("Error", "Order information not available");
    return;
  }
  
  // Replace with your actual tracking logic
  // Get.toNamed('/order-tracking', arguments: {'orderId': order!.orderId});
  print("Opening live location for Order ID: ${order!.orderId}");

  // Example: Navigate to a new screen with map
  Get.to(() => LiveLocationScreen(order: order!));
}



// Check if order is pending
  bool get _isPendingOrder => order?.status.toLowerCase() == 'pending';

  // Check if order is on delivery (for tracking)
  bool get _isOnDelivery => order?.status.toLowerCase() == 'ondelivery';
  


  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    final orderId = args['orderId'];

    return Scaffold(
      appBar: BackAppBar(
        title: '#$orderId',
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryColor,
            ))
            : order == null
                ? const Center(child: Text("Order not found"))
                : Padding(
                    padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                    child: ListView(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10), 

                            // Support Banner for Pending Orders
                            if (_isPendingOrder) _buildSupportBanner(),

                            // Tracking Available Banner for On Delivery Orders
                            if (_isOnDelivery) _buildTrackingBanner(),

                            const SizedBox(height: 10), 
                            Text(
                              "#$orderId",           
                            style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                              ),
                              Text(
                              order!.getFormattedDate(),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 10),

                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: getStatusColor(order!.status).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: getStatusColor(order!.status).withOpacity(0.3)),
                              ),
                              child: Text(
                                    order!.status,
                                    style: TextStyle(
                                      color: getStatusColor(order!.status),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                            ),
                        
                            const SizedBox(height: 10),
                              Text(
                              "Tsh. ${_formatNumber(order!.price)}/=",
                              style:const TextStyle(
                                fontSize: 20,
                                color: Colors.black,
                                fontWeight: FontWeight.w700
                              ),
                            ),
                            const SizedBox(height: 20),

                          ],
                        ),
                        // const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start, // top-align text
                          children: [
                            // Left side title
                            const Text(
                              "Fuel Type",
                              style: TextStyle(
                                color: AppColors.textColor,
                                ),
                            ),

                            // Right side value, flexible so it can wrap or shrink
                            Flexible(
                              child: Text(
                                order!.fuelType,
                                textAlign: TextAlign.right,
                                softWrap: true, // wrap text if it's too long
                                overflow: TextOverflow.ellipsis,
                                style:const TextStyle(
                                  color: AppColors.textColor,
                                  fontWeight: FontWeight.w600
                                  ) // optional, truncate if needed
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start, // top-align text
                          children: [
                            // Left side title
                            const Text(
                              "Station",
                              style: TextStyle(fontWeight: FontWeight.w400),
                            ),

                            // Right side value, flexible so it can wrap or shrink
                            Flexible(
                              child: Text(
                                '${order!.populatedStations.isNotEmpty ? order!.populatedStations[0].label : 'No station'}(${order!.stationName})',
                                textAlign: TextAlign.right,
                                softWrap: true, // wrap text if it's too long
                                overflow: TextOverflow.ellipsis,
                                style:const TextStyle(
                                  color: AppColors.textColor,
                                  fontWeight: FontWeight.w600
                                  ) // optional, truncate if needed
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                         Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start, // top-align text
                          children: [
                            // Left side title
                            const Text(
                              "Depot",
                              style: TextStyle(fontWeight: FontWeight.w400),
                            ),

                            // Right side value, flexible so it can wrap or shrink
                            Flexible(
                              child: Text(
                                '${order!.companyName} (${order!.depot})',
                                textAlign: TextAlign.right,
                                softWrap: true, // wrap text if it's too long
                                overflow: TextOverflow.ellipsis,
                                style:const TextStyle(
                                  color: AppColors.textColor,
                                  fontWeight: FontWeight.w600
                                  ) // optional, truncate if needed
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start, // top-align text
                          children: [
                            // Left side title
                            const Text(
                              "Delivery region",
                              style: TextStyle(fontWeight: FontWeight.w400),
                            ),

                            // Right side value, flexible so it can wrap or shrink
                            Flexible(
                              child: Text(
                                order!.region,
                                textAlign: TextAlign.right,
                                softWrap: true, // wrap text if it's too long
                                overflow: TextOverflow.ellipsis,
                                style:const TextStyle(
                                  color: AppColors.textColor,
                                  fontWeight: FontWeight.w600
                                  ) // optional, truncate if needed
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8), 
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start, // top-align text
                          children: [
                            // Left side title
                            const Text(
                              "Delivery District",
                              style: TextStyle(fontWeight: FontWeight.w400),
                            ),

                            // Right side value, flexible so it can wrap or shrink
                            Flexible(
                              child: Text(
                                order!.district,
                                textAlign: TextAlign.right,
                                softWrap: true, // wrap text if it's too long
                                overflow: TextOverflow.ellipsis,
                                style:const TextStyle(
                                  color: AppColors.textColor,
                                  fontWeight: FontWeight.w600
                                  ) // optional, truncate if needed
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start, // top-align text
                          children: [
                            // Left side title
                            const Text(
                              "Source",
                              style: TextStyle(fontWeight: FontWeight.w400),
                            ),

                            // Right side value, flexible so it can wrap or shrink
                            Flexible(
                              child: Text(
                                order!.source,
                                textAlign: TextAlign.right,
                                softWrap: true, // wrap text if it's too long
                                overflow: TextOverflow.ellipsis,
                                style:const TextStyle(
                                  color: AppColors.textColor,
                                  fontWeight: FontWeight.w600
                                  ) // optional, truncate if needed
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start, // top-align text
                          children: [
                            // Left side title
                            const Text(
                              "Source Company",
                              style: TextStyle(fontWeight: FontWeight.w400),
                            ),

                            // Right side value, flexible so it can wrap or shrink
                            Flexible(
                              child: Text(
                                order!.companyName,
                                textAlign: TextAlign.right,
                                softWrap: true, // wrap text if it's too long
                                overflow: TextOverflow.ellipsis,
                                style:const TextStyle(
                                  color: AppColors.textColor,
                                  fontWeight: FontWeight.w600
                                  ) // optional, truncate if needed
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),
                        // const SizedBox(height: 8), - 
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start, // top-align text
                          children: [
                            // Left side title
                            const Text(
                              "RouteWay",
                              style: TextStyle(fontWeight: FontWeight.w400),
                            ),

                            // Right side value, flexible so it can wrap or shrink
                            Flexible(
                              child: Text(
                                order!.routeWay,
                                textAlign: TextAlign.right,
                                softWrap: true, // wrap text if it's too long
                                overflow: TextOverflow.ellipsis,
                                style:const TextStyle(
                                  color: AppColors.textColor,
                                  fontWeight: FontWeight.w600
                                  ) // optional, truncate if needed
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start, // top-align text
                          children: [
                            // Left side title
                            const Text(
                              "Volume",
                              style: TextStyle(fontWeight: FontWeight.w400),
                            ),

                            // Right side value, flexible so it can wrap or shrink
                            Flexible(
                              child: Text(
                                 "${_formatNumber(order!.capacity)}L",
                                textAlign: TextAlign.right,
                                softWrap: true, // wrap text if it's too long
                                overflow: TextOverflow.ellipsis, 
                                style:const TextStyle(
                                  color: AppColors.textColor,
                                  fontWeight: FontWeight.w600
                                  )// optional, truncate if needed
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8), 
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start, // top-align text
                          children: [
                            // Left side title
                            const Text(
                              "Delivery Date",
                              style: TextStyle(fontWeight: FontWeight.w400),
                            ),

                            // Right side value, flexible so it can wrap or shrink
                            Flexible(
                              child: Text(
                                order!.deliveryTime,
                                textAlign: TextAlign.right,
                                softWrap: true, // wrap text if it's too long
                                overflow: TextOverflow.ellipsis,
                                style:const TextStyle(
                                  color: AppColors.textColor,
                                  fontWeight: FontWeight.w600
                                  ) // optional, truncate if needed
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                         // THREE BUTTONS SECTION
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Column(
                            children: [

                              if (order!.populatedDriver != null) ...[
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      label: const Text("Download Driver License"),
                                      onPressed: _downloadDriverLicense,
                                      style: _getSecondaryButtonStyle(),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      label: const Text("Share Driver License"),
                                      onPressed: _shareDriverLicense,
                                      style: _getSecondaryButtonStyle(),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],

                              if (order!.populatedVehicle != null) ...[
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      label: const Text("Download Vehicle Card"),
                                      onPressed: _downloadVehicleCard,
                                      style: _getSecondaryButtonStyle(),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      label: const Text("Share Vehicle Card"),
                                      onPressed: _shareVehicleCard,
                                      style: _getSecondaryButtonStyle(),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],



                              // Go to Order Tracking Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  
                                  label: const Text("Go to Order Tracking"),
                                  onPressed: _goToOrderTracking,
                                  style:  _getTrackingButtonStyle(),
                                ),
                              ),
                            ],
                          ),
                        ),

                         
                        // Support Buttons for Pending Orders
                        if (_isPendingOrder) ...[
                          const Row(
                            children: [
                              Icon(Icons.support_agent, size: 16, color: Colors.grey),
                              SizedBox(width: 6),
                              Text(
                                "Contact Support",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              // Call Support Button
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.phone, size: 18),
                                  label: const Text("Call Support"),
                                  onPressed: _callSupport,
                                  style: _getSupportButtonStyle(AppColors.primaryColor),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // WhatsApp Support Button
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(FontAwesome.whatsapp_brand, size: 18),
                                  label: const Text("WhatsApp"),
                                  onPressed: _whatsAppSupport,
                                  style: _getSupportButtonStyle(AppColors.primaryColor),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Tracking Button for On Delivery Orders
                        // if (_isOnDelivery) ...[
                        //   SizedBox(
                        //     width: double.infinity,
                        //     child: ElevatedButton.icon(
                        //       // icon: const Icon(Icons.map_outlined, size: 22),
                        //       label: const Text(
                        //         "Track Order ",
                        //         style: TextStyle(
                        //           fontSize: 16,
                        //           fontWeight: FontWeight.w600,
                        //         ),
                        //       ),
                        //       onPressed: _goToOrderTracking,
                        //       style: _getTrackingButtonStyle(),
                        //     ),
                        //   ),
                        //   const SizedBox(height: 12),
                        // ],

                       

                     
                        
                        // const Divider(),
        
                        // DRIVER DETAILS
                        // if (order!.populatedDriver != null) ...[
                        //   const Text(
                        //     "Driver Details",
                        //     style: TextStyle(
                        //         fontSize: 16, fontWeight: FontWeight.bold),
                        //   ),
                        //   const SizedBox(height: 4),
                        //   Text("Name: ${order!.populatedDriver!.name}"),
                        //   Text("Phone: ${order!.populatedDriver!.phone}"),
                        //   Text("Status: ${order!.populatedDriver!.status}"),
                        //   const SizedBox(height: 4),
                        //   ElevatedButton.icon(
                        //     icon: const Icon(Icons.download),
                        //     label: const Text("Download Driver License"),
                        //     onPressed: () {
                        //       // replace with actual driver license URL
                        //       _downloadFile(
                        //           "https://example.com/driver_license/${order!.populatedDriver!.id}");
                        //     },
                        //   ),
                        //   const Divider(),
                        // ],
        
                        // TRUCK OWNER DETAILS
                        // if (order!.populatedTruckOwner != null) ...[
                        //   const Text(
                        //     "Truck Owner Details",
                        //     style: TextStyle(
                        //         fontSize: 16, fontWeight: FontWeight.bold),
                        //   ),
                        //   const SizedBox(height: 4),
                        //   Text("Name: ${order!.populatedTruckOwner!.name}"),
                        //   Text("Phone: ${order!.populatedTruckOwner!.phone}"),
                        //   Text("Company: ${order!.populatedTruckOwner!.company}"),
                        //   const Divider(),
                        // ],


                        
        
                        // VEHICLE DETAILS
                        // if (order!.populatedVehicle != null) ...[
                        //   Text(
                        //     "Vehicle Details".toUpperCase(),
                            
                        //     style:const TextStyle(
                        //         fontSize: 16, 
                        //         fontWeight: FontWeight.w500,
                        //         color: Colors.black38
                        //       ),
                        //   ),
                        //   const SizedBox(height: 8),
                        //   Text(
                        //       "Identity: ${order!.populatedVehicle!.vehicleIdentity}"),
                        //   Text("Fuel Type: ${order!.populatedVehicle!.fuelType}"),
                        //   Text(
                        //       "Tank Capacity: ${order!.populatedVehicle!.tankCapacity}"),
                        //   const SizedBox(height: 4),
                        //   ElevatedButton.icon(
                        //     icon: const Icon(Icons.download),
                        //     label: const Text("Download Vehicle Card"),
                        //     onPressed: () {
                        //       // replace with actual vehicle card URL
                        //       _downloadFile(
                        //           "https://example.com/vehicle_card/${order!.populatedVehicle!.id}");
                        //     },
                        //   ),
                        //   const Divider(),
                        // ],
                      ],
                    ),
                  ),
      ),
    );
  }

   Widget _buildSupportBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1), // Light amber background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFF0C2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.amber[700],
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                "Need Help?",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF7A5A00),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "Your order is currently pending. Contact our support team for assistance with your order status.",
            style: TextStyle(
              color: Color(0xFF7A5A00),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F7FA), // Light cyan background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFB2EBF2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.delivery_dining,
                color: Colors.cyan[700],
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                "On the Way!",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF006064),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "Your order is out for delivery. Track its live location in real-time.",
            style: TextStyle(
              color: Color(0xFF006064),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }


}


