import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:oil_connect/utils/colors.dart';

class TankCapacityPage extends StatefulWidget {
  const TankCapacityPage({
    super.key,
    required this.controller,
    required this.onCompartmentSelected,
  });

  final TextEditingController controller;
  final Function(int, List<TextEditingController>) onCompartmentSelected;

  @override
  State<TankCapacityPage> createState() => _TankCapacityPageState();

}

class _TankCapacityPageState extends State<TankCapacityPage> {
  int selectedCompartment = 1;
  List<TextEditingController> compartmentControllers = [TextEditingController()];
  List<FocusNode> compartmentFocusNodes = [FocusNode()];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Ensure parent always has up-to-date references to the controllers
    for (final c in compartmentControllers) {
      c.addListener(_notifyParentControllers);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyParentControllers();
    });
  }

  Widget _buildAllocationSummary() {
    final total = _totalTankCapacity;
    final allocated = _allocatedCapacity;
    final remaining = total - allocated;
    final isMatch = total > 0 && remaining == 0;
    final isOver = remaining < 0;
    Color color;
    if (isMatch) {
      color = Colors.green;
    } else if (isOver) {
      color = Colors.red;
    } else {
      color = AppColors.rectangleColor;
    }

    String status;
    if (total == 0 && allocated == 0) {
      status = 'Enter total capacity to begin';
    } else if (isMatch) {
      status = 'Perfect split';
    } else if (isOver) {
      status = 'Reduce by ${formatNumber((allocated - total).toString())} L';
    } else {
      status = 'Add ${formatNumber(remaining.toString())} L more';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2A2A2A)
            : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF3A3A3A)
              : const Color(0xFFE1E5E9),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.tune_rounded, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Allocated ${formatNumber(allocated.toString())} L of ${formatNumber(total.toString())} L • $status',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChips() {
    final presets = [2, 3, 4];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: presets.map((p) {
        final selected = selectedCompartment == p;
        return ChoiceChip(
          selected: selected,
          label: Text('Quick: $p compartments'),
          onSelected: (_) {
            final hadTotal = _totalTankCapacity > 0;
            _setCompartmentsCount(p);
            if (hadTotal) {
              _applyEqualSplit();
            }
          },
        );
      }).toList(),
    );
  }

  void _notifyParentControllers() {
    widget.onCompartmentSelected(selectedCompartment, compartmentControllers);
  }

  int _parseIntSafe(String value) {
    final cleaned = value.replaceAll(',', '').trim();
    return int.tryParse(cleaned) ?? 0;
  }

  int get _totalTankCapacity => _parseIntSafe(widget.controller.text);

  int get _allocatedCapacity {
    int sum = 0;
    for (final c in compartmentControllers) {
      sum += _parseIntSafe(c.text);
    }
    return sum;
  }

  void _setCompartmentsCount(int count) {
    if (count < 1) return;
    setState(() {
      while (selectedCompartment < count) {
        final controller = TextEditingController();
        controller.addListener(_notifyParentControllers);
        compartmentControllers.add(controller);
        compartmentFocusNodes.add(FocusNode());
        selectedCompartment++;
      }
      while (selectedCompartment > count) {
        selectedCompartment--;
        compartmentControllers.removeLast();
        compartmentFocusNodes.removeLast();
      }
    });
    _notifyParentControllers();
  }

  void _applyEqualSplit() {
    final total = _totalTankCapacity;
    if (total <= 0 || selectedCompartment <= 0) return;
    final base = total ~/ selectedCompartment;
    int remainder = total % selectedCompartment;
    for (int i = 0; i < selectedCompartment; i++) {
      final part = base + (remainder > 0 ? 1 : 0);
      if (remainder > 0) remainder--;
      final formatted = formatNumber(part.toString());
      compartmentControllers[i].text = formatted;
    }
    _notifyParentControllers();
    setState(() {});
  }

  @override
  void dispose() {
    for (var node in compartmentFocusNodes) {
      node.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }


  /// Formats input with commas while typing (for display purposes only)
  String formatNumber(String value) {
    if (value.isEmpty) return '';
    final formatter = NumberFormat.decimalPattern();
    return formatter.format(int.tryParse(value.replaceAll(',', '')) ?? 0);
  }

  /// Cleans the input data to remove commas for database submission
  void cleanInputData() {
    // Remove commas from the main tank capacity
    widget.controller.text = widget.controller.text.replaceAll(',', '').trim();

    // Remove commas from all compartment capacities
    for (var controller in compartmentControllers) {
      controller.text = controller.text.replaceAll(',', '').trim();
    }
  }

  /// Validates and cleans input before submission
  bool validateAndCleanTankCapacity() {
    cleanInputData(); // Ensure no commas in the data

    if (widget.controller.text.isEmpty) {
      Get.snackbar("Validation Error", "Tank capacity is required.",
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }

    for (int i = 0; i < selectedCompartment; i++) {
      if (compartmentControllers[i].text.isEmpty) {
        Get.snackbar("Validation Error",
            "Capacity for Compartment ${i + 1} is required.",
            backgroundColor: Colors.red, colorText: Colors.white);
        return false;
      }
    }

    return true;
  }

  /// Builds a text field with validation
  Widget buildTextField({
    required String labelText,
    required TextEditingController controller,
    required String? Function(String?) validator,
    FocusNode? focusNode,
    TextInputAction? textInputAction,
    Function(String)? onFieldSubmitted,
    bool readOnly = false,
    Function? onTap,
  }) {
    return Container(
      width: Get.width,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        textInputAction: textInputAction,
        onFieldSubmitted: onFieldSubmitted,
        readOnly: readOnly,
        onTap: () => onTap?.call(),
        validator: validator,
        //controller: controller,
        keyboardType: TextInputType.number, // Input is numbers only
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
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : const Color(0xff202124),
        ),
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: GoogleFonts.poppins(
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
                  ? const Color(0x1FFFFFFF) // ✅ White border in dark mode
                  : AppColors.textFieldBorder, // ✅ Gray border in light mode
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

  /// Builds compartment selector
  Widget buildCompartmentSelector() {

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ElevatedButton(
          onPressed: () {
            if (selectedCompartment > 1) {
              setState(() {
                selectedCompartment--;
                compartmentControllers.removeLast();
                compartmentFocusNodes.removeLast();
              });
              widget.onCompartmentSelected(selectedCompartment, compartmentControllers);
            }
          },

          child: const Icon(Icons.remove),
        ),
        Text(
          'Compartments: $selectedCompartment',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        ElevatedButton(
          onPressed: () {
            if (selectedCompartment < 15) {
              setState(() {
                selectedCompartment++;
                compartmentControllers.add(TextEditingController());
                compartmentFocusNodes.add(FocusNode());
              });
              widget.onCompartmentSelected(selectedCompartment, compartmentControllers);
            }
          },

          child: const Icon(Icons.add),
        ),
      ],
    );
  }

  /// Builds compartment fields dynamically
  Widget buildCompartmentFields() {
    return Column(
      children: List.generate(selectedCompartment, (index) {
        final isLast = index == selectedCompartment - 1;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: buildTextField(
            labelText: 'Enter capacity for Compartment ${index + 1}',
            controller: compartmentControllers[index],
            focusNode: compartmentFocusNodes[index],
            textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
            onFieldSubmitted: (_) {
              if (!isLast) {
                FocusScope.of(context).requestFocus(compartmentFocusNodes[index + 1]);
              } else {
                if (validateAndCleanTankCapacity()) {
                  print('All compartment values validated and cleaned');
                }
              }
            },
            validator: (input) {
              if (input == null || input.isEmpty) {
                return 'Capacity for Compartment ${index + 1} is required';
              }
              return null;
            },
          ),
        );
      }),
    );
  }


  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tank Capacity',
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
                'Enter your tank capacity and compartment details',
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

          // Tank Capacity Input
          _buildTankCapacityField(),
          const SizedBox(height: 12),
          _buildAllocationSummary(),
          const SizedBox(height: 32),

          // Compartment Section
          Text(
            'Compartments',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 16),

          // Compartment Selector
          _buildCompartmentSelector(),
          const SizedBox(height: 24),

          // Preset chips for quick setup
          _buildPresetChips(),
          const SizedBox(height: 16),

          // Compartment Fields
          _buildCompartmentFields(),
        ],
      ),
    );
  }

  Widget _buildTankCapacityField() {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    Icons.local_gas_station,
                    size: 20,
                    color: AppColors.rectangleColor,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Total Tank Capacity (Liters)',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : const Color(0xFF1A1A1A),
                  ),
                ),
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
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: TextField(
              controller: widget.controller,
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
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF1A1A1A),
              ),
              decoration: InputDecoration(
                hintText: 'Enter total tank capacity',
                hintStyle: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white60
                      : const Color(0xFF999999),
                ),
                suffixText: 'L',
                suffixStyle: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.rectangleColor,
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

  Widget _buildCompartmentSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2A2A2A)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF3A3A3A)
              : const Color(0xFFE1E5E9),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Decrease Button
          Container(
            decoration: BoxDecoration(
              color: selectedCompartment > 1
                  ? AppColors.rectangleColor.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: selectedCompartment > 1
                  ? () {
                      setState(() {
                        selectedCompartment--;
                        compartmentControllers.removeLast();
                        compartmentFocusNodes.removeLast();
                      });
                  _notifyParentControllers();
                    }
                  : null,
              icon: Icon(
                Icons.remove,
                color: selectedCompartment > 1
                    ? AppColors.rectangleColor
                    : Colors.grey,
              ),
            ),
          ),

          // Compartment Count
          Column(
            children: [
              Text(
                'Number of Compartments',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : const Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$selectedCompartment',
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.rectangleColor,
                ),
              ),
            ],
          ),

          const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildCompartmentFields() {
    return Column(
      children: List.generate(selectedCompartment, (index) {
        final isLast = index == selectedCompartment - 1;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                      child: Text(
                        '${index + 1}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.rectangleColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Compartment ${index + 1} Capacity',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : const Color(0xFF1A1A1A),
                      ),
                    ),
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
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  children: [
                    TextField(
                      controller: compartmentControllers[index],
                      focusNode: compartmentFocusNodes[index],
                      textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
                      onSubmitted: (_) {
                        if (!isLast) {
                          FocusScope.of(context).requestFocus(compartmentFocusNodes[index + 1]);
                        } else {
                          if (validateAndCleanTankCapacity()) {
                            // validated
                          }
                        }
                      },
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
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : const Color(0xFF1A1A1A),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter capacity for compartment ${index + 1}',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white60
                              : const Color(0xFF999999),
                        ),
                        suffixText: 'L',
                        suffixStyle: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.rectangleColor,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    if (isLast)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton.icon(
                              onPressed: _totalTankCapacity > 0 ? _applyEqualSplit : null,
                              icon: const Icon(Icons.grid_view_rounded, size: 18),
                              label: Text(
                                'Split equally',
                                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                              ),
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: selectedCompartment < 15
                                    ? AppColors.rectangleColor
                                    : Colors.grey,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: selectedCompartment < 15
                                  ? () {
                                      setState(() {
                                        selectedCompartment++;
                                        final controller = TextEditingController();
                                        controller.addListener(_notifyParentControllers);
                                        compartmentControllers.add(controller);
                                        compartmentFocusNodes.add(FocusNode());
                                      });
                                      _notifyParentControllers();
                                      WidgetsBinding.instance.addPostFrameCallback((_) {
                                        if (_scrollController.hasClients) {
                                          _scrollController.animateTo(
                                            _scrollController.position.maxScrollExtent + 120,
                                            duration: const Duration(milliseconds: 300),
                                            curve: Curves.easeOut,
                                          );
                                        }
                                        FocusScope.of(context).requestFocus(
                                          compartmentFocusNodes.last,
                                        );
                                      });
                                    }
                                  : null,
                              icon: const Icon(Icons.add, size: 18),
                              label: Text(
                                'Add',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
