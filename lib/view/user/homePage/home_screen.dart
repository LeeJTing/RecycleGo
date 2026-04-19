import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recycle_go/app/routes.dart';
import 'package:recycle_go/controller/admin/submission_controller.dart';
import 'package:recycle_go/models/Appeals.dart';
import 'package:recycle_go/provider/UserProvider.dart';
import 'package:recycle_go/view/user/bottom_nav_bar.dart';
import 'package:recycle_go/view/user/homePage/widgets/home_header.dart';
import 'package:recycle_go/view/user/homePage/widgets/score_cards.dart';
import 'package:recycle_go/view/user/homePage/widgets/scan_button.dart';
import 'package:recycle_go/view/user/homePage/widgets/nearby_bin_card.dart';
import 'package:recycle_go/view/recycle/qr_scan_screen.dart';
import 'package:recycle_go/view/recycle/map_screen.dart';
import 'package:recycle_go/view/user/profile/profile_screen.dart';
import 'package:recycle_go/view/voucher/voucher_main_page.dart';
import 'package:recycle_go/view/user/homePage/widgets/purchase_card.dart';
import 'package:recycle_go/view/user/appeal/widgets/appeal_status_card.dart';

import '../../../app/TextDesign.dart';
import '../../../models/RecyclingSubmission.dart';
import '../AI-verify-recycle/verify_recycle_item.dart';
import '../appeal/appeal_form_screen.dart';
import '../appeal/appeal_list_screen.dart';
import '../submission/all_user_submission.dart';

class UserHomeScreen extends StatefulWidget {
  final int initialIndex;
  const UserHomeScreen({super.key, this.initialIndex = 0});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    final List<Widget> _pages = [
      const _HomeContent(),
      const QrScanScreen(),
      const MapScreen(),
      VoucherMainPage(
        currentPoints: user?.totalPoints ?? 0,
        goalPoints: 1000,
        memberRank: 'Bronze',
        nextRank: 'Silver',
      ),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

class _HomeContent extends StatefulWidget {
  const _HomeContent();

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  List<Appeals> _appeals = [];
  bool _isLoadingAppeals = true;

  List<RecycleSubmission> _recentSubmissions = [];
  bool _isLoadingSubmissions = true;

  void _navigateToAllSubmissions() {
    final userId = context.read<UserProvider>().user?.userId;
    if (userId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AllUserSubmission()),
      );
    } else {
      print("User ID is null");
    }
  }

  Future<void> _fetchSubmissions() async {
    final userId = context.read<UserProvider>().user?.userId;

    if (userId == null) {
      debugPrint("User ID is null");
      return;
    }

    try {
      final service = SubmissionService();
      final data = await service.getUserSubmissions(userId);

      final subs = data
          .map((json) => RecycleSubmission.fromJson(json))
          .toList();

      setState(() {
        _recentSubmissions = subs;
        _isLoadingSubmissions = false;
      });

      debugPrint("Submissions refreshed: ${subs.length}");
    } catch (e) {
      debugPrint("Fetch error: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchAppeals();
    _fetchSubmissions();
  }

  Future<void> _fetchAppeals() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.user?.userId == null) return;

    try {
      final appeals = await AppealsModel().getUserAppeals(
        userProvider.user!.userId!,
      );
      if (mounted) {
        setState(() {
          _appeals = appeals;
          _isLoadingAppeals = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingAppeals = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _fetchAppeals,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HomeHeader(
                onProfileTap: () {
                  Navigator.pushReplacementNamed(context, Routes.userProfile);
                },
              ),
              const SizedBox(height: 20),
              Consumer<UserProvider>(
                builder: (context, userProvider, child) {
                  return ScoreCards(
                    totalPoints: userProvider.user?.totalPoints ?? 0,
                  );
                },
              ),
              const SizedBox(height: 24),
              ScanButton(
                onScanCompleted: () async {
                  debugPrint("Scan completed → refreshing UI");
                  await _fetchSubmissions();
                },
              ),
              const SizedBox(height: 24),

              if (_isLoadingSubmissions)
                const Center(child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: CircularProgressIndicator(),
                ))
              else if (_recentSubmissions.isEmpty)
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "You have no recent submissions yet.",
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => _navigateToAllSubmissions(),
                            child: const Text("Show More"),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Recent Submissions",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            TextButton(
                              onPressed: _navigateToAllSubmissions,
                              child: const Text("Show More"),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Column(
                          children: _recentSubmissions.take(3).map((sub) => _SubmissionTile(submission: sub)).toList(),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // final userId = context.read<UserProvider>().user?.userId;
                    // Navigator.push(context, MaterialPageRoute(builder: (_) => AppealPage(userId: userId!, submissionId: '',)));
                  },
                  icon: const Icon(Icons.assignment_outlined, size: 18),
                  label: const Text("Apply Appeal"),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const NearbyBinCard(),
              const SizedBox(height: 24),
              const PurchaseCard(),
            ],
          ),
        ),
      ),
    );
  }
}
class _SubmissionTile extends StatelessWidget {
  final RecycleSubmission submission;

  const _SubmissionTile({required this.submission});

  Color _getStatusColor() {
    switch (submission.status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _formatDate() {
    final d = submission.submittedAt;
    if (d == null) return "Unknown Date";
    // Formatting: DD/MM/YYYY
    return "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";
  }

  @override
  Widget build(BuildContext context) {
    final isRejected = submission.status.toLowerCase() == 'rejected';

    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: isRejected ? Colors.red.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRejected ? Colors.red.withOpacity(0.3) : Colors.grey.shade200,
        ),
      ),
      // Material + InkWell provides the clickable ripple effect
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // 1. .trim() removes any invisible spaces from the database string!
            final exactStatus = submission.status.trim().toLowerCase();

            print("Tile Tapped! The exact status is: '$exactStatus'");
            print("Submission ID: ${submission.submissionId}");

            // --- 🔴 REJECTED LOGIC ---
            if (exactStatus == 'rejected' || exactStatus == 'reject') {
              if (submission.submissionId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AppealPage(submissionId: submission.submissionId!),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Error: Submission ID missing!"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
            // --- 🟠 PENDING LOGIC ---
            else if (exactStatus == 'pending') {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("This submission is currently under review."),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 2),
                ),
              );
            }
            // --- 🟢 APPROVED LOGIC ---
            else if (exactStatus == 'approved') {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("This submission was successfully approved!"),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    submission.status.toLowerCase() == 'approved'
                        ? Icons.check_circle
                        : isRejected
                        ? Icons.error_outline
                        : Icons.access_time,
                    color: _getStatusColor(),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),

                // Details (Weight, Date, Points/Reason)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${submission.weight?.toStringAsFixed(1) ?? '0.0'} kg • ${_formatDate()}",
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isRejected && submission.rejectionReason != null
                            ? "Reason: ${submission.rejectionReason}"
                            : "Awarded: ${submission.pointAward?.toStringAsFixed(0) ?? '0'} pts",
                        style: TextStyle(
                          fontSize: 13,
                          color: isRejected ? Colors.red.shade700 : Colors.grey.shade600,
                          fontWeight: isRejected ? FontWeight.w500 : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                        color: _getStatusColor().withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        submission.status.toUpperCase(),
                        style: TextStyle(
                          color: _getStatusColor(),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    // Show arrow if it's clickable (rejected)
                    if (isRejected) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: Colors.grey.shade400,
                      ),
                    ],
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