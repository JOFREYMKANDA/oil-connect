import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:oil_connect/backend/controllers/customerController.dart';
import 'package:oil_connect/backend/controllers/orderController.dart';
import 'package:oil_connect/backend/controllers/sharedOrderController.dart';
import 'package:oil_connect/backend/models/station_model.dart';
import 'package:oil_connect/backend/models/order_model.dart';
import 'package:oil_connect/backend/services/orderServices.dart';
import 'package:oil_connect/backend/services/sharedRouteService.dart';
import 'package:oil_connect/utils/colors.dart';
import 'package:oil_connect/widget/AppBar.dart';
import 'package:oil_connect/priceFormula.dart';
import 'package:oil_connect/screens/customer%20screens/dashboard.dart';
import 'package:oil_connect/screens/customer%20screens/station_registration.dart';
import 'package:oil_connect/widget/bottom_navigation.dart'; 
   

class PlaceOrderScreen extends StatefulWidget {
  const PlaceOrderScreen({super.key});

  @override
  State<PlaceOrderScreen> createState() => _PlaceOrderScreenState();
}

class _PlaceOrderScreenState extends State<PlaceOrderScreen> {
  final CustomerController customerController = Get.put(CustomerController());
  final OrderController orderController = Get.put(OrderController());
  final SharedOrderController sharedOrderController = Get.put(SharedOrderController());
  final OrderService orderService = OrderService();
  final sharedOrderService = SharedOrderService();


  Station? selectedStation;
  String? selectedRouteType;
  String? selectedFuelType;
  String? selectedDepotName;
  String? selectedSourceName;
  String? selectedCompanyName;
  final TextEditingController volumeController = TextEditingController();
  DateTime? deliveryDate;
  double? calculatedPrice;
  bool isProcessing = false;
  bool isCalculatingPrice = false;
  
  // Custom dropdown states
  bool _isDepotDropdownExpanded = false;
  bool _isFuelTypeDropdownExpanded = false;
  bool _isRouteTypeDropdownExpanded = false;
  bool _isStationDropdownExpanded = false;
  bool _isDatePickerExpanded = false;
  
  // Company coordinates for price calculation
  double? companyLatitude;
  double? companyLongitude;

  // Custom message state
  final RxBool _showMessage = false.obs;
  final RxString _messageText = ''.obs;
  final RxBool _isSuccessMessage = false.obs;

  @override
  void initState() {
    super.initState();
    customerController.fetchDepots();
    customerController.fetchCustomerStations();
  }

  // Helper method to format numbers with commas
  String _formatNumber(dynamic number) {
    if (number == null) return "0";
    return NumberFormat("#,###").format(number);
  }

  // Helper method to format volume input with commas
  String _formatVolumeInput(String value) {
    if (value.isEmpty) return '';
    // Remove all non-digit characters
    String digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.isEmpty) return '';
    
    // Parse to int and format with commas
    int? number = int.tryParse(digitsOnly);
    if (number == null) return '';
    
    return NumberFormat("#,###").format(number);
  }

  // Show custom message
  void _showCustomMessage(String message, bool isSuccess) {
    _messageText.value = message;
    _isSuccessMessage.value = isSuccess;
    _showMessage.value = true;
    
    // Auto hide after 4 seconds
    Future.delayed(const Duration(seconds: 60), () {
      _showMessage.value = false;
    });
  }

  // Build custom message container
  Widget _buildMessageContainer() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isSuccessMessage.value 
            ? Colors.green
            : Colors.red,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isSuccessMessage.value 
              ? Colors.green
              : Colors.red,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           IconButton(
            icon: const Icon(Icons.close, size: 18),
            color: Colors.white,
            onPressed: () {
              _showMessage.value = false;
            },
          ),
          Text(
              _messageText.value,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
         
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BackAppBar(
        title: 'New order',
        actions: [
          TextButton(
            onPressed:  _placeOrder,
            child:const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add, // or any other icon you prefer
                  color: AppColors.primaryColor,
                ),
                SizedBox(width: 8), // spacing between icon and text
                Text(
                  'Place order',
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Custom Message Container
            Obx(() => _showMessage.value ? _buildMessageContainer() : const SizedBox.shrink()),
            
            // Station Selection Section
            _buildStationSelection(),
            const SizedBox(height: 30),

            // Route Type Selection
            _buildRouteTypeSelection(),
            const SizedBox(height: 30),

            // Fuel Type Selection
            _buildFuelTypeSelection(),
            const SizedBox(height: 30),

            // Depot Selection
            _buildDepotSelection(),
            const SizedBox(height: 30),

            // Volume Input
            _buildVolumeInput(),
            const SizedBox(height: 30),

            // Delivery Date
            _buildDeliveryDate(),
            const SizedBox(height: 30),

            // Price Display
            if (calculatedPrice != null) _buildPriceDisplay(),
            if (calculatedPrice != null) const SizedBox(height: 30),

            // Action Buttons
            // _buildActionButtons(),
            // const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStationSelection() {
    final List<String> stationOptions = customerController.customerStations
        .map((station) => '${station.stationName} - ${station.region}, ${station.district}')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Custom Dropdown for Station Selection
        Obx(() {
          return CustomDropdown(
            options: stationOptions,
            selectedValue: selectedStation != null 
                ? '${selectedStation!.label}(${selectedStation!.stationName}) - ${selectedStation!.region}, ${selectedStation!.district}'
                : null,
            isExpanded: _isStationDropdownExpanded,
            hintText: 'Select destination station',
            isLoading: customerController.isStationsLoading.value,
            onTap: () {
              setState(() {
                _isStationDropdownExpanded = !_isStationDropdownExpanded;
                // Close other dropdowns
                _closeAllDropdownsExcept('station');
              });
            },
            onOptionSelected: (value) {
              final index = stationOptions.indexOf(value);
              if (index != -1) {
                setState(() {
                  selectedStation = customerController.customerStations[index];
                  _isStationDropdownExpanded = false;
                });
                _calculatePrice();
              }
            },
            onClear: () {
              setState(() {
                selectedStation = null;
                calculatedPrice = null;
                _isStationDropdownExpanded = false;
              });
            },
          );
        }),
        
        // Show register station button if no stations available
        Obx(() {
          if (customerController.customerStations.isEmpty && 
              !customerController.isStationsLoading.value) {
            return Column(
              children: [
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Get.to(() => const StationRegistration());
                    },
                    icon: const Icon(Icons.add_business, color: Colors.white),
                    label: const Text(
                      "Register Station First",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.rectangleColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            );
          }
          return const SizedBox();
        }),
      ],
    );
  }

  Widget _buildRouteTypeSelection() {
    final List<Map<String, dynamic>> routeTypeOptions = [
      {
        'value': 'single',
        'label': 'Single Route',
        'description': 'Direct delivery to your station',
        'icon': Icons.directions,
      },
      {
        'value': 'shared', 
        'label': 'Shared Route',
        'description': 'Share delivery with other customers',
        'icon': Icons.share,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Custom Dropdown for Route Type
        CustomDropdownWithIcons(
          options: routeTypeOptions,
          selectedValue: selectedRouteType,
          isExpanded: _isRouteTypeDropdownExpanded,
          hintText: 'Select route type',
          onTap: () {
            setState(() {
              _isRouteTypeDropdownExpanded = !_isRouteTypeDropdownExpanded;
              // Close other dropdowns
              _closeAllDropdownsExcept('route');
            });
          },
          onOptionSelected: (value) {
            setState(() {
              selectedRouteType = value;
              _isRouteTypeDropdownExpanded = false;
            });
          },
          onClear: () {
            setState(() {
              selectedRouteType = null;
              _isRouteTypeDropdownExpanded = false;
            });
          },
        ),
      ],
    );
  }

  Widget _buildFuelTypeSelection() {
    final List<String> fuelTypes = ['Petrol', 'Diesel', 'Kerosene'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Custom Dropdown for Fuel Type
        CustomDropdown(
          options: fuelTypes,
          selectedValue: selectedFuelType,
          isExpanded: _isFuelTypeDropdownExpanded,
          hintText: 'Select fuel type',
          onTap: () {
            setState(() {
              _isFuelTypeDropdownExpanded = !_isFuelTypeDropdownExpanded;
              // Close other dropdowns
              _closeAllDropdownsExcept('fuel');
            });
          },
          onOptionSelected: (value) {
            setState(() {
              selectedFuelType = value;
              _isFuelTypeDropdownExpanded = false;
            });
            _calculatePrice();
          },
          onClear: () {
            setState(() {
              selectedFuelType = null;
              calculatedPrice = null;
              _isFuelTypeDropdownExpanded = false;
            });
          },
        ),
      ],
    );
  }

  Widget _buildDepotSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Obx(() {
          // Create a simple loading state check since isDepotsLoading doesn't exist
          final bool isLoading = customerController.depots.isEmpty && 
              customerController.customerStations.isNotEmpty;
          
          final depotOptions = customerController.depots.map((depot) => depot.depot).toList();
          
          return CustomDropdown(
            options: depotOptions,
            selectedValue: selectedDepotName,
            isExpanded: _isDepotDropdownExpanded,
            hintText: 'Select a depot',
            isLoading: isLoading,
            onTap: () {
              setState(() {
                _isDepotDropdownExpanded = !_isDepotDropdownExpanded;
                // Close other dropdowns
                _closeAllDropdownsExcept('depot');
              });
            },
            onOptionSelected: (value) {
              setState(() {
                selectedDepotName = value;
                _isDepotDropdownExpanded = false;
                // Reset company coordinates when depot changes
                companyLatitude = null;
                companyLongitude = null;
                calculatedPrice = null;
              });
              
              // Set default company coordinates from first company in first source
              final depot = customerController.depots.firstWhereOrNull((d) => d.depot == value);
              if (depot != null && depot.sources.isNotEmpty && depot.sources.first.companies.isNotEmpty) {
                final firstCompany = depot.sources.first.companies.first;
                setState(() {
                  companyLatitude = firstCompany.latitude;
                  companyLongitude = firstCompany.longitude;
                });
                _calculatePrice();
              }
                        },
            onClear: () {
              setState(() {
                selectedDepotName = null;
                companyLatitude = null;
                companyLongitude = null;
                calculatedPrice = null;
                _isDepotDropdownExpanded = false;
              });
            },
          );
        }),
      ],
    );
  }

  Widget _buildVolumeInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.grey[900] 
                :const Color(0xfffafafa),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xfff5f5f5)),
            
          ),
          child: TextField(
            controller: volumeController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Enter volume in liters',
              hintStyle: GoogleFonts.inter(
                color: Colors.grey.shade600,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
            onChanged: (value) {
              // Format the input with commas
              String formattedValue = _formatVolumeInput(value);
              if (formattedValue != value) {
                volumeController.value = TextEditingValue(
                  text: formattedValue,
                  selection: TextSelection.collapsed(offset: formattedValue.length),
                );
              }
             _calculatePrice();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryDate() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomDatePicker(
          selectedDate: deliveryDate,
          isExpanded: _isDatePickerExpanded,
          hintText: 'Select delivery date',
          onTap: () {
            setState(() {
              _isDatePickerExpanded = !_isDatePickerExpanded;
              // Close other dropdowns
              _closeAllDropdownsExcept('date');
            });
          },
          onDateSelected: (date) {
            setState(() {
              deliveryDate = date;
              _isDatePickerExpanded = false;
            });
          },
          onClear: () {
            setState(() {
              deliveryDate = null;
              _isDatePickerExpanded = false;
            });
          },
        ),
      ],
    );
  }

Widget _buildPriceDisplay() {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      color: const Color(0XFFFAFAFA),
      border: Border.all(
        color: const Color(0xfff5f5f5),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Text(
              isCalculatingPrice ? 'Calculating Order Summary...' : 'Order Summary',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textColor,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 20),
        
        if (isCalculatingPrice)
          Center(
            child: Column(
              children: [
                Text(
                  'Please wait while we calculate your order...',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 16),
                const CircularProgressIndicator(
                  color: AppColors.primaryColor,
                ),
              ],
            ),
          )
        else
          Column(
            children: [
              // Order Details
              _buildSummaryItem('Fuel Type', selectedFuelType ?? 'N/A'),
              _buildSummaryItem('Route Type', 
                  selectedRouteType == 'single' ? 'Single Route' : 'Shared Route'),
              _buildSummaryItem('Depot', selectedDepotName ?? 'N/A'),
              _buildSummaryItem('Station', 
                  '${selectedStation?.label ?? 'N/A'}(${selectedStation?.stationName ?? 'N/A'})'),
              _buildSummaryItem('Volume', 
                  '${_formatNumber(int.tryParse(volumeController.text.replaceAll(',', '')) ?? 0)} Liters'),
              
              if (selectedRouteType == 'single' && deliveryDate != null)
                _buildSummaryItem('Delivery Date', 
                    DateFormat('MMM dd, yyyy').format(deliveryDate!)),
              
              const SizedBox(height: 16),
              
              // Divider
              // Container(
              //   height: 1,
              //   color: Colors.grey.shade300,
              // ),
              
              const SizedBox(height: 16),
              
              // Total Price
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Estimated Price:',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black38,
                    ),
                  ),
                  Text(
                    'TZS ${_formatNumber(calculatedPrice!.toInt())}',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textColor,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // // Note
              // Text(
              //   '*This is an estimated price. Final price may vary based on actual market rates.',
              //   style: GoogleFonts.inter(
              //     fontSize: 12,
              //     color: Colors.grey.shade600,
              //     fontStyle: FontStyle.italic,
              //   ),
              // ),
            ],
          ),
      ],
    ),
  );
}

// Helper method to build summary items
Widget _buildSummaryItem(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.black38,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
 

  bool _canPlaceOrder() {
    return selectedStation != null &&
        selectedRouteType != null &&
        selectedFuelType != null &&
        selectedDepotName != null &&
        companyLatitude != null &&
        companyLongitude != null &&
        volumeController.text.isNotEmpty &&
        calculatedPrice != null &&
        (selectedRouteType == 'shared' || deliveryDate != null) &&
        !isProcessing &&
        !isCalculatingPrice;
  }

  void _closeAllDropdownsExcept(String currentDropdown) {
    setState(() {
      _isStationDropdownExpanded = currentDropdown == 'station';
      _isRouteTypeDropdownExpanded = currentDropdown == 'route';
      _isFuelTypeDropdownExpanded = currentDropdown == 'fuel';
      _isDepotDropdownExpanded = currentDropdown == 'depot';
      _isDatePickerExpanded = currentDropdown == 'date';
    });
  }

  Future<void> _calculatePrice() async {
    if (volumeController.text.isNotEmpty && 
        selectedFuelType != null && 
        selectedStation != null && 
        companyLatitude != null && 
        companyLongitude != null) {
      
      setState(() {
        isCalculatingPrice = true;
      });

      try {
        // Remove commas from volume input before parsing
        final volumeText = volumeController.text.replaceAll(',', '');
        final volume = double.tryParse(volumeText) ?? 0;
        
        // Get distance using Google Maps API
        final distance = await PriceCalculator.getDistanceFromGoogleMaps(
          selectedStation!.latitude,
          selectedStation!.longitude,
          companyLatitude!,
          companyLongitude!,
        );
        
        if (distance != null) {
          // Calculate price using the formula: ((distance - 21.8) / 6.3944) * capacity
          final price = PriceCalculator.calculatePrice(distance, volume);
          setState(() {
            calculatedPrice = price;
          });
        } else {
          // Fallback to simple calculation if distance calculation fails
          final basePrice = selectedFuelType == 'Petrol' ? 2500 : 
                           selectedFuelType == 'Diesel' ? 2400 : 2000;
          setState(() {
            calculatedPrice = volume * basePrice;
          });
        }
      } catch (e) {
        print("Error calculating price: $e");
        // Fallback to simple calculation
        final volumeText = volumeController.text.replaceAll(',', '');
        final volume = double.tryParse(volumeText) ?? 0;
        final basePrice = selectedFuelType == 'Petrol' ? 2500 : 
                         selectedFuelType == 'Diesel' ? 2400 : 2000;
        setState(() {
          calculatedPrice = volume * basePrice;
        });
      } finally {
        setState(() {
          isCalculatingPrice = false;
        });
      }
    } else {
      setState(() {
        calculatedPrice = null;
      });
    }  
  }

  Future<void> _placeOrder() async {
    if (!_canPlaceOrder()) {
      _showCustomMessage(
        'Please fill in all required fields before placing your order.',
        false
      );
      return;
    }

    setState(() {
      isProcessing = true;
    });

    try {
      // Get the selected depot and source information
      final selectedDepot = customerController.depots.firstWhereOrNull(
        (depot) => depot.depot == selectedDepotName,
      );

      if (selectedDepot == null) {
        throw Exception('Selected depot not found');
      }

      // Determine route type
      final isSharedRoute = selectedRouteType == 'shared';

      // Get the first source and company (since we're using the first one by default)
      final source = selectedDepot.sources.first;
      final company = source.companies.first;

      // Create the order object
      final order = Order(
        orderId: '', // Will be generated by backend
        orderIdGenerated: '',
        sharedGroupId: '',
        createdDate: DateTime.now(),
        fuelType: selectedFuelType!,
        routeWay: selectedRouteType == 'single' ? 'private' : 'shared',
        capacity: int.parse(volumeController.text.replaceAll(',', '')),
        deliveryTime: selectedRouteType == 'single' && deliveryDate != null
            ? deliveryDate!.toIso8601String()
            : '',
        source: source.name,
        stationName: selectedStation!.stationName,
        region: selectedStation!.region,
        depot: selectedDepotName!,
        companyName: company.name,
        price: calculatedPrice,
        distance: null, // Will be calculated by backend
        status: 'Pending',
        driverId: '',
        driverName: '',
        driverPhone: '',
        driverStatus: '',
        assignedOrder: '',
        vehicleId: '',
        customerFirstName: '',
        customerLastName: '',
        customerPhone: '',
        district: selectedStation!.district,
        depotLat: company.latitude,
        depotLng: company.longitude,
        stationLat: selectedStation!.latitude,
        stationLng: selectedStation!.longitude,
      );

      // Place the order// ✅ Use appropriate service based on route type
      final result = isSharedRoute
        ? await sharedOrderService.placeSharedOrder(order)
        : await orderService.placeOrder(order);

      setState(() {
        isProcessing = false;
      });

      if (result['success']) {
        _showCustomMessage(
          '🎉 Order Placed Successfully! Your order has been submitted and is being processed. You will receive updates soon.',
          true
        );

        // Navigate to customer dashboard after a short delay
        Future.delayed(const Duration(seconds: 2), () {
          Get.offAll(() => const RoleBasedBottomNavScreen(role: 'Customer'));
        });
      } else {
        String errorMessage = result['message'] ?? 'Failed to place order';
        if (result['suggestion'] != null) {
          errorMessage += '\n\nSuggestion: ${result['suggestion']}';
        }

        _showCustomMessage(errorMessage, false);
      }
    } catch (e) {
      setState(() {
        isProcessing = false;
      });

      _showCustomMessage(
        'Something went wrong while placing your order. Please try again.',
        false
      );
    }
  }
}

// Custom Dropdown Widget
class CustomDropdown extends StatelessWidget {
  final List<String> options;
  final String? selectedValue;
  final bool isExpanded;
  final String hintText;
  final bool isLoading;
  final VoidCallback onTap;
  final Function(String) onOptionSelected;
  final VoidCallback? onClear;

  const CustomDropdown({
    super.key,
    required this.options,
    required this.selectedValue,
    required this.isExpanded,
    required this.hintText,
    this.isLoading = false,
    required this.onTap,
    required this.onOptionSelected,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Input Field
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xfffafafa),
              border: Border.all(color: const Color(0xfff5f5f5)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: isLoading
                      ? Text(
                          'Loading...',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        )
                      : Text(
                          selectedValue ?? hintText,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: selectedValue == null 
                                ? Colors.grey.shade600 
                                : Theme.of(context).textTheme.bodyLarge?.color,
                            fontWeight: selectedValue == null 
                                ? FontWeight.normal 
                                : FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
                if (isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryColor,
                    ),
                  )
                
                else
                  Icon(
                    isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    color: Colors.grey.shade600,
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
        
        // Dropdown Options Container
        if (isExpanded && !isLoading) ...[
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(
              maxHeight: 200,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: options.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No options available',
                      style: GoogleFonts.inter(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  )
                : Scrollbar(
                    child: ListView(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      children: options.map((option) {
                        return _DropdownOptionItem(
                          option: option,
                          isSelected: option == selectedValue,
                          onTap: () => onOptionSelected(option),
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ],
    );
  }
}

// Custom Dropdown with Icons for Route Type
class CustomDropdownWithIcons extends StatelessWidget {
  final List<Map<String, dynamic>> options;
  final String? selectedValue;
  final bool isExpanded;
  final String hintText;
  final VoidCallback onTap;
  final Function(String) onOptionSelected;
  final VoidCallback? onClear;

  const CustomDropdownWithIcons({
    super.key,
    required this.options,
    required this.selectedValue,
    required this.isExpanded,
    required this.hintText,
    required this.onTap,
    required this.onOptionSelected,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final selectedOption = options.firstWhereOrNull(
      (option) => option['value'] == selectedValue
    );

    return Column(
      children: [
        // Input Field
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xfffafafa),
              border: Border.all(color: const Color(0xfff5f5f5)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: selectedOption != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedOption['label'],
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          hintText,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                ),
                
                  Icon(
                    isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    color: Colors.grey.shade600,
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
        
        // Dropdown Options Container
        if (isExpanded) ...[
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(
              maxHeight: 200,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Scrollbar(
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                children: options.map((option) {
                  return _DropdownOptionItemWithIcon(
                    option: option,
                    isSelected: option['value'] == selectedValue,
                    onTap: () => onOptionSelected(option['value']),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// Custom Date Picker with text buttons
class CustomDatePicker extends StatelessWidget {
  final DateTime? selectedDate;
  final bool isExpanded;
  final String hintText;
  final VoidCallback onTap;
  final Function(DateTime) onDateSelected;
  final VoidCallback? onClear;

  const CustomDatePicker({
    super.key,
    required this.selectedDate,
    required this.isExpanded,
    required this.hintText,
    required this.onTap,
    required this.onDateSelected,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Input Field
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xfffafafa),
              border: Border.all(color: const Color(0xfff5f5f5)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    selectedDate != null
                        ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                        : hintText,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: selectedDate == null 
                          ? Colors.grey.shade600 
                          : Theme.of(context).textTheme.bodyLarge?.color,
                      fontWeight: selectedDate == null 
                          ? FontWeight.normal 
                          : FontWeight.w500,
                    ),
                  ),
                ),
                
                  Icon(
                    isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    color: Colors.grey.shade600,
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
        
        // Date Picker Container
        if (isExpanded) ...[
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: _DatePickerContent(
              selectedDate: selectedDate,
              onDateSelected: onDateSelected,
            ),
          ),
        ],
      ],
    );
  }
}

class _DatePickerContent extends StatefulWidget {
  final DateTime? selectedDate;
  final Function(DateTime) onDateSelected;

  const _DatePickerContent({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  __DatePickerContentState createState() => __DatePickerContentState();
}

class __DatePickerContentState extends State<_DatePickerContent> {
  DateTime _currentDate = DateTime.now();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate;
    _currentDate = widget.selectedDate ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Month/Year Header
          _buildHeader(),
          const SizedBox(height: 16),
          
          // Days of Week
          _buildDaysOfWeek(),
          const SizedBox(height: 8),
          
          // Calendar Grid
          _buildCalendarGrid(),
          const SizedBox(height: 16),
          
          // Action Buttons (now as text buttons)
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () {
            setState(() {
              _currentDate = DateTime(_currentDate.year, _currentDate.month - 1);
            });
          },
          icon: const Icon(Icons.chevron_left),
        ),
        Text(
          DateFormat('MMMM yyyy').format(_currentDate),
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        IconButton(
          onPressed: () {
            setState(() {
              _currentDate = DateTime(_currentDate.year, _currentDate.month + 1);
            });
          },
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  Widget _buildDaysOfWeek() {
    const days = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
    return Row(
      children: days.map((day) {
        return Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              day,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_currentDate.year, _currentDate.month, 1);
    final lastDayOfMonth = DateTime(_currentDate.year, _currentDate.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final startingWeekday = firstDayOfMonth.weekday;

    List<Widget> dayWidgets = [];

    // Add empty cells for days before the first day of the month
    for (int i = 0; i < startingWeekday % 7; i++) {
      dayWidgets.add(const Expanded(child: SizedBox()));
    }

    // Add days of the month
    for (int day = 1; day <= daysInMonth; day++) {
      final currentDate = DateTime(_currentDate.year, _currentDate.month, day);
      final isSelected = _selectedDate != null &&
          _selectedDate!.year == currentDate.year &&
          _selectedDate!.month == currentDate.month &&
          _selectedDate!.day == currentDate.day;
      final isToday = currentDate.year == DateTime.now().year &&
          currentDate.month == DateTime.now().month &&
          currentDate.day == DateTime.now().day;

      dayWidgets.add(
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = currentDate;
              });
            },
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.rectangleColor : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: isToday && !isSelected
                    ? Border.all(color: AppColors.rectangleColor)
                    : null,
              ),
              child: Center(
                child: Text(
                  day.toString(),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: isSelected
                        ? Colors.white
                        : isToday
                            ? AppColors.rectangleColor
                            : Colors.black,
                    fontWeight: isSelected || isToday ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Create rows of 7 days each
    List<Widget> rows = [];
    for (int i = 0; i < dayWidgets.length; i += 7) {
      rows.add(
        Row(
          children: dayWidgets.sublist(i, i + 7 > dayWidgets.length ? dayWidgets.length : i + 7),
        ),
      );
    }

    return Column(
      children: rows,
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () {
            setState(() {
              _selectedDate = null;
            });
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey.shade600,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: Text(
            'Cancel',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: _selectedDate != null
              ? () {
                  widget.onDateSelected(_selectedDate!);
                }
              : null,
          style: TextButton.styleFrom(
            foregroundColor: _selectedDate != null 
                ? AppColors.rectangleColor 
                : Colors.grey.shade400,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: Text(
            'Ok',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _DropdownOptionItem extends StatelessWidget {
  final String option;
  final bool isSelected;
  final VoidCallback onTap;

  const _DropdownOptionItem({
    super.key,
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.rectangleColor.withOpacity(0.1)
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                option,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: isSelected 
                      ? AppColors.rectangleColor 
                      : Theme.of(context).textTheme.bodyLarge?.color,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check,
                size: 18,
                color: AppColors.rectangleColor,
              ),
          ],
        ),
      ),
    );
  }
}

class _DropdownOptionItemWithIcon extends StatelessWidget {
  final Map<String, dynamic> option;
  final bool isSelected;
  final VoidCallback onTap;

  const _DropdownOptionItemWithIcon({
    super.key,
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.rectangleColor.withOpacity(0.1)
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppColors.rectangleColor 
                    : AppColors.rectangleColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                option['icon'],
                color: isSelected 
                    ? Colors.white 
                    : AppColors.rectangleColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option['label'],
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: isSelected 
                          ? AppColors.rectangleColor 
                          : Theme.of(context).textTheme.bodyLarge?.color,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    option['description'],
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.rectangleColor,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}