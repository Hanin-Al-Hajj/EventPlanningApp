import 'package:event_planner/models/vendor.dart';
import 'package:event_planner/screens/vendor_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:event_planner/constants/app_colors.dart';
import 'package:event_planner/screens/chosen_vendor_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:event_planner/services/api_service.dart';

class VendorsScreen extends StatefulWidget {
  final String eventId;
  const VendorsScreen({super.key, required this.eventId});

  @override
  State<VendorsScreen> createState() => _VendorsScreenState();
}

class _VendorsScreenState extends State<VendorsScreen> {
  List<Vendor> _allVendors = [];
  List<Vendor> _filteredVendors = [];
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  bool _isLoading = true;
  final Set<String> _togglingVendorIds = {};

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVendors() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getVendors(widget.eventId);
      final vendors = (data['vendors'] as List? ?? [])
          .map((v) => Vendor.fromJson(v))
          .toList();

      Set<String> favIds = {};
      try {
        final favData = await ApiService.getFavoriteVendors(widget.eventId);
        favIds = (favData['vendors'] as List? ?? [])
            .map((v) => v['id'].toString())
            .toSet();
      } catch (e) {
        debugPrint('Favorites failed (non-fatal): $e');
      }

      for (final vendor in vendors) {
        vendor.isFavorite = favIds.contains(vendor.id.toString());
      }

      setState(() {
        _allVendors = vendors;
        _filteredVendors = vendors;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading vendors: $e');
      setState(() => _isLoading = false);
    }
  }

  void _filterVendors() {
    setState(() {
      _filteredVendors = _allVendors.where((v) {
        final matchesCategory =
            _selectedCategory == 'All' ||
            v.category.toLowerCase() == _selectedCategory.toLowerCase();
        final matchesSearch = v.name.toLowerCase().contains(
          _searchController.text.toLowerCase(),
        );
        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  Future<void> _toggleFavorite(Vendor vendor) async {
    if (_togglingVendorIds.contains(vendor.id)) return;
    _togglingVendorIds.add(vendor.id);
    setState(() => vendor.isFavorite = !vendor.isFavorite);
    try {
      final result = await ApiService.toggleFavoriteVendor(
        widget.eventId,
        vendor.id,
      );
      setState(() => vendor.isFavorite = result['is_favorite'] == true);
    } catch (e) {
      setState(() => vendor.isFavorite = !vendor.isFavorite);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update favourite. Try again.'),
          ),
        );
      }
    } finally {
      _togglingVendorIds.remove(vendor.id);
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  ImageProvider _getVendorImage(String imageIcon) {
    if (imageIcon.isEmpty) return const AssetImage('assets/images/image.png');
    if (imageIcon.startsWith('http://') || imageIcon.startsWith('https://')) {
      return NetworkImage(imageIcon);
    }
    return NetworkImage('http://127.0.0.1:8000/$imageIcon');
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
                    onChanged: (_) => _filterVendors(),
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
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ChosenVendorScreen(eventId: widget.eventId),
                    ),
                  );
                  _loadVendors();
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
                SizedBox(
                  height: 60,
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
                          onTap: () {
                            setState(() => _selectedCategory = category);
                            _filterVendors();
                          },
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
                      );
                    },
                  ),
                ),
                Expanded(
                  child: _filteredVendors.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.search_off,
                                size: 64,
                                color: AppColors.coral,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No vendors found',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.coral,
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
                              return _buildVendorCard(
                                vendor,
                                key: ValueKey(
                                  '${vendor.id}_${vendor.isFavorite}',
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildVendorCard(Vendor vendor, {Key? key}) {
    return Card(
      key: key,
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
                Container(
                  width: 150,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: _getVendorImage(vendor.imageIcon),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vendor.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.burgundy,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        vendor.category,
                        style: const TextStyle(
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
                            style: const TextStyle(
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
                GestureDetector(
                  onTap: () => _toggleFavorite(vendor),
                  child: Icon(
                    vendor.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: AppColors.darkpink,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _actionButton(
                    label: 'View Details',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VendorDetailsScreen(
                          eventId: widget.eventId,
                          vendorId: vendor.id,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _actionButton(
                    label: 'Book Vendor',
                    onPressed: () => _launchURL(
                      'https://wa.me/961${vendor.phoneNumber.replaceAll(RegExp(r'[\s\-]'), '')}',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: AppColors.darkpink,
        side: const BorderSide(color: AppColors.darkpink),
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      child: Text(label),
    );
  }
}
