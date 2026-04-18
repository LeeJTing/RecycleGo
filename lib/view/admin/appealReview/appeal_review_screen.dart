import 'package:flutter/material.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/controller/admin/appeal_controller.dart';
import 'package:recycle_go/models/Appeals.dart';
import 'package:recycle_go/widgets/appeal_card.dart';

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Appeal Review', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
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
                fillColor: Colors.grey[100],
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
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
                    backgroundColor: Colors.grey[100],
                    selectedColor: theme.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    checkmarkColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 20),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('Review Queue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.successContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_appeals.where((a) => a.appealStatus == 'pending').length} New',
                        style: TextStyle(color: theme.onSuccessContainer, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {},
                  child: Text('View All', style: TextStyle(color: theme.primary, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredAppeals.isEmpty
                    ? const Center(child: Text('No appeals found'))
                    : ListView.builder(
                        itemCount: _filteredAppeals.length,
                        itemBuilder: (context, index) {
                          final appeal = _filteredAppeals[index];
                          return AppealCard(
                            appeal: appeal,
                            onWeightChanged: (newWeight) {
                              // Handle weight adjustment locally or update model
                            },
                            onApprove: () => _handleApprove(appeal),
                            onReject: () => _handleReject(appeal),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _handleApprove(Appeals appeal) async {
    // Show dialog for points
    final controller = TextEditingController(text: (appeal.weight != null ? (appeal.weight! * 1000).toInt() : 0).toString());
    final commentController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Appeal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'Points to award'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: commentController,
              decoration: const InputDecoration(labelText: 'Comment (Optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await _controller.approveAppeal(
                appeal, 
                int.tryParse(controller.text) ?? 0,
                commentController.text
              );
              if (!mounted) return;
              Navigator.pop(context);
              _loadAppeals();
            }, 
            child: const Text('Approve')
          ),
        ],
      ),
    );
  }

  void _handleReject(Appeals appeal) async {
    final commentController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Appeal'),
        content: TextField(
          controller: commentController,
          decoration: const InputDecoration(labelText: 'Reason for rejection'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await _controller.rejectAppeal(appeal, commentController.text);
              if (!mounted) return;
              Navigator.pop(context);
              _loadAppeals();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
