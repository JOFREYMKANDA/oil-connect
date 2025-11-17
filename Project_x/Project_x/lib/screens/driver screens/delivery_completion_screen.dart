import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oil_connect/backend/controllers/driverController.dart';
import 'package:oil_connect/backend/models/order_model.dart';
import 'package:oil_connect/utils/colors.dart';
import 'package:google_fonts/google_fonts.dart';

class DeliveryCompletionScreen extends StatefulWidget {
  final Order order;

  const DeliveryCompletionScreen({super.key, required this.order});

  @override
  State<DeliveryCompletionScreen> createState() => _DeliveryCompletionScreenState();
}

class _DeliveryCompletionScreenState extends State<DeliveryCompletionScreen> {
  final DriverOrderController controller = Get.find<DriverOrderController>();
  final TextEditingController _notesController = TextEditingController();
  bool _isCompleting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? const Color(0xFF121212) 
          : const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: AppColors.rectangleColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.shapeColor),
        centerTitle: true,
        title: const Text(
          "Complete Delivery",
          style: TextStyle(color: AppColors.shapeColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// ✅ Order Summary Card
              _buildOrderSummaryCard(),
              
              const SizedBox(height: 24),
              
              /// ✅ Delivery Details
              _buildDeliveryDetailsCard(),
              
              const SizedBox(height: 24),
              
              /// ✅ Completion Notes
              _buildCompletionNotesCard(),
              
              const SizedBox(height: 32),
              
              /// ✅ Action Buttons
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  /// ✅ Order Summary Card
  Widget _buildOrderSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? Colors.grey[900] 
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_long,
                color: AppColors.rectangleColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                "Order Summary",
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryRow("Order ID", widget.order.orderIdGenerated ?? widget.order.orderId),
          _buildSummaryRow("Fuel Type", widget.order.fuelType),
          _buildSummaryRow("Volume", "${_formatNumber(widget.order.capacity)} Liters"),
          _buildSummaryRow("Depot", "${widget.order.companyName}, ${widget.order.source}"),
          _buildSummaryRow("Destination", "${widget.order.stationName}, ${widget.order.district}"),
        ],
      ),
    );
  }

  /// ✅ Delivery Details Card
  Widget _buildDeliveryDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? Colors.grey[900] 
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_shipping,
                color: Colors.blue.shade700,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                "Delivery Details",
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryRow("Driver", widget.order.driverName),
          _buildSummaryRow("Vehicle ID", widget.order.vehicleId),
          _buildSummaryRow("Status", widget.order.status),
          _buildSummaryRow("Customer", "${widget.order.customerFirstName} ${widget.order.customerLastName}"),
          _buildSummaryRow("Phone", widget.order.customerPhone),
        ],
      ),
    );
  }

  /// ✅ Completion Notes Card
  Widget _buildCompletionNotesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? Colors.grey[900] 
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.note_add,
                color: Colors.orange.shade700,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                "Delivery Notes (Optional)",
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: "Add any notes about the delivery...",
              hintStyle: GoogleFonts.inter(
                color: Colors.grey[500],
                fontSize: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.rectangleColor, width: 2),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
            style: GoogleFonts.inter(fontSize: 14),
          ),
        ],
      ),
    );
  }

  /// ✅ Action Buttons
  Widget _buildActionButtons() {
    return Column(
      children: [
        // Complete Delivery Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _isCompleting ? null : _completeDelivery,
            icon: _isCompleting 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.check_circle, size: 24),
            label: Text(
              _isCompleting ? "Completing Delivery..." : "Complete Delivery",
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.rectangleColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Cancel Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: _isCompleting ? null : () => Get.back(),
            icon: const Icon(Icons.cancel, size: 24),
            label: Text(
              "Cancel",
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey.shade700,
              side: BorderSide(color: Colors.grey.shade300, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// ✅ Summary Row Helper
  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ Format Number Helper
  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  /// ✅ Complete Delivery Action
  void _completeDelivery() async {
    setState(() {
      _isCompleting = true;
    });

    try {
      final success = await controller.completeDelivery(widget.order.orderId);
      
      if (success) {
        // Show success message
        Get.snackbar(
          "Delivery Completed",
          "You have successfully completed the delivery",
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
          icon: const Icon(Icons.check_circle, color: Colors.white),
        );
        
        // Navigate back
        Get.back();
      } else {
        // Show error message
        Get.snackbar(
          "Error",
          "Failed to complete delivery. Please try again.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
          icon: const Icon(Icons.error, color: Colors.white),
        );
      }
    } catch (e) {
      // Show error message
      Get.snackbar(
        "Error",
        "An error occurred. Please try again.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
        icon: const Icon(Icons.error, color: Colors.white),
      );
    } finally {
      setState(() {
        _isCompleting = false;
      });
    }
  }
}
