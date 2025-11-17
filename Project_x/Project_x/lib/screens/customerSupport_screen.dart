import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oil_connect/utils/colors.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  // ✅ Open WhatsApp Chat
  static void openWhatsApp() async {
    const phoneNumber = "+255624160679"; // ✅ Replace with actual WhatsApp number
    const message = "Hello! I need assistance. Please help me.";

    final uri = Uri.parse(
        "https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}");

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar(
        "Error",
        "Could not launch WhatsApp",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // ✅ Make a Normal Phone Call
  static void makePhoneCall() async {
    const phoneNumber = "+255624160679"; // ✅ Replace with actual phone number
    final uri = Uri.parse("tel:$phoneNumber");

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      Get.snackbar(
        "Error",
        "Could not make a call",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // ✅ Open Email Support
  static void openEmailSupport() async {
    const email = "support@oilconnect.com";
    const subject = "Support Request";
    const body = "Hello, I need assistance with:";

    final uri = Uri.parse(
        "mailto:$email?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}");

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      Get.snackbar(
        "Error",
        "Could not open email client",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppColors.rectangleColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: const Text(
          "Customer Support",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.rectangleColor, AppColors.rectangleColor.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Hero Section
                _buildHeroSection(context, isDarkMode, screenHeight),
                
                // Contact Methods Section
                _buildContactMethodsSection(context, isDarkMode),
                
                // FAQ Section
                _buildFAQSection(context, isDarkMode),
                
                // Additional Info Section
                _buildAdditionalInfoSection(context, isDarkMode),
                
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ Hero Section with animated support icon
  Widget _buildHeroSection(BuildContext context, bool isDarkMode, double screenHeight) {
    return Container(
      height: screenHeight * 0.25,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.rectangleColor,
            AppColors.rectangleColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Background decoration
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.support_agent_rounded,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "We're Here to Help!",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Get instant support through multiple channels",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Contact Methods Section
  Widget _buildContactMethodsSection(BuildContext context, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Contact Us",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          
          // WhatsApp Card
          _buildContactCard(
            context: context,
            isDarkMode: isDarkMode,
            icon: Icons.chat,
            iconColor: const Color(0xFF25D366),
            title: "WhatsApp Chat",
            subtitle: "Get instant help via WhatsApp",
            onTap: openWhatsApp,
            gradient: const LinearGradient(
              colors: [Color(0xFF25D366), Color(0xFF128C7E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Phone Call Card
          _buildContactCard(
            context: context,
            isDarkMode: isDarkMode,
            icon: Icons.phone,
            iconColor: Colors.blue,
            title: "Phone Support",
            subtitle: "Call us directly for assistance",
            onTap: makePhoneCall,
            gradient: const LinearGradient(
              colors: [Colors.blue, Colors.blueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Email Card
          _buildContactCard(
            context: context,
            isDarkMode: isDarkMode,
            icon: Icons.email,
            iconColor: Colors.orange,
            title: "Email Support",
            subtitle: "Send us a detailed message",
            onTap: openEmailSupport,
            gradient: const LinearGradient(
              colors: [Colors.orange, Colors.deepOrange],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ FAQ Section
  Widget _buildFAQSection(BuildContext context, bool isDarkMode) {
    final faqs = [
      {
        "question": "How do I place an order?",
        "answer": "Navigate to the orders section, select your fuel type, and follow the prompts to complete your order."
      },
      {
        "question": "What payment methods are accepted?",
        "answer": "We accept mobile money, bank transfers, and cash on delivery."
      },
      {
        "question": "How long does delivery take?",
        "answer": "Delivery typically takes 30-60 minutes depending on your location and traffic conditions."
      },
      {
        "question": "Can I track my order?",
        "answer": "Yes, you can track your order in real-time through the app's tracking feature."
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Frequently Asked Questions",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          
          ...faqs.map((faq) => _buildFAQCard(
            context: context,
            isDarkMode: isDarkMode,
            question: faq["question"]!,
            answer: faq["answer"]!,
          )),
        ],
      ),
    );
  }

  // ✅ Additional Info Section
  Widget _buildAdditionalInfoSection(BuildContext context, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[800] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              Icons.info_outline,
              size: 40,
              color: AppColors.rectangleColor,
            ),
            const SizedBox(height: 16),
            Text(
              "Support Hours",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Monday - Friday: 8:00 AM - 6:00 PM\nSaturday: 9:00 AM - 4:00 PM\nSunday: 10:00 AM - 2:00 PM",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.rectangleColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "Average response time: 2-5 minutes",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.rectangleColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Contact Card Widget
  Widget _buildContactCard({
    required BuildContext context,
    required bool isDarkMode,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required LinearGradient gradient,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[800] : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ FAQ Card Widget
  Widget _buildFAQCard({
    required BuildContext context,
    required bool isDarkMode,
    required String question,
    required String answer,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(
          question,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.grey[800],
          ),
        ),
        children: [
          Text(
            answer,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

