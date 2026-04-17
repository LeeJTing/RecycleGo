import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/controller/admin/admin_management_ctrl.dart';
import 'package:recycle_go/models/Admins.dart';
import 'package:recycle_go/provider/AdminProvider.dart';
import 'package:recycle_go/view/admin/adminManagement/widgets/admin_card.dart';
import 'package:recycle_go/view/admin/adminManagement/add_admin_screen.dart';
import 'package:recycle_go/view/admin/adminManagement/admin_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminManagementScreen extends StatefulWidget {
  const AdminManagementScreen({super.key});

  @override
  State<AdminManagementScreen> createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends State<AdminManagementScreen> {
  final AdminManagementCtrl _ctrl = AdminManagementCtrl();
  List<Admins> _allAdmins = [];
  List<Admins> _filteredAdmins = [];
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _statusFilter = 'all';
  String _roleFilter = 'all';

  List<String> _searchHistory = [];
  bool _showHistory = false;

  @override
  void initState() {
    super.initState();
    _loadAdmins();
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
      _searchHistory = prefs.getStringList('admin_search_history') ?? [];
    });
  }

  Future<void> _addToHistory(String query) async {
    if (query.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();

    List<String> history = List.from(_searchHistory);
    history.remove(query); // Remove if exists to move to top
    history.insert(0, query);

    if (history.length > 5) {
      history = history.sublist(0, 5);
    }

    await prefs.setStringList('admin_search_history', history);
    setState(() {
      _searchHistory = history;
    });
  }

  Future<void> _removeFromHistory(String query) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = List.from(_searchHistory);
    history.remove(query);
    await prefs.setStringList('admin_search_history', history);
    setState(() {
      _searchHistory = history;
    });
  }

  Future<void> _loadAdmins() async {
    setState(() => _isLoading = true);
    try {
      final admins = await _ctrl.fetchAdmins();
      setState(() {
        _allAdmins = admins;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading admins: $e')));
      }
    }
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredAdmins = _allAdmins.where((admin) {
        final matchesSearch =
            admin.username.toLowerCase().contains(query) ||
            admin.email.toLowerCase().contains(query);
        final matchesStatus =
            _statusFilter == 'all' || admin.adminStatus == _statusFilter;
        final matchesRole = _roleFilter == 'all' || admin.role == _roleFilter;
        return matchesSearch && matchesStatus && matchesRole;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;
    final currentAdmin = Provider.of<AdminProvider>(
      context,
      listen: false,
    ).admin;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: Text("Admin Management", style: TextDesign.appBarTitle()),
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
                      onRefresh: _loadAdmins,
                      color: theme.primary,
                      child: _filteredAdmins.isEmpty
                          ? Center(
                              child: Text(
                                "No admins found",
                                style: TextDesign.normalText(color: theme.hint),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredAdmins.length,
                              itemBuilder: (context, index) {
                                final admin = _filteredAdmins[index];
                                return InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            AdminDetailScreen(admin: admin),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: AdminCard(
                                    admin: admin,
                                    theme: theme,
                                    isCurrentUser:
                                        admin.adminId == currentAdmin?.adminId,
                                    onStatusChanged: (isActive) async {
                                      if (admin.adminId ==
                                          currentAdmin?.adminId)
                                        return;
                                      try {
                                        await _ctrl.updateAdminStatus(
                                          admin.adminId!,
                                          isActive ? 'active' : 'inactive',
                                        );
                                        _loadAdmins();
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
            MaterialPageRoute(builder: (_) => const AddAdminScreen()),
          );
          if (result == true) _loadAdmins();
        },
        backgroundColor: theme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Add Admin",
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
            keyboardType: TextInputType.text,
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
                  value: _roleFilter,
                  items: ['all', 'super admin', 'normal'],
                  label: "Role",
                  onChanged: (val) {
                    setState(() => _roleFilter = val!);
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
