import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oil_connect/utils/colors.dart';
import 'package:flutter/services.dart';


class PlateNumberPage extends StatefulWidget {
  const PlateNumberPage({
    super.key,
    required this.headPlateController,
    required this.trailerPlateController,
    required this.specialPlateController,
  });

  final TextEditingController headPlateController;
  final TextEditingController trailerPlateController;
  final TextEditingController specialPlateController;

  @override
  State<PlateNumberPage> createState() => _PlateNumberPageState();
}

class _PlateNumberPageState extends State<PlateNumberPage> {
  final _headFocus = FocusNode();
  final _trailerFocus = FocusNode();
  final _specialFocus = FocusNode();

  @override
  void dispose() {
    _headFocus.dispose();
    _trailerFocus.dispose();
    _specialFocus.dispose();
    super.dispose();
  }

  Widget textFieldWidget({
    required BuildContext context,
    required String labelText,
    required TextEditingController controller,
    required String? Function(String?) validator,
    required FocusNode focusNode,
    required TextInputAction textInputAction,
    required void Function(String)? onFieldSubmitted,
    Function? onTap,
    bool readOnly = false,
  }) {
    return Container(
      width: Get.width,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: TextFormField(
        readOnly: readOnly,
        focusNode: focusNode,
        textInputAction: textInputAction,
        onFieldSubmitted: onFieldSubmitted,
        onTap: () => onTap?.call(),
        validator: validator,
        controller: controller,
        textCapitalization: TextCapitalization.characters,
        inputFormatters: [
          UpperCaseTextFormatter(),
          NoSpaceTextFormatter(),
        ],
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : const Color(0xff202124),
        ),
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: const Color(0xff7D7D7D),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: AppColors.rectangleColor,
              width: 1.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0x1FFFFFFF)
                  : AppColors.textFieldBorder,
              width: 1,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: AppColors.redColor,
              width: 1.5,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: AppColors.redColor,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
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
                'Plate Numbers',
                style: GoogleFonts.inter(
                  fontSize:28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : const Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your vehicle plate numbers',
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

          // Plate Number Input Fields
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Trailer Plate (Required)
                  _buildPlateField(
                    context: context,
                    label: 'Trailer Plate Number',
                    hint: 'Enter trailer plate number',
                    controller: widget.trailerPlateController,
                    focusNode: _trailerFocus,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_specialFocus),
                    isRequired: true,
                    icon: Icons.local_shipping,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlateField({
    required BuildContext context,
    required String label,
    required String hint,
    required TextEditingController controller,
    required FocusNode focusNode,
    required TextInputAction textInputAction,
    required void Function(String)? onFieldSubmitted,
    required bool isRequired,
    required IconData icon,
  })  {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2A2A2A)
            : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: focusNode.hasFocus
              ? AppColors.rectangleColor
              : Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF3A3A3A)
                  : const Color(0xFFE1E5E9),
          width: focusNode.hasFocus ? 2 : 1,
        ),
        boxShadow: focusNode.hasFocus
            ? [
                BoxShadow(
                  color: AppColors.rectangleColor.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label with Icon
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.rectangleColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: AppColors.rectangleColor,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : const Color(0xFF1A1A1A),
                  ),
                ),
                if (isRequired) ...[
                  const SizedBox(width: 4),
                  Text(
                    '*',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Text Field
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: TextFormField(
              controller: controller,
              focusNode: focusNode,
              textInputAction: textInputAction,
              onFieldSubmitted: onFieldSubmitted,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                UpperCaseTextFormatter(),
                NoSpaceTextFormatter(),
              ],
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF1A1A1A),
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white60
                      : const Color(0xFF999999),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
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
