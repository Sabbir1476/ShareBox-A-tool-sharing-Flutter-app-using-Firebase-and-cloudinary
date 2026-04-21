import 'package:flutter/foundation.dart';
import '../services/firestore_service.dart';
import '../services/chat_service.dart';
import '../models/rental_model.dart';
import '../models/message_model.dart';

class RentalProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final ChatService _chatService = ChatService();

  List<RentalModel> _myRentals = [];
  List<RentalModel> _rentalsAsOwner = [];
  bool _isLoading = false;
  String? _error;

  List<RentalModel> get myRentals => _myRentals;
  List<RentalModel> get rentalsAsOwner => _rentalsAsOwner;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<RentalModel> get pendingRentals =>
      _rentalsAsOwner.where((r) => r.status == RentalStatus.pending).toList();

  List<RentalModel> get activeRentals =>
      _myRentals.where((r) => r.status == RentalStatus.active).toList();

  // Load rentals as renter
  void loadMyRentals(String userId) {
    debugPrint('📥 Loading rentals as renter for user: $userId');
    _firestoreService.streamRentalsAsRenter(userId).listen((rentals) {
      debugPrint('📦 Received ${rentals.length} rentals as renter');
      for (var rental in rentals.take(3)) {
        debugPrint('  ✓ ${rental.toolName} (${rental.status.displayName})');
      }
      _myRentals = rentals;
      notifyListeners();
    }, onError: (e) {
      debugPrint('❌ Error loading rentals: $e');
      _error = 'Failed to load rentals.';
      notifyListeners();
    });
  }

  // Load rentals as owner
  void loadRentalsAsOwner(String userId) {
    debugPrint('📥 Loading rental requests as owner for user: $userId');
    _firestoreService.streamRentalsAsOwner(userId).listen((rentals) {
      debugPrint('📦 Received ${rentals.length} rental requests');
      for (var rental in rentals.take(3)) {
        debugPrint('  ✓ ${rental.toolName} from ${rental.renterName} (${rental.status.displayName})');
      }
      _rentalsAsOwner = rentals;
      notifyListeners();
    }, onError: (e) {
      debugPrint('❌ Error loading rental requests: $e');
      _error = 'Failed to load rental requests.';
      notifyListeners();
    });
  }

  // Create rental request
  Future<bool> createRentalRequest({
    required String toolId,
    required String toolName,
    String? toolImage,
    required String ownerId,
    required String ownerName,
    required String renterId,
    required String renterName,
    required DateTime startDate,
    required DateTime endDate,
    required double pricePerDay,
    String? message,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      debugPrint('🎯 Creating rental request...');
      
      // Validate IDs are not empty
      if (renterId.isEmpty) {
        throw Exception('❌ Renter ID is empty - user not authenticated');
      }
      if (ownerId.isEmpty) {
        throw Exception('❌ Owner ID is empty');
      }
      if (toolId.isEmpty) {
        throw Exception('❌ Tool ID is empty');
      }
      if (renterName.isEmpty) {
        throw Exception('❌ Renter name is empty');
      }
      if (ownerName.isEmpty) {
        throw Exception('❌ Owner name is empty');
      }
      
      debugPrint('   ✓ Renter: $renterId ($renterName)');
      debugPrint('   ✓ Owner: $ownerId ($ownerName)');
      debugPrint('   ✓ Tool: $toolId ($toolName)');
      debugPrint('   ✓ Message: ${message ?? "none"}');
      
      final durationDays = endDate.difference(startDate).inDays + 1;
      final totalPrice = pricePerDay * durationDays;

      final rental = RentalModel(
        id: '',
        toolId: toolId,
        toolName: toolName,
        toolImage: toolImage,
        ownerId: ownerId,
        ownerName: ownerName,
        renterId: renterId,
        renterName: renterName,
        status: RentalStatus.pending,
        startDate: startDate,
        endDate: endDate,
        totalPrice: totalPrice,
        pricePerDay: pricePerDay,
        message: message,
        createdAt: DateTime.now(),
      );

      // Create or get chat room
      debugPrint('📞 Creating/getting chat room...');
      final chatRoomId = await _chatService.createOrGetChatRoom(
        currentUserId: renterId,
        currentUserName: renterName,
        otherUserId: ownerId,
        otherUserName: ownerName,
        toolId: toolId,
        toolName: toolName,
      );
      debugPrint('✅ Chat room: $chatRoomId');

      // Create the rental request
      debugPrint('💾 Saving rental to Firestore...');
      final rentalId = await _firestoreService.createRental(rental);
      debugPrint('✅ Rental created: $rentalId');

      // Send rental request message to chat if message is provided
      if (message != null && message.isNotEmpty) {
        debugPrint('💬 Sending message to chat...');
        await _chatService.sendMessage(
          chatRoomId: chatRoomId,
          senderId: renterId,
          receiverId: ownerId,
          message: message,
          type: MessageType.rentalRequest,
          rentalId: rentalId,
        );
        debugPrint('✅ Message sent');
      }

      debugPrint('🎉 Rental request created successfully!');
      return true;
    } catch (e) {
      debugPrint('❌ Error: $e');
      debugPrint('Stack: ${StackTrace.current}');
      
      String errorMsg = 'Failed to send rental request.';
      final errorStr = e.toString();
      
      if (errorStr.contains('permission')) {
        errorMsg = 'Permission denied. Update Firestore rules.';
        debugPrint('💡 Hint: Check rentals collection rules allow create');
      } else if (errorStr.contains('not authenticated')) {
        errorMsg = 'User not authenticated.';
      } else if (errorStr.contains('empty')) {
        errorMsg = errorStr;
      } else if (errorStr.contains('network')) {
        errorMsg = 'Network error. Check connection.';
      } else {
        errorMsg = 'Error: ${e.toString().substring(0, 80)}';
      }
      
      _error = errorMsg;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Accept rental
  Future<bool> acceptRental(String rentalId) async {
    return await _updateRentalStatus(rentalId, RentalStatus.accepted);
  }

  // Mark as active
  Future<bool> markAsActive(String rentalId) async {
    return await _updateRentalStatus(rentalId, RentalStatus.active);
  }

  // Complete rental
  Future<bool> completeRental(String rentalId) async {
    return await _updateRentalStatus(rentalId, RentalStatus.completed);
  }

  // Cancel rental
  Future<bool> cancelRental(String rentalId) async {
    return await _updateRentalStatus(rentalId, RentalStatus.cancelled);
  }

  Future<bool> _updateRentalStatus(
      String rentalId, RentalStatus status) async {
    _setLoading(true);
    _clearError();
    try {
      await _firestoreService.updateRentalStatus(rentalId, status);
      return true;
    } catch (e) {
      _error = 'Failed to update rental status.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  // Debug: Print all rentals from both perspectives
  void debugShowAllRentals() {
    debugPrint('🔍 My rentals (as renter): ${_myRentals.length}');
    for (var rental in _myRentals) {
      debugPrint('  ✓ ${rental.toolName} from ${rental.ownerName} (${rental.status.displayName})');
    }
    
    debugPrint('🔍 Rental requests (as owner): ${_rentalsAsOwner.length}');
    for (var rental in _rentalsAsOwner) {
      debugPrint('  ✓ ${rental.toolName} from ${rental.renterName} (${rental.status.displayName})');
    }
    
    _firestoreService.debugPrintAllRentals();
  }
}
