import 'package:flutter/material.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/models/Appeals.dart';
import 'package:recycle_go/view/user/appeal/appeal_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppealListScreen extends StatefulWidget {
  final List<Appeals> initialAppeals;
  final String userId;

  const AppealListScreen({super.key, required this.initialAppeals, required this.userId});

  @override
  State<AppealListScreen> createState() => _AppealListScreenState();
}

class _AppealListScreenState extends State<AppealListScreen> {
  late List<Appeals> _allAppeals;
  List<Appeals> _filteredAppeals = [];
  bool _isLoading = false;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _statusFilter = 'all';
  String _sortOption = 'newest';

  List<String> _searchHistory = [];
  bool _showHistory = false;

  @override
  void initState() {
    super.initState();
    _allAppeals = widget.initialAppeals;
    _loadSearchHistory();
    _applyFilters();
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
      _searchHistory = prefs.getStringList('appeal_search_history') ?? [];
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

    await prefs.setStringList('appeal_search_history', history);
    setState(() {
      _searchHistory = history;
    });
  }

  Future<void> _removeFromHistory(String query) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = List.from(_searchHistory);
    history.remove(query);
    await prefs.setStringList('appeal_search_history', history);
    setState(() {
      _searchHistory = history;
    });
  }

  Future<void> _refreshAppeals() async {
    setState(() => _isLoading = true);
    try {
      final appeals = await AppealsModel().getUserAppeals(widget.userId);
      setState(() {
        _allAppeals = appeals;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    List<Appeals> filtered = _allAppeals.where((appeal) {
      final matchesSearch = appeal.appealReason.toLowerCase().contains(query);
      final matchesStatus = _statusFilter == 'all' || appeal.appealStatus == _statusFilter;
      return matchesSearch && matchesStatus;
    }).toList();

    // Sorting: First come last show (Newest first)
    if (_sortOption == 'newest') {
      filtered.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
    } else if (_sortOption == 'oldest') {
      filtered.sort((a, b) => (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0)));
    }

    setState(() {
      _filteredAppeals = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: Text("My Appeals", style: TextDesign.appBarTitle()),
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
                  ? Center(child: CircularProgressIndicator(color: theme.primary))
                  : RefreshIndicator(
                      onRefresh: _refreshAppeals,
                      color: theme.primary,
                      child: _filteredAppeals.isEmpty
                          ? Center(
                              child: Text(
                                "No appeals found",
                                style: TextDesign.normalText(color: theme.hint),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredAppeals.length,
                              itemBuilder: (context, index) {
                                final appeal = _filteredAppeals[index];
                                return _buildAppealCard(appeal, theme);
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppealCard(Appeals appeal, AppColors theme) {
    Color statusColor;
    switch (appeal.appealStatus.toLowerCase()) {
      case 'approved': statusColor = theme.success; break;
      case 'rejected': statusColor = theme.error; break;
      default: statusColor = theme.warning;
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AppealDetailScreen(appeal: appeal)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(appeal.appealReason, style: TextDesign.mediumText(), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(
                    appeal.createdAt != null 
                        ? _formatDate(appeal.createdAt!) 
                        : 'N/A', 
                    style: TextDesign.smallText(color: theme.hint)
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(appeal.appealStatus.toUpperCase(), style: TextDesign.badgeText(color: statusColor, fontSize: 10)),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
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
            decoration: InputDecoration(
              hintText: "Search by reason...",
              prefixIcon: Icon(Icons.search, color: theme.hint),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(icon: Icon(Icons.clear, color: theme.hint), onPressed: () { _searchController.clear(); _applyFilters(); })
                  : null,
              filled: true,
              fillColor: theme.background,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdown(
                  value: _statusFilter,
                  items: ['all', 'approved', 'rejected', 'pending'],
                  label: "Status",
                  onChanged: (val) { setState(() => _statusFilter = val!); _applyFilters(); },
                  theme: theme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFilterDropdown(
                  value: _sortOption,
                  items: ['newest', 'oldest'],
                  label: "Sort By",
                  onChanged: (val) { setState(() => _sortOption = val!); _applyFilters(); },
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
      decoration: BoxDecoration(color: theme.background, borderRadius: BorderRadius.circular(12)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          style: TextDesign.smallText(color: theme.onSurface),
          onChanged: onChanged,
          items: items.map((String item) => DropdownMenuItem<String>(value: item, child: Text(item.toUpperCase()))).toList(),
        ),
      ),
    );
  }
}
