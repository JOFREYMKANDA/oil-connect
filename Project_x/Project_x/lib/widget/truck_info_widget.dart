import 'package:flutter/material.dart';
import 'package:oil_connect/backend/models/truck_location_model.dart';
import 'package:oil_connect/utils/colors.dart';

class TruckInfoWidget extends StatelessWidget {
  final TruckLocation truck;

  const TruckInfoWidget({super.key, required this.truck});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: truck.status.toLowerCase() == 'busy' 
                      ? Colors.red 
                      : Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  truck.displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                truck.statusDisplay,
                style: TextStyle(
                  color: truck.status.toLowerCase() == 'busy' 
                      ? Colors.red 
                      : Colors.green,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          _buildInfoRow(
            Icons.local_shipping,
            'Vehicle Type',
            truck.vehicleType,
          ),
          
          _buildInfoRow(
            Icons.palette,
            'Color',
            truck.vehicleColor,
          ),
          
          if (truck.speed != null)
            _buildInfoRow(
              Icons.speed,
              'Speed',
              '${truck.speed!.round()} km/h',
            ),
          
          if (truck.lastUpdated != null)
            _buildInfoRow(
              Icons.access_time,
              'Last Update',
              _formatDateTime(truck.lastUpdated!),
            ),
          
          if (truck.driverName != null)
            _buildInfoRow(
              Icons.person,
              'Driver',
              truck.driverName!,
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.avatarPlaceholder),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
