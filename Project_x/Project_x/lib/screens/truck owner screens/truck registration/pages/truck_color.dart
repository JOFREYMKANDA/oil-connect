import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oil_connect/utils/colors.dart';

class ColorPage extends StatefulWidget {
  const ColorPage({super.key, required this.onColorSelected, this.isRequired = false});

  final Function onColorSelected;
  final bool isRequired; // Indicates if the field is required

  @override
  State<ColorPage> createState() => _ColorPageState();
}

class _ColorPageState extends State<ColorPage> {
  final TextEditingController colorController = TextEditingController();
  String? errorMessage;
  String? selectedColor;

  // Predefined color options
  final List<Map<String, dynamic>> colorOptions = [
    {'name': 'White', 'color': Colors.white, 'textColor': Colors.black},
    {'name': 'Black', 'color': Colors.black, 'textColor': Colors.white},
    {'name': 'Red', 'color': Colors.red, 'textColor': Colors.white},
    {'name': 'Blue', 'color': Colors.blue, 'textColor': Colors.white},
    {'name': 'Green', 'color': Colors.green, 'textColor': Colors.white},
    {'name': 'Yellow', 'color': Colors.yellow, 'textColor': Colors.black},
    {'name': 'Orange', 'color': Colors.orange, 'textColor': Colors.white},
    {'name': 'Purple', 'color': Colors.purple, 'textColor': Colors.white},
    {'name': 'Pink', 'color': Colors.pink, 'textColor': Colors.white},
    {'name': 'Brown', 'color': Colors.brown, 'textColor': Colors.white},
    {'name': 'Grey', 'color': Colors.grey, 'textColor': Colors.white},
    {'name': 'Silver', 'color': const Color(0xFFC0C0C0), 'textColor': Colors.black},
  ];

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
                'Vehicle Color',
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
                'Select your vehicle color or enter a custom color',
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
          const SizedBox(height: 32),

          // Custom Color Input
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF2A2A2A)
                  : const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF3A3A3A)
                    : const Color(0xFFE1E5E9),
                width: 1,
              ),
            ),
            child: TextField(
              controller: colorController,
              onChanged: (value) {
                setState(() {
                  errorMessage = null;
                  selectedColor = null;
                });
                widget.onColorSelected(value);
              },
              decoration: InputDecoration(
                hintText: 'Enter custom color (e.g., Metallic Blue)',
                hintStyle: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white60
                      : const Color(0xFF999999),
                ),
                prefixIcon: Icon(
                  Icons.palette,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white60
                      : const Color(0xFF666666),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorText: errorMessage,
              ),
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF1A1A1A),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Popular Colors Section
          Text(
            'Popular Colors',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 16),

          // Color Grid
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: colorOptions.length,
              itemBuilder: (context, index) {
                final colorOption = colorOptions[index];
                final isSelected = selectedColor == colorOption['name'];
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedColor = colorOption['name'];
                      colorController.text = colorOption['name'];
                    });
                    widget.onColorSelected(colorOption['name']);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: colorOption['color'],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.rectangleColor
                            : Colors.transparent,
                        width: isSelected ? 3 : 0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.rectangleColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Center(
                      child: Text(
                        colorOption['name'],
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: colorOption['textColor'],
                        ),
                        textAlign: TextAlign.center,
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
