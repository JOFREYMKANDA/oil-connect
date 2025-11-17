import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oil_connect/utils/colors.dart';

class ModelYearPage extends StatefulWidget {
  const ModelYearPage({super.key, required this.onSelect});

  final Function(int) onSelect;

  @override
  State<ModelYearPage> createState() => _ModelYearPageState();
}

class _ModelYearPageState extends State<ModelYearPage> {
  late List<int> years;
  late int selectedYear;

  @override
  void initState() {
    super.initState();
    // Generate years from the current year in descending order
    years = List.generate(50, (index) => DateTime.now().year - index);
    selectedYear = years[0]; // Default to the first year
  }

  void passDefaultYearIfNotSelected() {
    // Pass the selected year if it's still default
    widget.onSelect(selectedYear);
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
                'Model Year',
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
                'Select the year your vehicle was manufactured',
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

          // Selected Year Display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.rectangleColor.withOpacity(0.1),
                  AppColors.rectangleColor.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.rectangleColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Selected Year',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : const Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  selectedYear.toString(),
                  style: GoogleFonts.inter(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: AppColors.rectangleColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Year Picker
          Expanded(
            child: Container(
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CupertinoPicker.builder(
                  scrollController: FixedExtentScrollController(initialItem: 0),
                  childCount: years.length,
                  itemBuilder: (BuildContext context, int index) {
                    final year = years[index];
                    final isSelected = year == selectedYear;
                    
                    return Container(
                      height: 60,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.rectangleColor.withOpacity(0.1)
                            : Colors.transparent,
                      ),
                      child: Text(
                        year.toString(),
                        style: GoogleFonts.inter(
                          fontSize: isSelected ? 24 : 20,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? AppColors.rectangleColor
                              : Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : const Color(0xFF1A1A1A),
                        ),
                      ),
                    );
                  },
                  itemExtent: 60,
                  onSelectedItemChanged: (value) {
                    setState(() {
                      selectedYear = years[value];
                    });
                    widget.onSelect(selectedYear);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
