import 'package:flutter/material.dart';
import 'package:oil_connect/utils/colors.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutUsScreen extends StatefulWidget {
  const AboutUsScreen({super.key});

  @override
  State<AboutUsScreen> createState() => _AboutUsScreenState();
}

class _AboutUsScreenState extends State<AboutUsScreen>
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
          "About Us",
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
                
                // Mission & Vision Section
                _buildMissionVisionSection(context, isDarkMode),
                
                // Company Values Section
                _buildValuesSection(context, isDarkMode),
                
                // Team Section
                _buildTeamSection(context, isDarkMode),
                
                // Contact & Social Section
                _buildContactSection(context, isDarkMode),
                
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Hero Section with company branding
  Widget _buildHeroSection(BuildContext context, bool isDarkMode, double screenHeight) {
    return Container(
      height: screenHeight * 0.35,
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
                    Icons.local_gas_station_rounded,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Oil Connect",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Connecting you to reliable fuel delivery",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "Since 2024",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Mission & Vision Section
  Widget _buildMissionVisionSection(BuildContext context, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildInfoCard(
            context: context,
            isDarkMode: isDarkMode,
            icon: Icons.flag_circle_outlined,
            iconColor: Colors.blue,
            title: "Our Mission",
            content: "To revolutionize fuel delivery by providing convenient, reliable, and eco-friendly solutions that connect customers with quality fuel services through innovative technology.",
            gradient: const LinearGradient(
              colors: [Colors.blue, Colors.blueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            context: context,
            isDarkMode: isDarkMode,
            icon: Icons.visibility_outlined,
            iconColor: Colors.purple,
            title: "Our Vision",
            content: "To become the leading fuel delivery platform in East Africa, transforming how people access fuel while promoting sustainable energy practices and supporting local communities.",
            gradient: const LinearGradient(
              colors: [Colors.purple, Colors.deepPurple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ],
      ),
    );
  }

  // Company Values Section
  Widget _buildValuesSection(BuildContext context, bool isDarkMode) {
    final values = [
      {
        "icon": Icons.verified_user_outlined,
        "title": "Reliability",
        "description": "Consistent and dependable service delivery",
        "color": Colors.green,
      },
      {
        "icon": Icons.eco_outlined,
        "title": "Sustainability",
        "description": "Committed to environmental responsibility",
        "color": Colors.teal,
      },
      {
        "icon": Icons.people_outline,
        "title": "Community",
        "description": "Supporting local communities and businesses",
        "color": Colors.orange,
      },
      {
        "icon": Icons.lightbulb_outline,
        "title": "Innovation",
        "description": "Embracing technology for better solutions",
        "color": Colors.indigo,
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Our Values",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemCount: values.length,
            itemBuilder: (context, index) {
              final value = values[index];
              return _buildValueCard(
                context: context,
                isDarkMode: isDarkMode,
                icon: value["icon"] as IconData,
                title: value["title"] as String,
                description: value["description"] as String,
                color: value["color"] as Color,
              );
            },
          ),
        ],
      ),
    );
  }

  // Team Section
  Widget _buildTeamSection(BuildContext context, bool isDarkMode) {
    final teamMembers = [
      {
        "name": "Eng Juma",
        "role": "CEO & Founder",
        "image": "assets/team1.jpg", // Placeholder
      },
      {
        "name": "Name",
        "role": "Role",
        "image": "assets/team2.jpg", // Placeholder
      },
      {
        "name": "Name",
        "role": "Role",
        "image": "assets/team3.jpg", // Placeholder
      },
      {
        "name": "Name",
        "role": "Role",
        "image": "assets/team4.jpg", // Placeholder
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Meet Our Team",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: teamMembers.length,
              itemBuilder: (context, index) {
                final member = teamMembers[index];
                return _buildTeamCard(
                  context: context,
                  isDarkMode: isDarkMode,
                  name: member["name"] as String,
                  role: member["role"] as String,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Contact & Social Section
  Widget _buildContactSection(BuildContext context, bool isDarkMode) {
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
              Icons.contact_mail_outlined,
              size: 40,
              color: AppColors.rectangleColor,
            ),
            const SizedBox(height: 16),
            Text(
              "Get In Touch",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            _buildContactInfo(
              context: context,
              isDarkMode: isDarkMode,
              icon: Icons.email_outlined,
              label: "Email",
              value: "office@aei.co.tz",
              onTap: () => _launchEmail("info@oilconnect.com"),
            ),
            const SizedBox(height: 12),
            _buildContactInfo(
              context: context,
              isDarkMode: isDarkMode,
              icon: Icons.phone_outlined,
              label: "Phone",
              value: "+255 759 221 066",
              onTap: () => _launchPhone("+255759221066"),
            ),
            const SizedBox(height: 12),
            _buildContactInfo(
              context: context,
              isDarkMode: isDarkMode,
              icon: Icons.location_on_outlined,
              label: "Address",
              value: "Dar es salaam, Tanzania",
              onTap: () => _launchMaps("Nairobi, Kenya"),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for info cards
  Widget _buildInfoCard({
    required BuildContext context,
    required bool isDarkMode,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
    required LinearGradient gradient,
  }) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.grey[800],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
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

  // Helper widget for value cards
  Widget _buildValueCard({
    required BuildContext context,
    required bool isDarkMode,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.grey[800],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Helper widget for team cards
  Widget _buildTeamCard({
    required BuildContext context,
    required bool isDarkMode,
    required String name,
    required String role,
  }) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.rectangleColor.withOpacity(0.1),
            child: Icon(
              Icons.person,
              size: 30,
              color: AppColors.rectangleColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.grey[800],
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            role,
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Helper widget for contact info
  Widget _buildContactInfo({
    required BuildContext context,
    required bool isDarkMode,
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[700] : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppColors.rectangleColor,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.white : Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods for launching external apps
  void _launchEmail(String email) async {
    final uri = Uri.parse("mailto:$email");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _launchPhone(String phone) async {
    final uri = Uri.parse("tel:$phone");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _launchMaps(String address) async {
    final uri = Uri.parse("https://maps.google.com/?q=$address");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
