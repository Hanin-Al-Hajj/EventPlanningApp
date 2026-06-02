import 'package:event_planner/models/vendor.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:event_planner/constants/app_colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class VendorDetailsScreen extends StatelessWidget {
  const VendorDetailsScreen({super.key, required this.vendor});
  final Vendor vendor;

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        toolbarHeight: 76,
        automaticallyImplyLeading: false,
        titleSpacing: 0,

        title: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
          child: Row(
            children: [
              InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(22),
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Center(
                    child: FaIcon(
                      FontAwesomeIcons.arrowLeft,
                      size: 20,
                      color: AppColors.darkpink,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              const Expanded(
                child: Text(
                  'Vendor Details',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.burgundy,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              // Invisible widget to balance the back button
              const SizedBox(width: 40, height: 40),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //discription la kil vendor
            if (vendor.description != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'About',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.burgundy,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      vendor.description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.burgundy,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            //contact info of vendor
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Contact Information',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.burgundy,
                    ),
                  ),
                  const SizedBox(height: 16),

                  //phone nb
                  if (vendor.phoneNumber.isNotEmpty)
                    _buildContactItem(
                      icon: FontAwesomeIcons.whatsapp,
                      label: 'Phone',
                      value: vendor.phoneNumber,
                      onTap: () => _launchURL(
                        'https://wa.me/961${vendor.phoneNumber.replaceAll(RegExp(r'[\s\-]'), '')}',
                      ),
                    ),

                  if (vendor.instagram != null)
                    _buildContactItem(
                      icon: FontAwesomeIcons.instagram,
                      label: 'Instagram',
                      value: vendor.instagram!,
                      onTap: () => _launchURL(
                        'https://instagram.com/${vendor.instagram!}',
                      ),
                    ),

                  //email
                  if (vendor.email != null)
                    _buildContactItem(
                      icon: FontAwesomeIcons.envelope,
                      label: 'Email',
                      value: vendor.email!,
                      onTap: () => _launchURL('mailto:${vendor.email!}'),
                    ),

                  //website
                  if (vendor.website != null)
                    _buildContactItem(
                      icon: FontAwesomeIcons.globe,
                      label: 'Website',
                      value: vendor.website!,
                      onTap: () => _launchURL(vendor.website!),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Locations',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: AppColors.burgundy,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...vendor.locations.map(
                    (location) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: AppColors.darkpink,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              location,
                              softWrap: true,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.burgundy,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: AppColors.coral,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: FaIcon(icon, color: AppColors.burgundy, size: 28),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 12, color: AppColors.burgundy),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.burgundy,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.burgundy,
            ),
          ],
        ),
      ),
    );
  }
}
