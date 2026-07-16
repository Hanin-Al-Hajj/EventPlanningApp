import 'dart:async';

import 'package:event_planner/models/vendor.dart';
import 'package:event_planner/repositories/vendor_repository.dart';
import 'package:event_planner/screens/vendor_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:event_planner/constants/app_colors.dart';
import 'package:event_planner/screens/chosen_vendor_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
  String? _errorMessage;
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
    VendorRepository.changes.addListener(_onVendorCacheChanged);

    if (VendorRepository.hasCache(widget.eventId)) {
      _applyVendors(VendorRepository.cachedFor(widget.eventId).vendors);
      _isLoading = false;
      unawaited(VendorRepository.refreshInBackground(widget.eventId));
    } else {
      unawaited(_loadVendors());
    }
  }

  @override
  void didUpdateWidget(VendorsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.eventId == widget.eventId) return;

    if (VendorRepository.hasCache(widget.eventId)) {
      setState(() {
        _applyVendors(VendorRepository.cachedFor(widget.eventId).vendors);
        _isLoading = false;
        _errorMessage = null;
      });
      unawaited(VendorRepository.refreshInBackground(widget.eventId));
    } else {
      setState(() {
        _allVendors = [];
        _filteredVendors = [];
        _isLoading = true;
        _errorMessage = null;
      });
      unawaited(_loadVendors());
    }
  }

  @override
  void dispose() {
    VendorRepository.changes.removeListener(_onVendorCacheChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onVendorCacheChanged() {
    if (!mounted || !VendorRepository.hasCache(widget.eventId)) return;

    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _applyRepositoryCache();
      });
      return;
    }

    _applyRepositoryCache();
  }

  void _applyRepositoryCache() {
    if (!mounted || !VendorRepository.hasCache(widget.eventId)) return;

    setState(() {
      _applyVendors(VendorRepository.cachedFor(widget.eventId).vendors);
      _isLoading = false;
      _errorMessage = null;
    });
  }

  Future<void> _loadVendors({bool forceRefresh = false}) async {
    final hadCache = VendorRepository.hasCache(widget.eventId);

    if (!hadCache && mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final cache = await VendorRepository.load(
        widget.eventId,
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;

      setState(() {
        _applyVendors(cache.vendors);
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      debugPrint('Error loading vendors: $e');
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = hadCache ? null : 'Could not load vendors';
      });
    }
  }

  void _applyVendors(List<Vendor> vendors) {
    _allVendors = List<Vendor>.from(vendors);
    _filteredVendors = _matchingVendors();
  }

  List<Vendor> _matchingVendors() {
    final query = _searchController.text.trim().toLowerCase();

    return _allVendors.where((vendor) {
      final matchesCategory =
          _selectedCategory == 'All' ||
          vendor.category.toLowerCase() == _selectedCategory.toLowerCase();
      final matchesSearch =
          query.isEmpty || vendor.name.toLowerCase().contains(query);

      return matchesCategory && matchesSearch;
    }).toList();
  }

  void _filterVendors() {
    setState(() {
      _filteredVendors = _matchingVendors();
    });
  }

  Future<void> _toggleFavorite(Vendor vendor) async {
    final vendorId = vendor.id.toString();
    if (_togglingVendorIds.contains(vendorId)) return;

    final previousValue = vendor.isFavorite;
    final optimisticValue = !previousValue;

    setState(() {
      _togglingVendorIds.add(vendorId);
      vendor.isFavorite = optimisticValue;
    });
    VendorRepository.setFavorite(
      widget.eventId,
      vendorId,
      optimisticValue,
      notify: false,
    );

    try {
      final confirmedValue = await VendorRepository.toggleFavorite(
        widget.eventId,
        vendorId,
        fallback: optimisticValue,
      );
      if (!mounted) return;

      setState(() {
        vendor.isFavorite = confirmedValue;
      });
    } catch (e) {
      VendorRepository.setFavorite(widget.eventId, vendorId, previousValue);
      if (!mounted) return;

      setState(() {
        vendor.isFavorite = previousValue;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update favourite. Try again.')),
      );
    } finally {
      if (mounted) {
        setState(() => _togglingVendorIds.remove(vendorId));
      } else {
        _togglingVendorIds.remove(vendorId);
      }
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
    final showInitialLoader = _isLoading && _allVendors.isEmpty;

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
                      FontAwesomeIcons.xmark,
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
                  if (!mounted) return;
                  unawaited(_loadVendors(forceRefresh: true));
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
      body: showInitialLoader
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
                            setState(() {
                              _selectedCategory = category;
                              _filteredVendors = _matchingVendors();
                            });
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
                  child: RefreshIndicator(
                    onRefresh: () => _loadVendors(forceRefresh: true),
                    child: _filteredVendors.isEmpty
                        ? _buildEmptyList()
                        : ListView.builder(
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

  Widget _buildEmptyList() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.22),
        Icon(
          _errorMessage == null ? Icons.search_off : Icons.wifi_off_rounded,
          size: 64,
          color: AppColors.coral,
        ),
        const SizedBox(height: 16),
        Text(
          _errorMessage ?? 'No vendors found',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: AppColors.coral),
        ),
      ],
    );
  }

  Widget _buildVendorCard(Vendor vendor, {Key? key}) {
    final isToggling = _togglingVendorIds.contains(vendor.id.toString());

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
                      if (vendor.orderCount > 0)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.coral,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.shopping_cart_rounded,
                                size: 12,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${vendor.orderCount} order${vendor.orderCount > 1 ? 's' : ''}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
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
            const SizedBox(height: 16),
            Row(
              children: [
                GestureDetector(
                  onTap: isToggling ? null : () => _toggleFavorite(vendor),
                  child: Opacity(
                    opacity: isToggling ? 0.45 : 1,
                    child: Icon(
                      vendor.isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: AppColors.darkpink,
                      size: 28,
                    ),
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
