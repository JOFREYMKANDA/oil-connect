import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:oil_connect/backend/controllers/truckStatusController.dart';
import 'package:oil_connect/backend/controllers/vehicleController.dart';
import 'package:oil_connect/backend/models/vehicle_model.dart';
import 'package:oil_connect/screens/truck%20owner%20screens/gps_trucking.dart';
import 'package:oil_connect/screens/truck%20owner%20screens/truck%20registration/truckStatus.dart';
import 'package:oil_connect/screens/truck%20owner%20screens/truck%20registration/truck_registration_templates.dart';
import 'package:oil_connect/utils/colors.dart';
import 'package:oil_connect/widget/bottom_navigation.dart';
import 'package:google_fonts/google_fonts.dart';

class TruckListScreen extends StatefulWidget {
  const TruckListScreen({super.key});

  @override
  State<TruckListScreen> createState() => _TruckListScreenState();
}

class _TruckListScreenState extends State<TruckListScreen> {
  final VehicleController vehicleController = Get.put(VehicleController(), permanent: true);
  final MessageController messageController = Get.put(MessageController());

  Timer? _pollingTimer;

  final TextEditingController _searchController = TextEditingController();
  final RxString _searchQuery = ''.obs;
  final RxString _statusFilter = 'all'.obs; // values: all / approved / available / busy / rejected / submitted

  @override
  void initState() {
    super.initState();

    // Initial fetch
    vehicleController.getAllVehicles();

    // Fetch message count
    messageController.fetchUnreadCount();

    // Start polling every 10 seconds for vehicle status
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      vehicleController.getAllVehicles();
      messageController.fetchUnreadCount();
    });

    _searchController.addListener(() {
      _searchQuery.value = _searchController.text.trim();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel(); // Cancel polling when screen is disposed
    _searchController.dispose();
    super.dispose();
  }

  String formatNumber(dynamic value) {
    try {
      final number = double.tryParse(value.toString()) ?? 0;
      final formatter = NumberFormat("#,##0", "en_US");
      return formatter.format(number);
    } catch (_) {
      return value?.toString() ?? "N/A";
    }
  }

  List<Vehicle> _filteredVehicles(List<Vehicle> all) {
    final q = _searchQuery.value.toLowerCase();
    final filter = _statusFilter.value.toLowerCase();
    return all.where((v) {
      final name = (v.vehicleType).toLowerCase();
      final plate = (v.vehicleIdentity ?? '').toString().toLowerCase();
      final status = (v.status ?? '').toLowerCase();

      final matchesQuery = q.isEmpty || name.contains(q) || plate.contains(q);
      final matchesStatus = filter == 'all' || status == filter;

      return matchesQuery && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Get.offAll(() => const RoleBasedBottomNavScreen(role: 'TruckOwner')),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.shapeColor,
        centerTitle: true,
        title: Text(
          'My Trucks',
          style: GoogleFonts.inter(
            fontSize: 20,
            color: Colors.black87,
            fontWeight: FontWeight.w700
          ),
        ),
        actions: [
          Obx(() {
            int count = messageController.unreadCount.value;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.comment), color: Colors.black87,
                    onPressed: () {
                      Get.to(() => const MessageListScreen());
                    },
                  ),
                  if (count > 0)
                    Positioned(
                      top: 8,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          final all = vehicleController.vehicles;

          if (vehicleController.isLoading.value && all.isEmpty) {
            return const Align(
              alignment: Alignment.topCenter,
              child: LinearProgressIndicator(),
            );
          }

          if (all.isEmpty) {
            return RefreshIndicator(
              color: AppColors.rectangleColor,
              onRefresh: () => vehicleController.getAllVehicles(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(child: Icon(Icons.local_shipping_outlined, size: 64, color: Colors.grey)),
                  SizedBox(height: 12),
                  Center(child: Text('No trucks added yet', style: TextStyle(color: Colors.grey))),
                ],
              ),
            );
          }

          final filtered = _filteredVehicles(all);

          return RefreshIndicator(
            color: AppColors.rectangleColor,
            onRefresh: () async => vehicleController.getAllVehicles(),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3)),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: [
                              const Icon(Icons.search, color: Colors.grey),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  decoration: const InputDecoration(
                                    hintText: 'Search by name or plate',
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                              if (_searchQuery.value.isNotEmpty)
                                GestureDetector(
                                  onTap: () {
                                    _searchController.clear();
                                  },
                                  child: const Icon(Icons.close, color: Colors.grey),
                                )
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Status filters
                        SizedBox(
                          height: 42,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              const SizedBox(width: 4),
                              _statusChip('All', 'all'),
                              const SizedBox(width: 8),
                              _statusChip('Approved', 'approved'),
                              const SizedBox(width: 8),
                              _statusChip('Available', 'available'),
                              const SizedBox(width: 8),
                              _statusChip('Busy', 'busy'),
                              const SizedBox(width: 8),
                              _statusChip('Rejected', 'rejected'),
                              const SizedBox(width: 8),
                              _statusChip('Submitted', 'submitted'),
                              const SizedBox(width: 4),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('${filtered.length} trucks', style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),

                // List
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final vehicle = filtered[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: _ModernTruckCard(
                          vehicle: vehicle,
                          onTap: () => showTruckDetailsBottomSheet(context, vehicle),
                          statusColor: _getStatusColor(vehicle.status),
                          formatNumber: formatNumber,
                        ),
                      );
                    },
                    childCount: filtered.length,
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          );
        }),
      ),

      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Obx(() {
            final anyApproved = vehicleController.vehicles.any((v) => (v.status ?? '').toLowerCase() == 'approved');
            if (!anyApproved) return const SizedBox.shrink();
            return FloatingActionButton.extended(
              heroTag: 'mapBtn',
              backgroundColor: AppColors.rectangleColor,
              icon: const Icon(Icons.map, color: Colors.white),
              label: const Text('Map', style: TextStyle(color: Colors.white)),
              onPressed: () => Get.to(() => const GpsTrackingScreen()),
            );
          }),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'addBtn',
            backgroundColor: AppColors.primaryColor,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('New Truck', style: TextStyle(color: Colors.white)),
            onPressed: () async {
              await Get.to(() => const CarRegistrationTemplate());
              await vehicleController.getAllVehicles();
            },
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return AppColors.rectangleColor;
      case 'submitted':
        return AppColors.blueColor;
      case 'rejected':
        return AppColors.redColor;
      case 'available':
        return Colors.green;
      case 'busy':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _statusChip(String label, String value) {
    return Obx(() {
      final selected = _statusFilter.value == value;
      return GestureDetector(
        onTap: () => _statusFilter.value = value,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected ? [BoxShadow(color: AppColors.rectangleColor.withOpacity(0.12), blurRadius: 6)] : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6)],
            border: Border.all(color: selected ? Colors.transparent : Colors.grey.shade200),
          ),
          child: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.grey[700], fontWeight: FontWeight.w600)),
        ),
      );
    });
  }

  void showTruckDetailsBottomSheet(BuildContext context, Vehicle vehicle) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  height: 5,
                  width: 60,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: _getStatusColor(vehicle.status).withOpacity(0.12),
                    child: Icon(Icons.local_shipping, color: _getStatusColor(vehicle.status), size: 30),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(vehicle.vehicleType, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text(vehicle.vehicleIdentity?.toString() ?? 'N/A', style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _getStatusColor(vehicle.status).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text((vehicle.status ?? 'Unknown').toUpperCase(), style: TextStyle(color: _getStatusColor(vehicle.status), fontWeight: FontWeight.bold)),
                  )
                ],
              ),

              const SizedBox(height: 16),

              // details list
              _truckDetailRow('Vehicle Type', vehicle.vehicleType),
              _truckDetailRow('Plate (Head)', vehicle.plateNumber.headPlate),
              _truckDetailRow('Trailer Plate', vehicle.plateNumber.trailerPlate),
              _truckDetailRow('Color', vehicle.vehicleColor),
              _truckDetailRow('Model Year', vehicle.vehicleModelYear),
              _truckDetailRow('Tank Capacity', formatNumber(vehicle.tankCapacity)),
              _truckDetailRow('Fuel Type', vehicle.fuelType),

              const SizedBox(height: 12),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.map),
                      label: const Text('View on Map'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.rectangleColor),
                      onPressed: () {
                        Navigator.of(context).pop();
                        Get.to(() => const GpsTrackingScreen());
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                      onPressed: () {
                        Navigator.of(context).pop();
                        Get.to(() => const CarRegistrationTemplate())!.then((_) => vehicleController.getAllVehicles());
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _truckDetailRow(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(flex: 4, child: Text(value?.toString() ?? 'N/A')),
        ],
      ),
    );
  }
}

class _ModernTruckCard extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onTap;
  final Color statusColor;
  final String Function(dynamic) formatNumber;

  const _ModernTruckCard({required this.vehicle, required this.onTap, required this.statusColor, required this.formatNumber});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Left avatar / icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.local_shipping, color: statusColor, size: 32),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(vehicle.vehicleType, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                        child: Text((vehicle.status ?? 'Unknown').toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(vehicle.vehicleIdentity?.toString() ?? 'N/A', style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.opacity, size: 14, color: Colors.grey.shade400),
                      const SizedBox(width: 6),
                      Text('Capacity ${formatNumber(vehicle.tankCapacity)} L', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),

            // Menu
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'map') {
                  Get.to(() => const GpsTrackingScreen());
                } else if (value == 'edit') {
                  //Get.to(() => const CarRegistrationTemplate())!.then((_) => vehicleController.getAllVehicles());
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'map', child: Text('View on Map')),
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
              ],
            )
          ],
        ),
      ),
    );
  }
}
