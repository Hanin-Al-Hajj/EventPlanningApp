import 'package:event_planner/constants/app_colors.dart';
import 'package:event_planner/db/vendor_storage.dart';
import 'package:event_planner/models/vendor.dart';
import 'package:event_planner/screens/vendor_details_screen.dart';
import 'package:flutter/material.dart';

class ChosenVendorScreen extends StatefulWidget {
  final List<Vendor> favoriteVendors;
  const ChosenVendorScreen({super.key, required this.favoriteVendors});

  @override
  State<ChosenVendorScreen> createState() => _ChosenVendorScreenState();
}

class _ChosenVendorScreenState extends State<ChosenVendorScreen> {
  late List<Vendor> _favorites;

  @override
  void initState() {
    super.initState();
    _favorites = List.from(widget.favoriteVendors);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back, color: AppColors.darkpink),
        ),
        title: Text(
          'My Favorites',
          style: TextStyle(
            color: AppColors.darkpink,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _favorites.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 30, color: AppColors.coral),
                  const SizedBox(height: 16),
                  Text(
                    'No favorite vendors yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.coral,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _favorites.length,
              itemBuilder: (context, index) {
                final vendor = _favorites[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadiusGeometry.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: IconButton(
                      icon: Icon(Icons.favorite, color: AppColors.darkpink),
                      onPressed: () async {
                        setState(() {
                          vendor.isFavorite = false;
                          _favorites.removeAt(index);
                        });
                        await updateVendor(vendor);
                      },
                    ),

                    title: Text(
                      vendor.name,
                      style: TextStyle(
                        color: AppColors.burgundy,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      vendor.category,
                      style: TextStyle(color: AppColors.burgundy),
                    ),
                    trailing: const Icon(
                      Icons.arrow_back_ios,
                      size: 16,
                      color: AppColors.burgundy,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              VendorDetailsScreen(vendor: vendor),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
