import 'package:event_planner/db/vendor_storage.dart';
import 'package:event_planner/models/vendor.dart';
import 'package:event_planner/screens/vendor_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:event_planner/constants/app_colors.dart';
import 'package:event_planner/screens/chosen_vendor_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class VendorsScreen extends StatefulWidget {
  const VendorsScreen({super.key});

  @override
  State<VendorsScreen> createState() => _VendorsScreenState();
}

class _VendorsScreenState extends State<VendorsScreen> {
  List<Vendor> _allVendors = [];
  List<Vendor> _filteredVendors = [];
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  bool _isLoading = true;
  final List<String> _categories = [
    'All',
    'Catering',
    'Photography',
    'Decoration',
    'Venue',
    'Entertainment',
  ];
  @override
  void initState() {
    super.initState();
    _loadVendors();
  }

  Future<void> _loadVendors() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await seedSampleVendors();

      final vendors = await loadVendors();
      setState(() {
        _allVendors = vendors;
        _filteredVendors = vendors;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading vendors: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterVendors() {
    setState(() {
      _filteredVendors = _allVendors.where((vendor) {
        final matchesCategory =
            _selectedCategory == 'All' || vendor.category == _selectedCategory;
        final matchesSearch = vendor.name.toLowerCase().contains(
          _searchController.text.toLowerCase(),
        );
        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _filterVendors();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  String getVendorBackgroundImage(Vendor vendor) {
    switch (vendor.name) {
      case "THE FLOWER SHOP":
        return "assets/images/theflowershop.jpeg";
      case "Cremino":
        return "assets/images/cremino.jpeg";
      case "Aljawad Dining":
        return "assets/images/jawad.jpeg";
      case "Planto":
        return "assets/images/planto.jpeg";
      case "Lancaster Eden Bay":
        return "assets/images/lancaster.jpeg";
      default:
        return "assets/images/image.png";
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
                    child: Icon(
                      FontAwesomeIcons.arrowLeft,
                      color: AppColors.darkpink,
                      size: 20,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => _filterVendors(),
                    decoration: InputDecoration(
                      hintText: 'Search vendors...',
                      hintStyle: const TextStyle(color: AppColors.coral),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.coral,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(40),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChosenVendorScreen(
                        favoriteVendors: _allVendors
                            .where((v) => v.isFavorite)
                            .toList(),
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(22),
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Center(
                    child: Icon(
                      Icons.favorite,
                      color: AppColors.darkpink,
                      size: 30,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF586041)),
            )
          : Column(
              children: [
                //category tabs
                Container(
                  height: 60,
                  color: AppColors.cream,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = category == _selectedCategory;

                      return Padding(
                        padding: const EdgeInsets.only(
                          right: 8,
                          top: 8,
                          bottom: 8,
                        ),

                        child: GestureDetector(
                          onTap: () => _selectCategory(category),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.darkpink
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(40),
                            ),

                            child: Center(
                              child: Text(
                                category,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.darkpink,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                //vendor list
                Expanded(
                  child: _filteredVendors.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: AppColors.coral,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No vendors found',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.coral,
                                  // color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadVendors,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredVendors.length,
                            itemBuilder: (context, index) {
                              final vendor = _filteredVendors[index];
                              return _buildVendorCard(vendor);
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildVendorCard(Vendor vendor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                //icon of vendor
                Container(
                  width: 150,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: AssetImage(getVendorBackgroundImage(vendor)),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                //vendor info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              vendor.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.burgundy,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        vendor.category,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.burgundy,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            '${vendor.rating}',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.burgundy,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    vendor.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: AppColors.darkpink,
                  ),
                  onPressed: () async {
                    setState(() {
                      vendor.isFavorite = !vendor.isFavorite;
                    });
                    await updateVendor(vendor);
                  },
                ),
                SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              VendorDetailsScreen(vendor: vendor),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: AppColors.darkpink,
                      side: const BorderSide(color: AppColors.darkpink),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text('View Details'),
                  ),
                ),
                const SizedBox(width: 8), // space between buttons
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _launchURL(
                      'https://wa.me/961${vendor.phoneNumber.replaceAll(RegExp(r'[\s\-]'), '')}',
                    ),

                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: AppColors.darkpink,
                      side: const BorderSide(color: AppColors.darkpink),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text('Book Vendor'), // change label as needed
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
