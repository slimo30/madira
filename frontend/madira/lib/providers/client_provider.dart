// import 'package:flutter/material.dart';
// import '../models/client_model.dart';
// import '../services/client_service.dart';

// class ClientProvider with ChangeNotifier {
//   final ClientService _clientService = ClientService();

//   List<ClientModel> _clients = [];
//   bool _isLoading = false;
//   String? _error;
//   bool _isFetching = false;

//   // Pagination properties
//   int _currentPage = 1;
//   int _pageSize = 10;
//   int _totalCount = 0;
//   String? _nextPage;
//   String? _previousPage;

//   // Search and ordering
//   String _searchQuery = '';
//   String _ordering = 'name';

//   // Getters
//   List<ClientModel> get clients => _clients;
//   bool get isLoading => _isLoading;
//   String? get error => _error;
//   int get currentPage => _currentPage;
//   int get pageSize => _pageSize;
//   int get totalCount => _totalCount;
//   int get totalPages => (_totalCount / _pageSize).ceil();
//   bool get hasNextPage => _nextPage != null;
//   bool get hasPreviousPage => _previousPage != null;
//   String get searchQuery => _searchQuery;
//   String get ordering => _ordering;

//   // Fetch clients with pagination and search
//   Future<void> fetchClients({
//     int? page,
//     String? search,
//     String? ordering,
//   }) async {
//     if (_isFetching) {
//       print(
//         '⚠️ ClientProvider: Fetch already in progress, skipping duplicate request',
//       );
//       return;
//     }

//     _isFetching = true;
//     _isLoading = true;
//     _error = null;

//     // Update search and ordering if provided
//     if (search != null) _searchQuery = search;
//     if (ordering != null) _ordering = ordering;
//     if (page != null) _currentPage = page;

//     notifyListeners();

//     try {
//       final response = await _clientService.getClients(
//         page: _currentPage,
//         pageSize: _pageSize,
//         search: _searchQuery,
//         ordering: _ordering,
//       );

//       _clients = response['results'] as List<ClientModel>;
//       _totalCount = response['count'] as int;
//       _nextPage = response['next'] as String?;
//       _previousPage = response['previous'] as String?;

//       print(
//         '✅ ClientProvider: Fetched ${_clients.length} clients successfully',
//       );
//       print('📊 Total count: $_totalCount, Page: $_currentPage/$totalPages');
//     } catch (e) {
//       _error = e.toString();
//       print('❌ ClientProvider: Error fetching clients: $e');
//     } finally {
//       _isLoading = false;
//       _isFetching = false;
//       notifyListeners();
//     }
//   }

//   // Navigate to next page
//   Future<void> nextPage() async {
//     if (hasNextPage && _currentPage < totalPages) {
//       await fetchClients(page: _currentPage + 1);
//     }
//   }

//   // Navigate to previous page
//   Future<void> previousPage() async {
//     if (hasPreviousPage && _currentPage > 1) {
//       await fetchClients(page: _currentPage - 1);
//     }
//   }

//   // Go to specific page
//   Future<void> goToPage(int page) async {
//     if (page > 0 && page <= totalPages) {
//       await fetchClients(page: page);
//     }
//   }

//   // Search clients
//   Future<void> searchClients(String query) async {
//     _searchQuery = query;
//     _currentPage = 1; // Reset to first page on new search
//     await fetchClients();
//   }

//   // Update ordering
//   Future<void> updateOrdering(String newOrdering) async {
//     _ordering = newOrdering;
//     _currentPage = 1; // Reset to first page
//     await fetchClients();
//   }

//   // Create new client
//   Future<void> createClient({
//     required String name,
//     required String phone,
//     required String address,
//     required String creditBalance,
//     required String clientType,
//     required String notes,
//   }) async {
//     _isLoading = true;
//     _error = null;
//     notifyListeners();

//     try {
//       print('📝 ClientProvider: Creating client: $name');
//       await _clientService.createClient(
//         name: name,
//         phone: phone,
//         address: address,
//         creditBalance: creditBalance,
//         clientType: clientType,
//         notes: notes,
//       );

//       // Refresh clients list
//       print('🔄 ClientProvider: Refreshing clients list');
//       await fetchClients();
//       print('✅ ClientProvider: Client created and list refreshed');
//     } catch (e) {
//       _error = e.toString();
//       print('❌ ClientProvider: Error creating client: $e');
//       rethrow;
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   // Update client
//   Future<void> updateClient(
//     int clientId, {
//     required String name,
//     required String phone,
//     required String address,
//     required String creditBalance,
//     required String clientType,
//     required String notes,
//     required bool isActive,
//   }) async {
//     try {
//       print('🔄 ClientProvider: Updating client $clientId');
//       final updatedClient = await _clientService.updateClient(
//         clientId,
//         name: name,
//         phone: phone,
//         address: address,
//         creditBalance: creditBalance,
//         clientType: clientType,
//         notes: notes,
//         isActive: isActive,
//       );

//       // Update in local list
//       final index = _clients.indexWhere((c) => c.id == clientId);
//       if (index != -1) {
//         _clients[index] = updatedClient;
//         print('✅ ClientProvider: Client $clientId updated locally');
//       }
//       notifyListeners();
//     } catch (e) {
//       _error = e.toString();
//       print('❌ ClientProvider: Error updating client: $e');
//       rethrow;
//     }
//   }

//   // Deactivate client
//   Future<void> deactivateClient(int clientId) async {
//     try {
//       print('🔄 ClientProvider: Deactivating client $clientId');
//       await _clientService.deleteClient(clientId);

//       // Refresh the client data
//       await fetchClients();
//       print(
//         '✅ ClientProvider: Client $clientId deactivated and list refreshed',
//       );
//     } catch (e) {
//       _error = e.toString();
//       print('❌ ClientProvider: Error deactivating client: $e');
//       rethrow;
//     }
//   }

//   // Get complete client profile
//   Future<Map<String, dynamic>> getClientComplete(int clientId) async {
//     try {
//       print(
//         '🔄 ClientProvider: Fetching complete profile for client $clientId',
//       );
//       final completeData = await _clientService.getClientComplete(clientId);
//       print('✅ ClientProvider: Complete profile fetched');
//       return completeData;
//     } catch (e) {
//       _error = e.toString();
//       print('❌ ClientProvider: Error fetching complete profile: $e');
//       rethrow;
//     }
//   }

//   // Clear error
//   void clearError() {
//     _error = null;
//     notifyListeners();
//   }

//   // Reset pagination
//   void resetPagination() {
//     _currentPage = 1;
//     _searchQuery = '';
//     _ordering = 'name';
//     notifyListeners();
//   }
// }
import 'package:flutter/material.dart';
import '../models/client_model.dart';
import '../services/client_service.dart';

class ClientProvider with ChangeNotifier {
  final ClientService _clientService = ClientService();

  List<ClientModel> _clients = [];
  bool _isLoading = false;
  String? _error;
  bool _isFetching = false;

  // Pagination properties
  int _currentPage = 1;
  int _pageSize = 10;
  int _totalCount = 0;
  String? _nextPage;
  String? _previousPage;

  // Search and ordering
  String _searchQuery = '';
  String _ordering = 'name';

  // Getters
  List<ClientModel> get clients => _clients;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  int get totalCount => _totalCount;
  int get totalPages => (_totalCount / _pageSize).ceil();
  bool get hasNextPage => _nextPage != null;
  bool get hasPreviousPage => _previousPage != null;
  String get searchQuery => _searchQuery;
  String get ordering => _ordering;

  // Fetch clients with pagination and search
  Future<void> fetchClients({
    int? page,
    String? search,
    String? ordering,
  }) async {
    if (_isFetching) {
      print(
        '⚠️ ClientProvider: Fetch already in progress, skipping duplicate request',
      );
      return;
    }

    _isFetching = true;
    _isLoading = true;
    _error = null;

    // Update search and ordering if provided
    if (search != null) _searchQuery = search;
    if (ordering != null) _ordering = ordering;
    if (page != null) _currentPage = page;

    notifyListeners();

    try {
      final response = await _clientService.getClients(
        page: _currentPage,
        pageSize: _pageSize,
        search: _searchQuery,
        ordering: _ordering,
      );

      _clients = response['results'] as List<ClientModel>;
      _totalCount = response['count'] as int;
      _nextPage = response['next'] as String?;
      _previousPage = response['previous'] as String?;

      print(
        '✅ ClientProvider: Fetched ${_clients.length} clients successfully',
      );
      print('📊 Total count: $_totalCount, Page: $_currentPage/$totalPages');
    } catch (e) {
      _error = e.toString();
      print('❌ ClientProvider: Error fetching clients: $e');
    } finally {
      _isLoading = false;
      _isFetching = false;
      notifyListeners();
    }
  }

  // ✅ API SEARCH METHOD - Server-side search with pagination
  Future<List<ClientModel>> searchClientsAPI(String query) async {
    if (query.isEmpty) {
      _clients = [];
      _searchQuery = '';
      _currentPage = 1;
      _totalCount = 0;
      _nextPage = null;
      _previousPage = null;
      notifyListeners();
      return [];
    }

    if (_isFetching) {
      print(
        '⚠️ ClientProvider: Search already in progress, skipping duplicate request',
      );
      return _clients;
    }

    _isFetching = true;
    _isLoading = true;
    _error = null;
    _searchQuery = query;
    _currentPage = 1; // Reset to first page on new search

    notifyListeners();

    try {
      print('🔍 ClientProvider: Searching API for clients: "$query"');
      final response = await _clientService.getClients(
        page: _currentPage,
        pageSize: _pageSize,
        search: _searchQuery,
        ordering: _ordering,
      );

      _clients = response['results'] as List<ClientModel>;
      _totalCount = response['count'] as int;
      _nextPage = response['next'] as String?;
      _previousPage = response['previous'] as String?;

      print(
        '✅ ClientProvider: Search found ${_clients.length} clients for "$_searchQuery"',
      );
      print('📊 Total results: $_totalCount');

      return _clients;
    } catch (e) {
      _error = e.toString();
      _clients = [];
      print('❌ ClientProvider: Error searching clients: $e');
      return [];
    } finally {
      _isLoading = false;
      _isFetching = false;
      notifyListeners();
    }
  }

  // Navigate to next page
  Future<void> nextPage() async {
    if (hasNextPage && _currentPage < totalPages) {
      await fetchClients(page: _currentPage + 1);
    }
  }

  // Navigate to previous page
  Future<void> previousPage() async {
    if (hasPreviousPage && _currentPage > 1) {
      await fetchClients(page: _currentPage - 1);
    }
  }

  // Go to specific page
  Future<void> goToPage(int page) async {
    if (page > 0 && page <= totalPages) {
      await fetchClients(page: page);
    }
  }

  // Search clients
  Future<void> searchClients(String query) async {
    _searchQuery = query;
    _currentPage = 1; // Reset to first page on new search
    await fetchClients();
  }

  // Update ordering
  Future<void> updateOrdering(String newOrdering) async {
    _ordering = newOrdering;
    _currentPage = 1; // Reset to first page
    await fetchClients();
  }

  // Create new client
  Future<void> createClient({
    required String name,
    required String phone,
    required String address,
    required String creditBalance,
    required String clientType,
    required String notes,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('📝 ClientProvider: Creating client: $name');
      await _clientService.createClient(
        name: name,
        phone: phone,
        address: address,
        creditBalance: creditBalance,
        clientType: clientType,
        notes: notes,
      );

      // Refresh clients list
      print('🔄 ClientProvider: Refreshing clients list');
      await fetchClients();
      print('✅ ClientProvider: Client created and list refreshed');
    } catch (e) {
      _error = e.toString();
      print('❌ ClientProvider: Error creating client: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update client
  Future<void> updateClient(
    int clientId, {
    required String name,
    required String phone,
    required String address,
    required String creditBalance,
    required String clientType,
    required String notes,
    required bool isActive,
  }) async {
    try {
      print('🔄 ClientProvider: Updating client $clientId');
      final updatedClient = await _clientService.updateClient(
        clientId,
        name: name,
        phone: phone,
        address: address,
        creditBalance: creditBalance,
        clientType: clientType,
        notes: notes,
        isActive: isActive,
      );

      // Update in local list
      final index = _clients.indexWhere((c) => c.id == clientId);
      if (index != -1) {
        _clients[index] = updatedClient;
        print('✅ ClientProvider: Client $clientId updated locally');
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      print('❌ ClientProvider: Error updating client: $e');
      rethrow;
    }
  }

  // Deactivate client
  Future<void> deactivateClient(int clientId) async {
    try {
      print('🔄 ClientProvider: Deactivating client $clientId');
      await _clientService.deleteClient(clientId);

      // Refresh the client data
      await fetchClients();
      print(
        '✅ ClientProvider: Client $clientId deactivated and list refreshed',
      );
    } catch (e) {
      _error = e.toString();
      print('❌ ClientProvider: Error deactivating client: $e');
      rethrow;
    }
  }

  // Get complete client profile
  Future<Map<String, dynamic>> getClientComplete(int clientId) async {
    try {
      print(
        '🔄 ClientProvider: Fetching complete profile for client $clientId',
      );
      final completeData = await _clientService.getClientComplete(clientId);
      print('✅ ClientProvider: Complete profile fetched');
      return completeData;
    } catch (e) {
      _error = e.toString();
      print('❌ ClientProvider: Error fetching complete profile: $e');
      rethrow;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Reset pagination
  void resetPagination() {
    _currentPage = 1;
    _searchQuery = '';
    _ordering = 'name';
    notifyListeners();
  }
}
