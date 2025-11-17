import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oil_connect/utils/colors.dart';

class VehicalTypePage extends StatefulWidget {
  const VehicalTypePage({
    super.key,
    required this.onSelect,
    required this.selectedVehical,
  });

  final String selectedVehical;
  final Function(String) onSelect;

  @override
  State<VehicalTypePage> createState() => _VehicalTypePageState();
}

class _VehicalTypePageState extends State<VehicalTypePage> {
  final TextEditingController _controller = TextEditingController();

  final List<String> vehicleSuggestions = [
    'Scania', 'Volvo', 'Mercedes-Benz', 'MAN', 'Renault Trucks', 'DAF', 'Iveco',
    'Freightliner', 'Kenworth', 'Peterbilt', 'Mack', 'International', 'Western Star', 'Ford Cargo',
    'Tata', 'Ashok Leyland', 'Hino', 'Isuzu', 'Fuso', 'Hyundai Xcient', 'UD Trucks', 'Dongfeng',
    'FAW', 'JAC Motors', 'Sinotruk', 'Shacman',
    'Tanker Truck', 'Flatbed Truck', 'Box Truck', 'Refrigerated Truck', 'Dump Truck',
    'Tipper Truck', 'Cement Mixer', 'Livestock Truck', 'Car Carrier', 'Low Loader', 'Container Truck',
    'Canter', 'Mini Truck', 'Trailer', 'Prime Mover', 'Heavy Duty Truck',
  ];

  @override
  void initState() {
    super.initState();
    _controller.text = widget.selectedVehical;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vehicle Type',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : const Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select your vehicle type',
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
          const SizedBox(height: 16),

          // Vehicle Type Cards
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: vehicleSuggestions.length,
              itemBuilder: (context, index) {
                final vehicle = vehicleSuggestions[index];
                final isSelected = widget.selectedVehical == vehicle;
                
                return GestureDetector(
                  onTap: () {
                    _controller.text = vehicle;
                    widget.onSelect(vehicle);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.rectangleColor.withOpacity(0.1)
                          : Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF2A2A2A)
                              : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.rectangleColor
                            : Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF3A3A3A)
                                : const Color(0xFFE1E5E9),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.rectangleColor.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        vehicle,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected
                              ? AppColors.rectangleColor
                              : Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : const Color(0xFF1A1A1A),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
