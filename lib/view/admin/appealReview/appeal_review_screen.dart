import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/controller/admin/appeal_controller.dart';
import 'package:recycle_go/models/Appeals.dart';
import 'package:recycle_go/view/admin/appealReview/widgets/appeal_detail_view.dart';

class AppealReviewScreen extends StatefulWidget {
  const AppealReviewScreen({super.key});

  @override
  State<AppealReviewScreen> createState() => _AppealReviewScreenState();
}

class _AppealReviewScreenState extends State<AppealReviewScreen> {
  final AppealController _controller = AppealController();
  String _selectedFilter = 'All';
  String _searchQuery = '';
  List<Appeals> _appeals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAppeals();
  }

  Future<void> _loadAppeals() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final appeals = await _controller.getAllAppeals();
      if (!mounted) return;
      setState(() {
        _appeals = appeals;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching appeals: $e");
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading appeals: $e')),
      );
    }
  }

  List<Appeals> get _filteredAppeals {
    return _appeals.where((appeal) {
      final matchesFilter = _selectedFilter == 'All' || 
          appeal.appealStatus.toLowerCase() == _selectedFilter.toLowerCase();
      final matchesSearch = appeal.submissionId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (appeal.userName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      return matchesFilter && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;

    return Scaffold(
      backgroundColor: theme.background,
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search by ID or User...',
                prefixIcon: const Icon(Icons.search),
                fillColor: theme.surface,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: ['All', 'Pending', 'Approved', 'Rejected'].map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (val) => setState(() => _selectedFilter = filter),
                    backgroundColor: theme.surface,
                    selectedColor: theme.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : theme.onSurface,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    checkmarkColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // List
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: theme.primary))
                : RefreshIndicator(
                    onRefresh: _loadAppeals,
                    color: theme.primary,
                    child: _filteredAppeals.isEmpty
                        ? ListView(
                            children: [
                              SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                              Center(child: Text('No appeals found', style: TextDesign.normalText(color: theme.hint))),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filteredAppeals.length,
                            itemBuilder: (context, index) {
                              final appeal = _filteredAppeals[index];
                              return _buildAppealItem(appeal, theme);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppealItem(Appeals appeal, AppColors theme) {
    final dateStr = appeal.createdAt != null 
        ? DateFormat('MMM dd, yyyy').format(appeal.createdAt!)
        : 'N/A';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border),
      ),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AppealDetailView(appeal: appeal),
            ),
          );
          if (result == true) _loadAppeals();
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Photo Thumbnail with Count Badge
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child: appeal.photoUrl != null
                          ? Image.network(
                              appeal.photoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(color: theme.background, child: Icon(Icons.image_not_supported, color: theme.hint)),
                            )
                          : Container(color: theme.background, child: Icon(Icons.image, color: theme.hint)),
                    ),
                  ),
                  if (appeal.photoCount > 0)
                    Positioned(
                      right: 4,
                      bottom: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.camera_alt, color: Colors.white, size: 10),
                            const SizedBox(width: 2),
                            Text(
                              "${appeal.photoCount}",
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          appeal.userName ?? 'Unknown User',
                          style: TextDesign.mediumText().copyWith(fontWeight: FontWeight.bold),
                        ),
                        _buildStatusBadge(appeal.appealStatus, theme),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "ID: ${appeal.submissionId.substring(0, 8).toUpperCase()}",
                      style: TextDesign.smallText(color: theme.hint),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 14, color: theme.hint),
                        const SizedBox(width: 4),
                        Text(dateStr, style: TextDesign.label(fontSize: 11, color: theme.hint)),
                        const Spacer(),
                        Text(
                          "View",
                          style: TextStyle(color: theme.primary, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        Icon(Icons.chevron_right, size: 16, color: theme.primary),
                      ],
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

  Widget _buildStatusBadge(String status, AppColors theme) {
    Color color;
    switch (status.toLowerCase()) {
      case 'approved': color = theme.success; break;
      case 'rejected': color = theme.error; break;
      default: color = theme.warning;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
