import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:oil_connect/backend/controllers/vehicleController.dart';
import 'package:oil_connect/screens/truck%20owner%20screens/truck%20registration/pages/success_screen.dart';
import 'package:oil_connect/utils/colors.dart';
import 'package:oil_connect/utils/constants.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class CarRegistrationTemplate extends StatefulWidget {
  const CarRegistrationTemplate({super.key});

  @override
  State<CarRegistrationTemplate> createState() => _CarRegistrationTemplateState();
}

class _CarRegistrationTemplateState extends State<CarRegistrationTemplate> {
  final VehicleController _controller = Get.put(VehicleController());
  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();

  // Form-related variables
  String? selectedVehicleType;
  String? selectedModelYear;
  String? selectedVehicleColor;
  final TextEditingController trailerPlateController = TextEditingController();
  final TextEditingController tankCapacityController = TextEditingController();
  
  int selectedCompartments = 1;
  List<TextEditingController> compartmentControllers = [TextEditingController()];
  List<FocusNode> compartmentFocusNodes = [FocusNode()];
  
  // Document upload state
  final List<File?> attachments = List<File?>.filled(4, null);
  final List<String> documentLabels = [
    "Registration Card",
    "Front Image",
    "Back Image",
    "Side Image",
  ];
  final Map<int, bool> expandedTiles = {};

  // Vehicle type options
  final List<String> vehicleTypes = [
    'Scania', 'Volvo', 'Mercedes-Benz', 'MAN', 'Renault Trucks', 'DAF', 'Iveco',
    'Freightliner', 'Kenworth', 'Peterbilt', 'Mack', 'International', 'Western Star', 'Ford Cargo',
    'Tata', 'Ashok Leyland', 'Hino', 'Isuzu', 'Fuso', 'Hyundai Xcient', 'UD Trucks', 'Dongfeng',
    'FAW', 'JAC Motors', 'Sinotruk', 'Shacman',
    'Tanker Truck', 'Flatbed Truck', 'Box Truck', 'Refrigerated Truck', 'Dump Truck',
    'Tipper Truck', 'Cement Mixer', 'Livestock Truck', 'Car Carrier', 'Low Loader', 'Container Truck',
    'Canter', 'Mini Truck', 'Trailer', 'Prime Mover', 'Heavy Duty Truck',
  ];

  // Model year options (last 50 years)
  late List<String> modelYears;

  // Vehicle color options
  final List<String> vehicleColors = [
    'White', 'Black', 'Red', 'Blue', 'Green', 'Yellow', 'Orange', 
    'Purple', 'Pink', 'Brown', 'Grey', 'Silver'
  ];

  // Compartment options
  final List<int> compartmentOptions = List.generate(15, (index) => index + 1);

  @override
  void initState() {
    super.initState();
    // Generate years from current year in descending order
    modelYears = List.generate(50, (index) => (DateTime.now().year - index).toString());
    // Initialize expanded tiles
    for (int i = 0; i < documentLabels.length; i++) {
      expandedTiles[i] = false;
    }
  }

  @override
  void dispose() {
    trailerPlateController.dispose();
    tankCapacityController.dispose();
    for (var controller in compartmentControllers) {
      controller.dispose();
    }
    for (var focusNode in compartmentFocusNodes) {
      focusNode.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  String formatNumber(String value) {
    if (value.isEmpty) return '';
    final formatter = NumberFormat.decimalPattern();
    return formatter.format(int.tryParse(value.replaceAll(',', '')) ?? 0);
  }

  void _updateCompartments(int count) {
    setState(() {
      while (selectedCompartments < count) {
        final controller = TextEditingController();
        final focusNode = FocusNode();
        compartmentControllers.add(controller);
        compartmentFocusNodes.add(focusNode);
        selectedCompartments++;
      }
      while (selectedCompartments > count) {
        selectedCompartments--;
        compartmentControllers.removeLast().dispose();
        compartmentFocusNodes.removeLast().dispose();
      }
    });
  }

  Future<void> _pickFile(int index) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
    );
    if (result != null) {
      final file = File(result.files.single.path!);
      final fileSize = await file.length();
      
      const maxFileSize = 1024 * 1024; // 1MB
      
      if (fileSize > maxFileSize) {
        Get.snackbar(
          "File Too Large",
          "File size is ${(fileSize / (1024 * 1024)).toStringAsFixed(2)}MB. Maximum allowed is 1MB.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }
      
      setState(() {
        attachments[index] = file;
        expandedTiles[index] = false; // Collapse after upload
      });
    }
  }

  void _removeFile(int index) {
    setState(() {
      attachments[index] = null;
    });
  }

  void _viewFile(File file) {
    OpenFile.open(file.path);
  }

  bool _validateForm() {
    if (selectedVehicleType == null || selectedVehicleType!.isEmpty) {
      Get.snackbar("Error", "Please select a vehicle type.",
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }

    if (selectedModelYear == null || selectedModelYear!.isEmpty) {
      Get.snackbar("Error", "Please select a model year.",
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }

    if (trailerPlateController.text.trim().isEmpty) {
      Get.snackbar("Error", "Trailer Plate Number is required.",
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }

    if (selectedVehicleColor == null || selectedVehicleColor!.isEmpty) {
      Get.snackbar("Error", "Please select a vehicle color.",
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }

    final tankCapText = tankCapacityController.text.replaceAll(',', '').trim();
    if (tankCapText.isEmpty) {
      Get.snackbar("Error", "Tank capacity is required.",
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }

    int? tankCapacity = int.tryParse(tankCapText);
    if (tankCapacity == null || tankCapacity <= 0) {
      Get.snackbar("Error", "Tank capacity must be a valid number.",
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }

    int totalCompartmentCapacity = 0;
    for (int i = 0; i < selectedCompartments; i++) {
      final compartmentText = compartmentControllers[i].text.replaceAll(',', '').trim();
      if (compartmentText.isEmpty) {
        Get.snackbar("Error", "Compartment ${i + 1} capacity is required.",
            backgroundColor: Colors.red, colorText: Colors.white);
        return false;
      }
      int? compartmentCapacity = int.tryParse(compartmentText);
      if (compartmentCapacity == null || compartmentCapacity <= 0) {
        Get.snackbar("Error", "Compartment ${i + 1} must be a valid number.",
            backgroundColor: Colors.red, colorText: Colors.white);
        return false;
      }
      totalCompartmentCapacity += compartmentCapacity;
    }

    if (totalCompartmentCapacity != tankCapacity) {
      Get.snackbar(
        "Validation Error",
        "Total compartment capacity ($totalCompartmentCapacity) must equal tank capacity ($tankCapacity).",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    if (attachments.any((file) => file == null)) {
      Get.snackbar("Error",
          "Please upload all required documents before submitting.",
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }

    return true;
  }

  void _cleanTankCapacityData() {
    tankCapacityController.text = tankCapacityController.text.replaceAll(',', '').trim();
    for (var controller in compartmentControllers) {
      controller.text = controller.text.replaceAll(',', '').trim();
    }
  }

  Future<void> _submitForm() async {
    if (!_validateForm()) return;

    _cleanTankCapacityData();
    _controller.isLoading(true);

    Map<String, dynamic> carData = {
      'vehicle_type': selectedVehicleType!,
      'model_year': selectedModelYear!,
      'trailer_plate_number': trailerPlateController.text.trim(),
      'truck_color': selectedVehicleColor!,
      'tank_capacity': tankCapacityController.text.trim(),
      'compartments': List.generate(selectedCompartments, (index) => {
        'compartment_number': index + 1,
        'capacity': compartmentControllers[index].text.trim(),
      }),
    };

    bool isSuccess = await _controller.submitRegistration(carData, attachments);

    _controller.isLoading(false);

    if (isSuccess) {
      Get.off(() => const SuccessScreen());
    } else {
      Get.snackbar(
        "Error",
        "Failed to submit the registration. Please try again.",
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
          : const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Get.back(),
        ),
        title: Text(
          AppConstants.truckRegistration.tr.capitalizeFirst!,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Vehicle Type Dropdown
                _buildSectionTitle("Vehicle Type", "Select your vehicle type"),
                const SizedBox(height: 12),
                _buildDropdown<String>(
                  value: selectedVehicleType,
                  items: vehicleTypes.map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  )).toList(),
                  hint: "Select vehicle type",
                  onChanged: (value) {
                    setState(() {
                      selectedVehicleType = value;
                    });
                  },
                ),
                const SizedBox(height: 24),

                // Model Year Dropdown
                _buildSectionTitle("Model Year", "Select the year your vehicle was manufactured"),
                const SizedBox(height: 12),
                _buildDropdown<String>(
                  value: selectedModelYear,
                  items: modelYears.map((year) => DropdownMenuItem(
                    value: year,
                    child: Text(year),
                  )).toList(),
                  hint: "Select model year",
                  onChanged: (value) {
                    setState(() {
                      selectedModelYear = value;
                    });
                  },
                ),
                const SizedBox(height: 24),

                // Plate Number TextField
                _buildSectionTitle("Plate Number", "Enter your vehicle plate number"),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: trailerPlateController,
                  label: "Trailer Plate Number",
                  hint: "Enter trailer plate number",
                  isRequired: true,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    UpperCaseTextFormatter(),
                    NoSpaceTextFormatter(),
                  ],
                ),
                const SizedBox(height: 24),

                // Vehicle Color Dropdown
                _buildSectionTitle("Vehicle Color", "Select your vehicle color"),
                const SizedBox(height: 12),
                _buildDropdown<String>(
                  value: selectedVehicleColor,
                  items: vehicleColors.map((color) => DropdownMenuItem(
                    value: color,
                    child: Text(color),
                  )).toList(),
                  hint: "Select vehicle color",
                  onChanged: (value) {
                    setState(() {
                      selectedVehicleColor = value;
                    });
                  },
                ),
                
                const SizedBox(height: 24),

                // Tank Capacity Section
                _buildSectionTitle("Tank Capacity", "Enter tank capacity and number of compartments"),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Tank Capacity TextField
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.7,
                      child: _buildTextField(
                        controller: tankCapacityController,
                        label: "Tank Capacity (L)",
                        hint: "Enter capacity",
                        isRequired: true,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          TextInputFormatter.withFunction((oldValue, newValue) {
                            final formatted = formatNumber(newValue.text);
                            return TextEditingValue(
                              text: formatted,
                              selection: TextSelection.collapsed(offset: formatted.length),
                            );
                          }),
                        ],
                        suffixText: "L",
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Compartments Dropdown
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.3 - 56,
                      child: _buildDropdown<int>(
                        value: selectedCompartments,
                        items: compartmentOptions.map((count) => DropdownMenuItem(
                          value: count,
                          child: Text("$count"),
                        )).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            _updateCompartments(value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                const Text("Enter capacities for each compartment (L):"),
                // Compartment Capacity Fields
                ...List.generate(selectedCompartments, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildTextField(
                      controller: compartmentControllers[index],
                      label: "Compartment ${index + 1} Capacity (Liters)",
                      hint: "Enter capacity",
                      isRequired: true,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        TextInputFormatter.withFunction((oldValue, newValue) {
                          final formatted = formatNumber(newValue.text);
                          return TextEditingValue(
                            text: formatted,
                            selection: TextSelection.collapsed(offset: formatted.length),
                          );
                        }),
                      ],
                      suffixText: "L",
                    ),
                  );
                }),
                const SizedBox(height: 24),

                // Document Upload Section
                _buildSectionTitle("Required Documents", "Upload the required documents for vehicle registration"),
                const SizedBox(height: 12),
                // File size limit info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.rectangleColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.rectangleColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: AppColors.rectangleColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Maximum file size: 1MB per document. Large files will be rejected.',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.rectangleColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Accordion-style document upload
                ...List.generate(documentLabels.length, (index) {
                  final hasFile = attachments[index] != null;
                  final documentIcons = [
                    Icons.description,
                    Icons.camera_alt,
                    Icons.camera_alt,
                    Icons.camera_alt,
                  ];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: hasFile
                          ? AppColors.rectangleColor.withOpacity(0.05)
                          : Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF2A2A2A)
                              : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: hasFile
                            ? AppColors.rectangleColor
                            : Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF3A3A3A)
                                : const Color(0xFFE1E5E9),
                        width: hasFile ? 2 : 1,
                      ),
                    ),
                    child: ExpansionTile(
                      initiallyExpanded: expandedTiles[index] ?? false,
                      onExpansionChanged: (expanded) {
                        setState(() {
                          expandedTiles[index] = expanded;
                        });
                      },
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: hasFile
                              ? AppColors.rectangleColor.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          documentIcons[index],
                          size: 20,
                          color: hasFile ? AppColors.rectangleColor : Colors.grey,
                        ),
                      ),
                      title: Text(
                        documentLabels[index],
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : const Color(0xFF1A1A1A),
                        ),
                      ),
                      subtitle: hasFile
                          ? Text(
                              attachments[index]!.path.split('/').last,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.rectangleColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            )
                          : null,
                      trailing: hasFile
                          ? Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.rectangleColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              ),
                            )
                          : null,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              if (hasFile) ...[
                                // File info and actions
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? const Color(0xFF1A1A1A)
                                        : const Color(0xFFF8F9FA),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? const Color(0xFF3A3A3A)
                                          : const Color(0xFFE1E5E9),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.attach_file,
                                        size: 20,
                                        color: AppColors.rectangleColor,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          attachments[index]!.path.split('/').last,
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Theme.of(context).brightness == Brightness.dark
                                                ? Colors.white
                                                : const Color(0xFF1A1A1A),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _viewFile(attachments[index]!),
                                        icon: const Icon(Icons.visibility, size: 18),
                                        label: const Text("View"),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.rectangleColor,
                                          side: BorderSide(color: AppColors.rectangleColor),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _removeFile(index),
                                        icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                        label: const Text("Delete", style: TextStyle(color: Colors.red)),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red,
                                          side: const BorderSide(color: Colors.red),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ] else ...[
                                // Upload button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _pickFile(index),
                                    icon: const Icon(Icons.cloud_upload, color: Colors.white),
                                    label: const Text(
                                      "Upload Document",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.rectangleColor,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 32),

                // Submit Button
                Obx(() {
                  if (_controller.isLoading.value) {
                    return Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.rectangleColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: AppColors.rectangleColor,
                                strokeWidth: 2,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Processing...',
                              style: GoogleFonts.inter(
                                color: AppColors.rectangleColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.rectangleColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Submit Registration',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.check, size: 20),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : const Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white70
                : const Color(0xFF666666),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
  required T? value,
  required List<DropdownMenuItem<T>> items,
  String? hint,
  required void Function(T?) onChanged,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  
  return Container(
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: value != null 
            ? AppColors.rectangleColor.withOpacity(0.5)
            : isDark ? const Color(0xFF404040) : const Color(0xFFE5E5E5),
        width: 1.2,
      ),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton2<T>(
        value: value,
        items: items,
        hint: hint != null ? Text(
          hint,
          style: GoogleFonts.inter(
            fontSize: 15,
            color: isDark ? Colors.white54 : const Color(0xFF888888),
          ),
        ) : null,
        onChanged: onChanged,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : const Color(0xFF1A1A1A),
        ),
        dropdownStyleData: DropdownStyleData(
          maxHeight: 300,
          width: MediaQuery.of(context).size.width * 0.9,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
            border: Border.all(
              color: isDark ? const Color(0xFF404040) : const Color(0xFFE5E5E5),
            ),
          ),
          offset: const Offset(0, -8),
          elevation: 4,
        ),
        iconStyleData: IconStyleData(
          icon: Icon(
            Icons.expand_more_rounded,
            color: AppColors.rectangleColor,
            size: 20,
          ),
          iconSize: 20,
        ),
        buttonStyleData: const ButtonStyleData(
          height: 50,
          padding: EdgeInsets.symmetric(horizontal: 16),
        ),
        menuItemStyleData: const MenuItemStyleData(
          height: 40,
          padding: EdgeInsets.symmetric(horizontal: 16),
        ),
        isExpanded: true,
      ),
    ),
  );
}

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool isRequired = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? suffixText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2A2A2A)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF3A3A3A)
              : const Color(0xFFE1E5E9),
        ),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        textCapitalization: textCapitalization,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : const Color(0xFF1A1A1A),
        ),
        decoration: InputDecoration(
          labelText: isRequired ? "$label *" : label,
          hintText: hint,
          suffixText: suffixText,
          suffixStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.rectangleColor,
          ),
          labelStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white70
                : const Color(0xFF666666),
          ),
          hintStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white60
                : const Color(0xFF999999),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class NoSpaceTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final newText = newValue.text.replaceAll(' ', '');
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
