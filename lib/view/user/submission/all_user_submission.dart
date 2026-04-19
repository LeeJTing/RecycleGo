import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// IMPORTANT: Ensure these paths match your project structure!
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import '../../../controller/admin/submission_controller.dart';
import '../../../provider/UserProvider.dart';
import '../appeal/appeal_form_screen.dart'; // Import AppealPage for routing

class AllUserSubmission extends StatefulWidget {
  const AllUserSubmission({super.key});

  @override
  State<AllUserSubmission> createState() => _AllUserSubmissionState();
}

class _AllUserSubmissionState extends State<AllUserSubmission> {
  final SubmissionController _controller = SubmissionController();

  String _searchQuery = "";
  String _selectedFilter = "All";
  final List<String> _filterOptions = ["All", "Pending", "Approved", "Rejected"];

  List<Map<String, dynamic>> _mySubmissions = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchMySubmissions();
    });
  }

  Future<void> _fetchMySubmissions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = context.read<UserProvider>().user;
      final userId = user?.userId;

      if (userId == null) {
        if (mounted) {
          setState(() {
            _errorMessage = "User not logged in.";
            _isLoading = false;
          });
        }
        return;
      }

      final data = await _controller.getUserSubmissions(userId);

      if (mounted) {
        setState(() {
          _mySubmissions = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  // --- FILTERING LOGIC ---
  List<Map<String, dynamic>> get _filteredSubmissions {
    return _mySubmissions.where((sub) {
      final subId = sub['submission_id']?.toString() ?? "";
      final userId = sub['user_id']?.toString() ?? "";
      final status = sub['status']?.toString().toLowerCase().trim() ?? "pending";

      // 1. Search Filter
      final query = _searchQuery.toLowerCase();
      final matchesSearch = query.isEmpty ||
          subId.toLowerCase().contains(query) ||
          userId.toLowerCase().contains(query);

      // 2. Status Filter
      // We check for both "reject" and "rejected" just in case!
      bool matchesStatus = false;
      if (_selectedFilter == "All") {
        matchesStatus = true;
      } else if (_selectedFilter == "Rejected") {
        matchesStatus = (status == "rejected" || status == "reject");
      } else {
        matchesStatus = (status == _selectedFilter.toLowerCase());
      }

      return matchesSearch && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;

    // ✨ Grab the filtered list!
    final displayData = _filteredSubmissions;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: Text("My Submissions", style: TextDesign.appBarTitle()),
        backgroundColor: theme.surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Search Bar
          _buildSearchBar(theme),

          // 2. Filter Row
          _buildFilterRow(theme),

          Padding(
            padding: const EdgeInsets.only(left: 20.0, top: 16.0, bottom: 8.0),
            child: Text("All History", style: TextDesign.headingThree()),
          ),

          // 3. Submissions List
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: theme.primary))
                : _errorMessage != null
                ? Center(child: Text(_errorMessage!, style: TextDesign.normalText(color: theme.error)))
                : displayData.isEmpty
                ? Center(child: Text("No submissions found.", style: TextDesign.normalText(color: theme.hint)))
                : RefreshIndicator(
              onRefresh: _fetchMySubmissions,
              color: theme.primary,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: displayData.length,
                itemBuilder: (context, index) {
                  // ✨ Use your custom card builder
                  return _buildSubmissionCard(displayData[index], theme);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildSearchBar(AppColors theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))
          ],
          border: Border.all(color: theme.border.withOpacity(0.5)),
        ),
        child: TextField(
          onChanged: (value) => setState(() => _searchQuery = value),
          style: TextDesign.normalText(),
          decoration: InputDecoration(
            hintText: "Search by ID...",
            hintStyle: TextDesign.hintText(),
            prefixIcon: Icon(Icons.search, color: theme.primary),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterRow(AppColors theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: _filterOptions.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? theme.primary : theme.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? theme.primary : theme.border.withOpacity(0.5),
                  ),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected ? Colors.white : theme.onSurface,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSubmissionCard(Map<String, dynamic> submission, AppColors theme) {
    final status = submission['status']?.toString().toLowerCase().trim() ?? 'pending';
    final weight = submission['weight']?.toString() ?? '0.0';
    final points = submission['point_award']?.toString() ?? '0';
    final subId = submission['submission_id']?.toString();
    final isRejected = status == 'rejected' || status == 'reject';

    // Determine status colors
    Color statusColor;
    if (status == "approved") {
      statusColor = theme.success;
    } else if (isRejected) {
      statusColor = theme.error;
    } else {
      statusColor = theme.warning;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isRejected ? theme.error.withOpacity(0.05) : theme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isRejected ? theme.error.withOpacity(0.3) : theme.border.withOpacity(0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (isRejected && subId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AppealPage(submissionId: subId),
                ),
              );
            } else if (status == 'pending') {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: const Text("This submission is currently under review."), backgroundColor: theme.warning),
              );
            } else if (status == 'approved') {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: const Text("This submission was successfully approved!"), backgroundColor: theme.success),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon Box
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    status == 'approved' ? Icons.check_circle : isRejected ? Icons.error_outline : Icons.access_time,
                    color: statusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),

                // Text Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$weight kg",
                        style: TextDesign.normalText().copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isRejected ? "Needs Review" : "Awarded: $points pts",
                        style: TextDesign.smallText(color: isRejected ? theme.error : theme.hint),
                      ),
                    ],
                  ),
                ),

                // Status Badge & Arrow
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                    if (isRejected) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.chevron_right, size: 20, color: theme.hint),
                    ]
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}