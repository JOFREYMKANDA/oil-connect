import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_file/open_file.dart';
import 'package:oil_connect/utils/colors.dart';

class AttachmentPage extends StatefulWidget {
  final Function(List<File?>) onFilesSelected;

  const AttachmentPage({super.key, required this.onFilesSelected});

  @override
  State<AttachmentPage> createState() => _AttachmentPageState();
}

class _AttachmentPageState extends State<AttachmentPage> {
  final List<File?> _selectedFiles = [];
  final List<String> documentLabels = [
    "Registration Card",
    "Front Image",
    "Back Image",
    "Side Image",
  ];

  @override
  void initState() {
    super.initState();
    _selectedFiles.addAll(List<File?>.filled(documentLabels.length, null));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).unfocus();
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
      
      // Check file size (1MB = 1024 * 1024 bytes)
      // Using 1MB as the limit since nginx default is 1MB
      const maxFileSize = 1024 * 1024; // 1MB
      
      if (fileSize > maxFileSize) {
        _showFileSizeError(fileSize, maxFileSize);
        return;
      }
      setState(() {
        _selectedFiles[index] = file;
      });
      widget.onFilesSelected(_selectedFiles);
    }
  }

  void _showFileSizeError(int actualSize, int maxSize) {
    final actualSizeMB = (actualSize / (1024 * 1024)).toStringAsFixed(2);
    final maxSizeMB = (maxSize / (1024 * 1024)).toStringAsFixed(0);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'File Too Large',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'The selected file is too large to upload.',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'File Details:',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.red[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• File size: $actualSizeMB MB',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.red[700],
                      ),
                    ),
                    Text(
                      '• Maximum allowed: $maxSizeMB MB',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.red[700],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Please select a smaller file or compress the image before uploading.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF666666),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'OK',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.rectangleColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles[index] = null;
      widget.onFilesSelected(_selectedFiles);
    });
  }

  void _viewFile(File file) {
    OpenFile.open(file.path);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Required Documents',
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
                'Upload the required documents for vehicle registration',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : const Color(0xFF666666),
                ),
              ),

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
            ],
          ),
          const SizedBox(height: 32),

          // Document Upload Cards
          ...List.generate(documentLabels.length, (index) {
            final hasFile = _selectedFiles[index] != null;
            final documentIcons = [
              Icons.description,
              Icons.camera_alt,
              Icons.camera_alt,
              Icons.camera_alt,
            ];

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: hasFile
                    ? AppColors.rectangleColor.withOpacity(0.05)
                    : Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF2A2A2A)
                        : const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: hasFile
                      ? AppColors.rectangleColor
                      : Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF3A3A3A)
                          : const Color(0xFFE1E5E9),
                  width: hasFile ? 2 : 1,
                ),
                boxShadow: hasFile
                    ? [
                        BoxShadow(
                          color: AppColors.rectangleColor.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Document Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: hasFile
                                ? AppColors.rectangleColor.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            documentIcons[index],
                            size: 24,
                            color: hasFile
                                ? AppColors.rectangleColor
                                : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                documentLabels[index],
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white
                                      : const Color(0xFF1A1A1A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                hasFile
                                    ? 'Document uploaded successfully'
                                    : 'Required document',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: hasFile
                                      ? AppColors.rectangleColor
                                      : Theme.of(context).brightness == Brightness.dark
                                          ? Colors.white60
                                          : const Color(0xFF666666),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (hasFile)
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.rectangleColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                      ],
                    ),

                    if (hasFile) ...[
                      const SizedBox(height: 16),
                      // File Info
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF1A1A1A)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF3A3A3A)
                                : const Color(0xFFE1E5E9),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.attach_file,
                                  size: 20,
                                  color: AppColors.rectangleColor,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _selectedFiles[index]!.path.split('/').last,
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
                            const SizedBox(height: 8),
                            // File size info
                            FutureBuilder<int>(
                              future: _selectedFiles[index]!.length(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  final fileSize = snapshot.data!;
                                  final fileSizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(2);
                                  final isWithinLimit = fileSize <= 1024 * 1024; // 1MB limit
                                  
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isWithinLimit 
                                          ? Colors.green.withOpacity(0.1)
                                          : Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: isWithinLimit 
                                            ? Colors.green.withOpacity(0.3)
                                            : Colors.red.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isWithinLimit ? Icons.check_circle : Icons.warning,
                                          size: 14,
                                          color: isWithinLimit ? Colors.green : Colors.red,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$fileSizeMB MB',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: isWithinLimit ? Colors.green[700] : Colors.red[700],
                                          ),
                                        ),
                                        if (!isWithinLimit) ...[
                                          const SizedBox(width: 4),
                                          Text(
                                            '(Max: 1MB)',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w400,
                                              color: Colors.red[600],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Action Buttons
                    Row(
                      children: [
                        if (!hasFile) ...[
                          Expanded(
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.rectangleColor,
                                    AppColors.rectangleColor.withOpacity(0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ElevatedButton.icon(
                                onPressed: () => _pickFile(index),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.cloud_upload,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                label: Text(
                                  'Upload Document',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ] else ...[
                          Expanded(
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.rectangleColor),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ElevatedButton.icon(
                                onPressed: () => _viewFile(_selectedFiles[index]!),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: Icon(
                                  Icons.visibility,
                                  color: AppColors.rectangleColor,
                                  size: 20,
                                ),
                                label: Text(
                                  'View Document',
                                  style: GoogleFonts.inter(
                                    color: AppColors.rectangleColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            height: 48,
                            width: 48,
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              onPressed: () => _removeFile(index),
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
