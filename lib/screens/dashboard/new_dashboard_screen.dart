import 'package:flutter/material.dart';
import '../../widgets/common/app_sidebar.dart';
import '../../widgets/common/app_top_bar.dart';
import '../../api-routes/dashboard/dashboard_api_routes.dart';
import '../../models/case_model.dart';
import 'widgets/stats_card.dart';
import 'widgets/action_buttons.dart';
import 'widgets/cases_table.dart';
import 'widgets/search_bar_widget.dart';
import 'widgets/status_filter_dropdown.dart';
import 'widgets/pagination_controls.dart';

class NewDashboardScreen extends StatefulWidget {
  const NewDashboardScreen({Key? key}) : super(key: key);

  @override
  State<NewDashboardScreen> createState() => _NewDashboardScreenState();
}

class _NewDashboardScreenState extends State<NewDashboardScreen> {
  List<CaseModel> _cases = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _totalCases = 0;
  int _inProgressCases = 0;
  int _completedCases = 0;

  // Search and filter state
  String _searchQuery = '';
  String _selectedStatus = 'all';

  // Pagination state
  int _currentPage = 1;
  int _itemsPerPage = 10;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _fetchCases();
  }

  Future<void> _fetchCases() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await DashboardApiRoutes.getAllCases(
        page: _currentPage,
        limit: _itemsPerPage,
        status: _selectedStatus != 'all' ? _selectedStatus : null,
      );

      final casesList = (result['cases'] as List)
          .map((caseJson) => CaseModel.fromJson(caseJson))
          .toList();

      // Calculate stats
      final total = result['pagination']['total'] as int;
      final inProgress = casesList
          .where((c) => c.status == 'processing')
          .length;
      final completed = casesList.where((c) => c.status == 'completed').length;

      setState(() {
        _cases = casesList;
        _totalCases = total;
        _inProgressCases = inProgress;
        _completedCases = completed;
        _totalPages = (total / _itemsPerPage).ceil();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Row(
        children: [
          // Shared Sidebar
          const AppSidebar(currentRoute: '/dashboard'),
          // Main content
          Expanded(
            child: Column(
              children: [
                const AppTopBar(
                  title: 'Dashboard',
                  subtitle: 'Monitor and manage your forensic cases',
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatsCards(),
                        const SizedBox(height: 24),
                        const ActionButtons(),
                        const SizedBox(height: 24),
                        _buildSearchAndFilter(),
                        const SizedBox(height: 16),
                        _buildCasesSection(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: StatsCard(
            title: 'Total Cases',
            value: _isLoading ? '...' : _totalCases.toString(),
            subtitle: _isLoading ? '' : '+${_cases.length} loaded',
            icon: Icons.folder_outlined,
            color: const Color(0xFF3B82F6),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatsCard(
            title: 'In Progress',
            value: _isLoading ? '...' : _inProgressCases.toString(),
            subtitle: _isLoading ? '' : 'Processing...',
            icon: Icons.sync,
            color: const Color(0xFF8B5CF6),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatsCard(
            title: 'Completed',
            value: _isLoading ? '...' : _completedCases.toString(),
            subtitle: _isLoading ? '' : 'Finished',
            icon: Icons.check_circle_outline,
            color: const Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: StatsCard(
            title: 'Threats Found',
            value: '0',
            subtitle: 'Analysis pending',
            icon: Icons.warning_amber_outlined,
            color: Color(0xFFEF4444),
          ),
        ),
      ],
    );
  }

  Widget _buildCasesSection() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48.0),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00D9FF)),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48.0),
          child: Column(
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Color(0xFFEF4444),
              ),
              const SizedBox(height: 16),
              const Text(
                'Error loading cases',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _fetchCases,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D9FF),
                  foregroundColor: const Color(0xFF0A0E1A),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_cases.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48.0),
          child: Column(
            children: [
              const Icon(Icons.folder_open, size: 64, color: Color(0xFF64748B)),
              const SizedBox(height: 16),
              const Text(
                'No cases yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Upload a memory dump to get started',
                style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/upload');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D9FF),
                  foregroundColor: const Color(0xFF0A0E1A),
                ),
                child: const Text('Upload Case'),
              ),
            ],
          ),
        ),
      );
    }

    return _buildCasesWithPagination();
  }

  Widget _buildSearchAndFilter() {
    return Row(
      children: [
        SearchBarWidget(
          searchQuery: _searchQuery,
          onSearchChanged: (query) {
            setState(() {
              _searchQuery = query;
              _currentPage = 1; // Reset to first page on search
            });
          },
          onClear: () {
            setState(() {
              _searchQuery = '';
              _currentPage = 1;
            });
          },
        ),
        const SizedBox(width: 16),
        StatusFilterDropdown(
          selectedStatus: _selectedStatus,
          onStatusChanged: (status) {
            if (status != null) {
              setState(() {
                _selectedStatus = status;
                _currentPage = 1; // Reset to first page on filter change
              });
              _fetchCases(); // Fetch with new filter
            }
          },
        ),
      ],
    );
  }

  List<CaseModel> _getFilteredCases() {
    if (_searchQuery.isEmpty) {
      return _cases;
    }

    final query = _searchQuery.toLowerCase();
    return _cases.where((caseModel) {
      final nameMatch = caseModel.name.toLowerCase().contains(query);
      final idMatch = caseModel.id.toString().contains(query);
      return nameMatch || idMatch;
    }).toList();
  }

  Widget _buildCasesWithPagination() {
    final filteredCases = _getFilteredCases();

    return Column(
      children: [
        CasesTable(cases: filteredCases, onRefresh: _fetchCases),
        if (filteredCases.isNotEmpty)
          PaginationControls(
            currentPage: _currentPage,
            totalPages: _totalPages,
            totalItems: _totalCases,
            itemsPerPage: _itemsPerPage,
            onPageChanged: (page) {
              setState(() {
                _currentPage = page;
              });
              _fetchCases();
            },
            onItemsPerPageChanged: (itemsPerPage) {
              setState(() {
                _itemsPerPage = itemsPerPage;
                _currentPage = 1; // Reset to first page
              });
              _fetchCases();
            },
          ),
      ],
    );
  }
}
