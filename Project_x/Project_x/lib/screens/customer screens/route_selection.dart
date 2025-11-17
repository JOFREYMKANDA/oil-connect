import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:dropdown_search/dropdown_search.dart'; // For searchable dropdown
import 'package:oil_connect/backend/controllers/customerController.dart';
import 'package:oil_connect/backend/controllers/sharedOrderController.dart';
import 'package:oil_connect/priceFormula.dart';
import 'package:oil_connect/utils/colors.dart';
import '../../backend/controllers/orderController.dart';
import '../../backend/models/order_model.dart';
import '../../backend/models/station_model.dart';
import 'package:intl/intl.dart';

class RouteSelectionSheet extends StatefulWidget {
  final Station station;
  final Order? existingOrder;

  const RouteSelectionSheet({super.key, required this.station,this.existingOrder,});

  @override
  State<RouteSelectionSheet> createState() => _RouteSelectionSheetState();
}

class _RouteSelectionSheetState extends State<RouteSelectionSheet> {
  String? selectedRouteType;
  String? selectedFuelType;
  String? selectedCombinedItem; // To store selected depot, source, and company
  String? selectedDepotName;
  String? selectedSourceName;
  String? selectedCompanyName;
  final TextEditingController volumeController = TextEditingController();
  DateTime? deliveryDate;
  double? calculatedPrice;
  Order? pendingOrder;
  bool showContinueButton = true;
  bool isProcessing = false; // Track loading state

  final CustomerController depotController = Get.put(CustomerController());
  final OrderController orderController = Get.put(OrderController());
  final SharedOrderController sharedOrderController = Get.put(SharedOrderController());

  @override
  void initState() {
    super.initState();
    depotController.fetchDepots().then((_) {
      if (widget.existingOrder != null) {
        final order = widget.existingOrder!;

        // Get depot after ensuring the list is fetched
        final depot = depotController.depots.firstWhereOrNull((d) => d.depot == order.depot);
        if (depot != null) {
          final source = depot.sources.firstWhereOrNull((s) => s.name == order.source);
          if (source != null) {
            final company = source.companies.firstWhereOrNull((c) => c.name == order.companyName);
            if (company != null) {
              setState(() {
                selectedRouteType = order.routeWay;
                selectedFuelType = order.fuelType;
                selectedDepotName = depot.depot;
                selectedSourceName = source.name;
                selectedCompanyName = company.name;
                volumeController.text = _formatNumber(order.capacity.toString());
                deliveryDate = order.deliveryTime.isNotEmpty
                    ? DateTime.tryParse(order.deliveryTime)
                    : null;
              });
            } else {
              _showError("Company not found for selected depot/source.");
            }
          } else {
            _showError("Source not found for selected depot.");
          }
        } else {
          _showError("Depot not found.");
        }
      }
    });
  }

  bool validateFields() {
    if (selectedDepotName == null ||
        selectedSourceName == null ||
        selectedCompanyName == null ||
        selectedFuelType == null ||
        volumeController.text.isEmpty) {
      _showError("Please fill all required fields.");
      return false;
    }

    if (selectedRouteType == "private" && deliveryDate == null) {
      _showError("Please select a delivery date for a single route.");
      return false;
    }

    return true;
  }
  /// handle shared route
  Future<void> _handleSharedRoute() async {
    if (!validateFields()) return;

    final Order? sharedOrder = await _calculatePriceAndSubmit(shared: true);

    if (sharedOrder != null && mounted) {
      Navigator.pop(context, sharedOrder); // ✅ Return to CustomerScreen with order
    }
  }

  /// If [shared] is true, returns the constructed shared order.
  /// If [shared] is false (private), it submits the order and returns null.
  Future<Order?> _calculatePriceAndSubmit({bool shared = false}) async {
    if (!validateFields()) {
      setState(() {
        showContinueButton = true;
      });
      return null;
    }

    final depot = depotController.depots.firstWhere((depot) => depot.depot == selectedDepotName);
    final source = depot.sources.firstWhere((source) => source.name == selectedSourceName);
    final company = source.companies.firstWhere((company) => company.name == selectedCompanyName);

    final stationLat = widget.station.latitude;
    final stationLng = widget.station.longitude;
    final companyLat = company.latitude;
    final companyLng = company.longitude;

    final distance = await PriceCalculator.getDistanceFromGoogleMaps(
      stationLat,
      stationLng,
      companyLat,
      companyLng,
    );

    if (distance != null) {

      final volume = double.tryParse(volumeController.text.replaceAll(',', '')) ?? 0.0;

      setState(() {
        calculatedPrice = PriceCalculator.calculatePrice(distance, volume);
      });

      // ✅ If shared route, return constructed order to pass back to CustomerScreen
      if (shared) {
        return Order(
          fuelType: selectedFuelType ?? '',
          routeWay: "shared",
          capacity: int.tryParse(volumeController.text.replaceAll(',', '')) ?? 0,
          source: selectedSourceName ?? '',
          region: widget.station.region,
          stationName: widget.station.stationName,
          depot: selectedDepotName ?? '',
          companyName: selectedCompanyName ?? '',
          price: calculatedPrice,
          distance: distance,
          status: "Pending",
          orderId: '',
          createdDate: null,
          orderIdGenerated: '',
          driverId: '',
          driverName: '',
          driverPhone: '',
          driverStatus: '',
          deliveryTime: '', assignedOrder: '', vehicleId: '', customerFirstName: '', customerLastName: '', customerPhone: '', district: '', sharedGroupId: '',
        );
      } else {
        _submitOrder(); // For private route, submit order and pop
        return null;
      }
    } else {
      _showError("Failed to calculate distance. Please try again.");
      return null;
    }
  }


  /// Submit the order
  void _submitOrder() async {
    if (selectedRouteType == null || calculatedPrice == null) {
      _showError("Please complete all fields before submitting the order.");
      return;
    }

    final order = Order(
      fuelType: selectedFuelType ?? '',
      routeWay: selectedRouteType ?? '',
      capacity: int.tryParse(volumeController.text.replaceAll(',', '')) ?? 0,
      deliveryTime: deliveryDate != null
          ? DateFormat('yyyy-MM-dd').format(deliveryDate!)
          : '',
      source: selectedSourceName ?? '',
      stationName: widget.station.stationName,
      depot: selectedDepotName ?? '',
      companyName: selectedCompanyName ?? '',
      price: calculatedPrice,
      distance: null,
      status: " ",
      orderId: '',
      createdDate: null,
      orderIdGenerated: '',
      driverId: '', driverName: '',
      driverPhone: '', driverStatus: '',
      region: '', assignedOrder: '',
      vehicleId: '', customerFirstName: '',
      customerLastName: '', customerPhone: '', district: '', sharedGroupId: '',

    );
    Navigator.pop(context, order); // Pass the order back to CustomerScreen
  }

  void _showError(String message) {
    Get.snackbar(
      "Error",
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
    setState(() {
      showContinueButton = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select Route Type",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildRouteTypeSelection(),
            if (selectedRouteType == "private") _buildDeliveryDateSelection(),
            if (selectedRouteType != null) ...[
              _buildFuelSelection(),
              const SizedBox(height: 1),
              _buildVolumeInput(),
              const SizedBox(height: 1),
              _buildCombinedDropdown(),
            ],
            const SizedBox(height: 8),
            _buildContinueButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteTypeSelection() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[900] // Dark mode background
            : Colors.grey[100], // Light mode background
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0x1FFFFFFF) // Dark mode border
              : Colors.grey[300]!, // Light mode border
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Route Type",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color, // Dynamic text color
            ),
          ),
          const SizedBox(height: 8),

          RadioListTile<String>(
            value: "shared",
            groupValue: selectedRouteType,
            activeColor: Theme.of(context).primaryColor, // Primary color based on theme
            title: Text(
              "Shared Route",
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color, // Adaptive text color
              ),
            ),
            onChanged: (value) {
              setState(() {
                selectedRouteType = value;
                resetSelections();
              });
            },
          ),

          RadioListTile<String>(
            value: "private",
            groupValue: selectedRouteType,
            activeColor: Theme.of(context).primaryColor, // Primary color based on theme
            title: Text(
              "Single Route",
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color, // Adaptive text color
              ),
            ),
            onChanged: (value) {
              setState(() {
                selectedRouteType = value;
                resetSelections();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryDateSelection() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[900] // Dark mode background
            : Colors.grey[100], // Light mode background
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0x1FFFFFFF) // Dark mode border
              : Colors.grey[300]!, // Light mode border
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Delivery Date",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color, // Adaptive text color
            ),
          ),
          const SizedBox(height: 8),

          GestureDetector(
            onTap: () async {
              final DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      primaryColor: Theme.of(context).primaryColor, // Themed color
                      colorScheme: ColorScheme.light(
                        primary: Theme.of(context).primaryColor, // Themed highlight
                      ),
                    ),
                    child: child!,
                  );
                },
              );

              // ✅ Auto-update the selected date without using Navigator.pop
              if (pickedDate != null && mounted) {
                setState(() {
                  deliveryDate = pickedDate;
                  showContinueButton = false;
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800] // Dark mode field background
                    : Colors.white, // Light mode field background
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0x1FFFFFFF) // Dark mode border
                      : Colors.grey[300]!, // Light mode border
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    deliveryDate != null
                        ? "${deliveryDate!.toLocal()}".split(' ')[0] // ✅ Only show Date
                        : "Select Delivery Date",
                    style: TextStyle(
                      fontSize: 16,
                      color: deliveryDate != null
                          ? Theme.of(context).textTheme.bodyLarge?.color // Normal text color
                          : Colors.red, // Red text if not selected
                    ),
                  ),
                  Icon(
                    Icons.calendar_today,
                    color: Theme.of(context).primaryColor, // Themed icon color
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCombinedDropdown() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[900] // Dark mode background
            : Colors.grey[100], // Light mode background
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0x1FFFFFFF) // Dark mode border
              : Colors.grey[300]!, // Light mode border
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Depot",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color, // Adaptive text color
            ),
          ),
          const SizedBox(height: 8),

          Obx(() {
            if (depotController.isLoading.value) {
              return Center(child: CircularProgressIndicator(color: Colors.green.shade900,));
            }
            if (depotController.depots.isEmpty) {
              return const Text("No depots available.");
            }

            List<String> dropdownItems = [];
            Map<String, dynamic> mapping = {};

            for (var depot in depotController.depots) {
              for (var source in depot.sources) {
                for (var company in source.companies) {
                  String item = "${company.name}, ${source.name}, ${depot.depot}";
                  dropdownItems.add(item);
                  mapping[item] = {
                    "depot": depot.depot,
                    "source": source.name,
                    "company": company.name,
                  };
                }
              }
            }

            return DropdownSearch<String>(
              items: dropdownItems,
              selectedItem: selectedDepotName != null &&
                  selectedSourceName != null &&
                  selectedCompanyName != null
                  ? "$selectedDepotName, $selectedSourceName, $selectedCompanyName"
                  : null,
              popupProps: const PopupProps.dialog(
                showSearchBox: true,
                searchFieldProps: TextFieldProps(
                  decoration: InputDecoration(
                    labelText: "Search Depot",
                  ),
                ),
              ),
              dropdownDecoratorProps: DropDownDecoratorProps(
                dropdownSearchDecoration: InputDecoration(
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[800] // Dark mode input field background
                      : Colors.white, // Light mode input field background
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0x1FFFFFFF) // Dark mode border
                          : Colors.grey[300]!, // Green if selected
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  hintText: "Select Depot",
                  hintStyle: TextStyle(
                    color: selectedDepotName == null ? Colors.red : Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ),
                onChanged: (value) {
                  if (value != null && mapping.containsKey(value)) {
                    setState(() {
                      selectedDepotName = mapping[value]["depot"] ?? '';
                      selectedSourceName = mapping[value]["source"] ?? '';
                      selectedCompanyName = mapping[value]["company"] ?? '';
                    });
                  } else {
                    _showError("Invalid selection. Please try again.");
                  }
                }
            );
          }),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isProcessing
            ? null // Disable button when processing
            : () async {
          if (selectedRouteType == null) {
            _showError("Please select a route type.");
            return;
          }

          if (!validateFields()) {
            return;
          }

          setState(() {
            showContinueButton = false; // Hide button
            isProcessing = true; // Show progress indicator
          });

          // ✅ Step 2: Handle shared or single order
          if (selectedRouteType == "shared") {
            await _handleSharedRoute(); // New shared route logic
          } else {
            await _calculatePriceAndSubmit(); // Existing single route logic
          }

          // ✅ Hide progress indicator after process
          if (mounted) {
            setState(() {
              isProcessing = false;
            });
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.rectangleColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: isProcessing
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.green.shade900, // ✅ Green progress indicator on white button
                  strokeWidth: 3,
                ),
            )
            : const Text("Continue", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildFuelSelection() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[900] // Dark mode background
            : Colors.grey[100], // Light mode background
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0x1FFFFFFF) // Dark mode border
              : Colors.grey[300]!, // Light mode border
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Fuel Type",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color, // Adaptive text color
            ),
          ),
          const SizedBox(height: 8),

          DropdownButtonFormField<String>(
            initialValue: selectedFuelType,
            isExpanded: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[800]
                  : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.transparent),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0x1FFFFFFF)
                      : Colors.grey[300]!,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              hintText: "Select Fuel Type",
              hintStyle: TextStyle(
                color: selectedFuelType == null ? Colors.red : Theme.of(context).textTheme.bodyMedium?.color,
                fontWeight: FontWeight.w500,
              ),
            ),
            dropdownColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[850]
                : Colors.white,
            items: ["Diesel", "Petrol", "Kerosine"].map((type) => DropdownMenuItem(
              value: type,
              child: Text(
                type,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            )).toList(),
            onChanged: (value) {
              setState(() {
                selectedFuelType = value;
                showContinueButton = false;
              });
            },
          )
        ],
      ),
    );
  }

  Widget _buildVolumeInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[900] // Dark mode background
            : Colors.grey[100], // Light mode background
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0x1FFFFFFF) // Dark mode border
              : Colors.grey[300]!, // Light mode border
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Volume (Liters)",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color, // Adaptive text color
            ),
          ),
          const SizedBox(height: 8),

          TextFormField(
            controller: volumeController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly, // ✅ Allow only numbers
            ],
            decoration: InputDecoration(
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[800] // Dark mode input field background
                  : Colors.white, // Light mode input field background
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.transparent), // Transparent border
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0x1FFFFFFF) // Dark mode border
                      : Colors.grey[300]!, // Light mode border
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              hintText: "Enter Volume",
              hintStyle: const TextStyle(color: Colors.red), // Red hint text if empty
            ),
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color, // Adaptive text color
            ),
            onChanged: (value) {
              setState(() {
                showContinueButton = false;

                // ✅ Format the displayed text with commas
                String rawValue = value.replaceAll(',', ''); // Remove commas
                if (rawValue.isNotEmpty) {
                  volumeController.text = _formatNumber(rawValue);
                  volumeController.selection = TextSelection.fromPosition(
                    TextPosition(offset: volumeController.text.length),
                  );
                }
              });
            },
          ),
        ],
      ),
    );
  }

// ✅ Function to format numbers with commas for display
  String _formatNumber(String value) {
    final number = int.tryParse(value) ?? 0;
    return NumberFormat("#,###").format(number);
  }

// ✅ Function to get raw value without commas before sending to the database
  String getRawVolume() {
    return volumeController.text.replaceAll(',', '');
  }

  void resetSelections() {
    setState(() {
      selectedDepotName = null;
      selectedSourceName = null;
      selectedCompanyName = null;
      deliveryDate = null;
      showContinueButton = false;
    });
  }
}
