import 'package:flutter/material.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/controller/admin/user_management_ctrl.dart';
import 'package:recycle_go/models/Users.dart';
import 'package:recycle_go/view/admin/userManagement/widgets/user_card.dart';
import 'package:recycle_go/view/admin/userManagement/add_user_screen.dart';
import 'package:recycle_go/view/admin/userManagement/user_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final UserManagementCtrl _ctrl = UserManagementCtrl();
  List<Users> _allUsers = [];
  List<Users> _filteredUsers = [];
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _statusFilter = 'all';
  String _sortOption = 'newest';

  List<String> _searchHistory = [];
  bool _showHistory = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadSearchHistory();
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(() {
      setState(() {
        _showHistory =
            _searchFocusNode.hasFocus &&
            _searchController.text.isEmpty &&
            _searchHistory.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _showHistory =
          _searchFocusNode.hasFocus &&
          _searchController.text.isEmpty &&
          _searchHistory.isNotEmpty;
    });
    _applyFilters();
  }

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _searchHistory = prefs.getStringList('user_search_history') ?? [];
    });
  }

  Future<void> _addToHistory(String query) async {
    if (query.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();

    List<String> history = List.from(_searchHistory);
    history.remove(query);
    history.insert(0, query);

    if (history.length > 5) {
      history = history.sublist(0, 5);
    }

    await prefs.setStringList('user_search_history', history);
    setState(() {
      _searchHistory = history;
    });
  }

  Future<void> _removeFromHistory(String query) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = List.from(_searchHistory);
    history.remove(query);
    await prefs.setStringList('user_search_history', history);
    setState(() {
      _searchHistory = history;
    });
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _ctrl.fetchUsers();
      setState(() {
        _allUsers = users;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading users: $e')));
      }
    }
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    List<Users> filtered = _allUsers.where((user) {
      final matchesSearch =
          user.userName.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query);
      final matchesStatus =
          _statusFilter == 'all' || user.accountStatus == _statusFilter;
      return matchesSearch && matchesStatus;
    }).toList();

    // Sorting
    if (_sortOption == 'newest') {
      filtered.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
    } else if (_sortOption == 'oldest') {
      filtered.sort((a, b) => (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0)));
    } else if (_sortOption == 'points') {
      filtered.sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
    }

    setState(() {
      _filteredUsers = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: Text("User Management", style: TextDesign.appBarTitle(),),
        backgroundColor: theme.onPrimary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: theme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            _buildSearchAndFilter(theme),
            if (_showHistory) _buildHistoryList(theme),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: theme.primary),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadUsers,
                      color: theme.primary,
                      child: _filteredUsers.isEmpty
                          ? Center(
                              child: Text(
                                "No users found",
                                style: TextDesign.normalText(color: theme.hint),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredUsers.length,
                              itemBuilder: (context, index) {
                                final user = _filteredUsers[index];
                                return InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            UserDetailScreen(user: user),
                                      ),
                                    ).then((_) => _loadUsers());
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: UserCard(
                                    user: user,
                                    theme: theme,
                                    onStatusChanged: (isActive) async {
                                      try {
                                        await _ctrl.updateUserStatus(
                                          user.userId!,
                                          isActive ? 'active' : 'inactive',
                                        );
                                        _loadUsers();
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Update failed: $e',
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddUserScreen()),
          );
          if (result == true) _loadUsers();
        },
        backgroundColor: theme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Add User",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildHistoryList(AppColors theme) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      width: double.infinity,
      color: theme.onPrimary,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _searchHistory.length,
        itemBuilder: (context, index) {
          final query = _searchHistory[index];
          return ListTile(
            leading: Icon(Icons.history, color: theme.hint, size: 20),
            title: Text(query, style: TextDesign.smallText()),
            trailing: IconButton(
              icon: Icon(Icons.close, size: 16, color: theme.hint),
              onPressed: () => _removeFromHistory(query),
            ),
            onTap: () {
              _searchController.text = query;
              _searchFocusNode.unfocus();
              _applyFilters();
            },
          );
        },
      ),
    );
  }

  Widget _buildSearchAndFilter(AppColors theme) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: theme.onPrimary,
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            onSubmitted: (value) => _addToHistory(value),
            enableSuggestions: false,
            autocorrect: false,
            autofillHints: null,
            decoration: InputDecoration(
              hintText: "Search by username or email...",
              prefixIcon: Icon(Icons.search, color: theme.hint),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: theme.hint),
                      onPressed: () {
                        _searchController.clear();
                        _applyFilters();
                      },
                    )
                  : null,
              filled: true,
              fillColor: theme.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdown(
                  value: _statusFilter,
                  items: ['all', 'active', 'inactive'],
                  label: "Status",
                  onChanged: (val) {
                    setState(() => _statusFilter = val!);
                    _applyFilters();
                  },
                  theme: theme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFilterDropdown(
                  value: _sortOption,
                  items: ['newest', 'oldest', 'points'],
                  label: "Sort By",
                  onChanged: (val) {
                    setState(() => _sortOption = val!);
                    _applyFilters();
                  },
                  theme: theme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String value,
    required List<String> items,
    required String label,
    required ValueChanged<String?> onChanged,
    required AppColors theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          style: TextDesign.smallText(color: theme.onSurface),
          onChanged: onChanged,
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item.toUpperCase()),
            );
          }).toList(),
        ),
      ),
    );
  }
}
