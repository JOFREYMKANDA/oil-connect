import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oil_connect/backend/controllers/registerDriverController.dart';
import 'package:oil_connect/backend/models/driver_model.dart';
import 'package:oil_connect/screens/truck%20owner%20screens/driver%20registration/add_new_driver.dart';
import 'package:oil_connect/utils/colors.dart';
import 'package:url_launcher/url_launcher.dart';

class DriverInfoBottomSheet extends StatelessWidget {
  final Driver driver;

  const DriverInfoBottomSheet({super.key, required this.driver});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color baseBg = Theme.of(context).scaffoldBackgroundColor;
    final Color cardBg = Theme.of(context).cardColor;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              // Grab handle
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black54,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              const SizedBox(height: 12),

              // Header with gradient and avatar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.rectangleColor,
                      AppColors.rectangleColor.withOpacity(0.85),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white.withOpacity(0.15),
                        child: const Icon(
                          Icons.person,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${driver.firstname} ${driver.lastname}",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            _StatusPill(status: driver.status),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Contact shortcuts
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _ContactButton(
                        icon: Icons.call_rounded,
                        label: "Call",
                        onTap: () {
                          _launchPhone(context, driver.phoneNumber);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ContactButton(
                        icon: Icons.chat_rounded,
                        label: "Message",
                        onTap: () {
                          _launchSms(context, driver.phoneNumber);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ContactButton(
                        icon: Icons.email_rounded,
                        label: "Email",
                        onTap: () {
                          _launchEmail(context, driver.email);
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Info tiles
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white10 : const Color(0xFFE1E5E9),
                  ),
                ),
                child: Column(
                  children: [
                    _InfoTile(
                      icon: Icons.badge_rounded,
                      label: "License Number",
                      value: driver.licenseNumber ?? "N/A",
                    ),
                    const Divider(height: 16),
                    _InfoTile(
                      icon: Icons.calendar_month_rounded,
                      label: "License Expire Date",
                      value: driver.licenseExpireDate?.toString() ?? "N/A",
                    ),
                    const Divider(height: 16),
                    _InfoTile(
                      icon: Icons.phone_rounded,
                      label: "Phone",
                      value: driver.phoneNumber.isNotEmpty ? driver.phoneNumber : "N/A",
                    ),
                    const Divider(height: 16),
                    _InfoTile(
                      icon: Icons.email_rounded,
                      label: "Email",
                      value: driver.email.isNotEmpty ? driver.email : "N/A",
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Actions
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _PrimaryActionButton(
                        label: "Edit",
                        icon: Icons.edit_rounded,
                        backgroundColor: baseBg,
                        foregroundColor: isDark ? Colors.white : const Color(0xFF1A1A1A),
                        onTap: () {
                          Get.to(() => AddNewDriverScreen(isEditing: true, driver: driver));
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _PrimaryActionButton(
                        label: "Remove",
                        icon: Icons.delete_rounded,
                        backgroundColor: baseBg,
                        foregroundColor: AppColors.redColor,
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                backgroundColor: Theme.of(context).dialogBackgroundColor,
                                title: const Text("Confirm Delete"),
                                content: const Text("Are you sure you want to delete this driver?"),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text("Cancel"),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Get.find<DriverRegistrationController>().deleteDriver(driver.id);
                                      Navigator.of(context).pop();
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text("Delete"),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchPhone(BuildContext context, String number) async {
    final String sanitized = number.trim();
    if (sanitized.isEmpty) {
      _showSnack(context, 'No phone number available');
      return;
    }
    final Uri uri = Uri(scheme: 'tel', path: sanitized);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showSnack(context, 'Could not launch dialer');
    }
  }

  Future<void> _launchSms(BuildContext context, String number) async {
    final String sanitized = number.trim();
    if (sanitized.isEmpty) {
      _showSnack(context, 'No phone number available');
      return;
    }
    final Uri uri = Uri(scheme: 'sms', path: sanitized);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showSnack(context, 'Could not open messages');
    }
  }

  Future<void> _launchEmail(BuildContext context, String email) async {
    final String sanitized = email.trim();
    if (sanitized.isEmpty) {
      _showSnack(context, 'No email address available');
      return;
    }
    final Uri uri = Uri(
      scheme: 'mailto',
      path: sanitized,
      query: _encodeQuery(<String, String>{
        'subject': 'Oil Connect',
      }),
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showSnack(context, 'Could not open email app');
    }
  }

  String _encodeQuery(Map<String, String> params) {
    return params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill({required this.status});

  Color _bg(String s) {
    switch (s.toLowerCase()) {
      case 'available':
        return Colors.green.withOpacity(0.18);
      case 'busy':
        return Colors.red.withOpacity(0.18);
      case 'offline':
        return Colors.grey.withOpacity(0.18);
      default:
        return Colors.blue.withOpacity(0.18);
    }
  }

  Color _fg(String s) {
    switch (s.toLowerCase()) {
      case 'available':
        return Colors.white;
      case 'busy':
        return Colors.white;
      case 'offline':
        return Colors.white;
      default:
        return Colors.white;
    }
  }

  IconData _icon(String s) {
    switch (s.toLowerCase()) {
      case 'available':
        return Icons.check_circle_rounded;
      case 'busy':
        return Icons.schedule_rounded;
      case 'offline':
        return Icons.offline_bolt_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _bg(status),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.white.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon(status), size: 14, color: _fg(status)),
          const SizedBox(width: 6),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: _fg(status),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ContactButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE1E5E9)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: AppColors.rectangleColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final Color labelColor = Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.8) ?? Colors.grey;
    final Color valueColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.rectangleColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: labelColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color foregroundColor;

  const _PrimaryActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: foregroundColor.withOpacity(0.25),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: foregroundColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: foregroundColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
