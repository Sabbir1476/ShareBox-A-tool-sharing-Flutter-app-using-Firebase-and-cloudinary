import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/tool_model.dart';
import '../models/rental_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─── TOOLS ───────────────────────────────────────────────────────────────

  // Add a new tool
  Future<String> addTool(ToolModel tool) async {
    final docRef = await _firestore.collection('tools').add(tool.toMap());
    return docRef.id;
  }

  // Update a tool
  Future<void> updateTool(String toolId, Map<String, dynamic> data) async {
    await _firestore.collection('tools').doc(toolId).update(data);
  }

  // Delete a tool
  Future<void> deleteTool(String toolId) async {
    await _firestore.collection('tools').doc(toolId).delete();
  }

  // Get a single tool
  Future<ToolModel?> getTool(String toolId) async {
    final doc = await _firestore.collection('tools').doc(toolId).get();
    if (doc.exists) return ToolModel.fromFirestore(doc);
    return null;
  }

  // Stream all available tools (simplified - no composite index needed)
  Stream<List<ToolModel>> streamAvailableTools() {
    debugPrint('📡 Setting up stream for available tools...');
    return _firestore
        .collection('tools')
        .snapshots()
        .map((snapshot) {
      final tools = snapshot.docs
          .where((doc) => doc['isAvailable'] == true)
          .map((doc) => ToolModel.fromFirestore(doc))
          .toList();
      
      // Sort by createdAt in Dart instead of Firestore
      tools.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      debugPrint('📡 Stream received ${tools.length} available tools');
      for (var tool in tools.take(3)) {
        debugPrint('  - ${tool.name} (${tool.category.displayName})');
      }
      return tools;
    }).handleError((error) {
      debugPrint('❌ Stream error: $error');
      return [];
    });
  }

  // Get ALL tools (debug)
  Future<void> debugPrintAllTools() async {
    try {
      final snapshot = await _firestore.collection('tools').get();
      debugPrint('🔍 DEBUG: Total tools in database: ${snapshot.docs.length}');
      for (var doc in snapshot.docs) {
        debugPrint('  - ${doc['name']}: isAvailable=${doc['isAvailable']}, category=${doc['category']}');
      }
    } catch (e) {
      debugPrint('❌ Debug error: $e');
    }
  }

  // Get ALL tools (one-time fetch - simplified)
  Future<List<ToolModel>> getAllAvailableTools() async {
    try {
      debugPrint('📥 Fetching all available tools...');
      final snapshot = await _firestore.collection('tools').get();
      
      final tools = snapshot.docs
          .where((doc) => doc['isAvailable'] == true)
          .map((doc) => ToolModel.fromFirestore(doc))
          .toList();
      
      // Sort by createdAt in Dart
      tools.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      debugPrint('✅ Fetched ${tools.length} available tools');
      for (var tool in tools.take(3)) {
        debugPrint('  - ${tool.name} (Available: true, Created: ${tool.createdAt})');
      }
      return tools;
    } catch (e) {
      debugPrint('❌ Error fetching tools: $e');
      rethrow;
    }
  }

  // Stream tools by category
  Stream<List<ToolModel>> streamToolsByCategory(ToolCategory category) {
    return _firestore
        .collection('tools')
        .where('category', isEqualTo: category.name)
        .where('isAvailable', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ToolModel.fromFirestore(doc)).toList());
  }

  // Stream tools by owner
  Stream<List<ToolModel>> streamToolsByOwner(String ownerId) {
    return _firestore
        .collection('tools')
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ToolModel.fromFirestore(doc)).toList());
  }

  // Search tools by name
  Future<List<ToolModel>> searchTools(String query) async {
    final snapshot = await _firestore
        .collection('tools')
        .where('isAvailable', isEqualTo: true)
        .get();

    final tools =
        snapshot.docs.map((doc) => ToolModel.fromFirestore(doc)).toList();

    return tools
        .where((tool) =>
            tool.name.toLowerCase().contains(query.toLowerCase()) ||
            tool.description.toLowerCase().contains(query.toLowerCase()) ||
            tool.location.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  // Toggle tool availability
  Future<void> toggleToolAvailability(String toolId, bool isAvailable) async {
    await _firestore
        .collection('tools')
        .doc(toolId)
        .update({'isAvailable': isAvailable});
  }

  // ─── RENTALS ─────────────────────────────────────────────────────────────

  // Create a rental request
  Future<String> createRental(RentalModel rental) async {
    try {
      debugPrint('💾 Saving rental to Firestore...');
      
      // Validate required fields
      if (rental.renterId.isEmpty) {
        throw Exception('renterId is empty - user must be authenticated');
      }
      if (rental.ownerId.isEmpty) {
        throw Exception('ownerId is empty');
      }
      if (rental.toolId.isEmpty) {
        throw Exception('toolId is empty');
      }
      
      final rentalData = rental.toMap();
      debugPrint('   ✓ renterId: ${rentalData['renterId']}');
      debugPrint('   ✓ ownerId: ${rentalData['ownerId']}');
      debugPrint('   ✓ toolId: ${rentalData['toolId']}');
      debugPrint('   ✓ status: ${rentalData['status']}');
      
      final docRef = await _firestore.collection('rentals').add(rentalData);
      debugPrint('✅ Rental saved successfully with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error creating rental: $e');
      debugPrint('   Error type: ${e.runtimeType}');
      if (e.toString().contains('permission')) {
        debugPrint('   💡 Permission denied - check:');
        debugPrint('      1. Firestore rules allow create in rentals collection');
        debugPrint('      2. renterId matches current user UID');
        debugPrint('      3. User is authenticated');
      }
      rethrow;
    }
  }

  // Update rental status
  Future<void> updateRentalStatus(String rentalId, RentalStatus status) async {
    await _firestore
        .collection('rentals')
        .doc(rentalId)
        .update({'status': status.name});
  }

  // Stream rentals as renter
  Stream<List<RentalModel>> streamRentalsAsRenter(String renterId) {
    debugPrint('🔌 Setting up stream for rentals (as renter) for user: $renterId');
    return _firestore
        .collection('rentals')
        .where('renterId', isEqualTo: renterId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final rentals = snapshot.docs
          .map((doc) => RentalModel.fromFirestore(doc))
          .toList();
      debugPrint('📡 Stream received ${rentals.length} rentals');
      return rentals;
    }).handleError((error) {
      debugPrint('❌ Stream error (as renter): $error');
      return [];
    });
  }

  // Stream rentals as owner
  Stream<List<RentalModel>> streamRentalsAsOwner(String ownerId) {
    debugPrint('🔌 Setting up stream for rental requests (as owner) for user: $ownerId');
    return _firestore
        .collection('rentals')
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final rentals = snapshot.docs
          .map((doc) => RentalModel.fromFirestore(doc))
          .toList();
      debugPrint('📡 Stream received ${rentals.length} rental requests');
      return rentals;
    }).handleError((error) {
      debugPrint('❌ Stream error (as owner): $error');
      return [];
    });
  }

  // Get rental by id
  Future<RentalModel?> getRental(String rentalId) async {
    final doc = await _firestore.collection('rentals').doc(rentalId).get();
    if (doc.exists) return RentalModel.fromFirestore(doc);
    return null;
  }

  // Debug: Print all rentals
  Future<void> debugPrintAllRentals() async {
    try {
      final snapshot = await _firestore.collection('rentals').get();
      debugPrint('🔍 DEBUG: Total rentals in database: ${snapshot.docs.length}');
      for (var doc in snapshot.docs) {
        final data = doc.data();
        debugPrint('  ✓ Rental ${doc.id}:');
        debugPrint('     Tool: ${data['toolName']}');
        debugPrint('     Renter: ${data['renterId']}');
        debugPrint('     Owner: ${data['ownerId']}');
        debugPrint('     Status: ${data['status']}');
      }
    } catch (e) {
      debugPrint('❌ Debug error: $e');
    }
  }

  // ─── USERS ───────────────────────────────────────────────────────────────

  // Get user by id
  Future<UserModel?> getUser(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists) return UserModel.fromFirestore(doc);
    return null;
  }

  // Stream user
  Stream<UserModel?> streamUser(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      if (doc.exists) return UserModel.fromFirestore(doc);
      return null;
    });
  }

  // Update user
  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(userId).update(data);
  }

  // Toggle favorite tool
  Future<void> toggleFavoriteTool(String userId, String toolId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final data = userDoc.data() as Map<String, dynamic>? ?? {};
    final favorites = List<String>.from(data['favoriteTools'] ?? []);

    if (favorites.contains(toolId)) {
      favorites.remove(toolId);
    } else {
      favorites.add(toolId);
    }

    await _firestore
        .collection('users')
        .doc(userId)
        .update({'favoriteTools': favorites});
  }

  // Stream favorite tools
  Stream<List<ToolModel>> streamFavoriteTools(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().asyncMap(
      (userDoc) async {
        if (!userDoc.exists) return [];
        final data = userDoc.data() as Map<String, dynamic>? ?? {};
        final favorites = List<String>.from(data['favoriteTools'] ?? []);
        if (favorites.isEmpty) return [];

        final toolSnapshots = await Future.wait(
          favorites.map((id) => _firestore.collection('tools').doc(id).get()),
        );

        return toolSnapshots
            .where((doc) => doc.exists)
            .map((doc) => ToolModel.fromFirestore(doc))
            .toList();
      },
    );
  }

  // ─── STATS ───────────────────────────────────────────────────────────────

  // Get tool stats
  Future<Map<String, int>> getToolStats(String ownerId) async {
    final toolsSnapshot = await _firestore
        .collection('tools')
        .where('ownerId', isEqualTo: ownerId)
        .get();

    final rentalsSnapshot = await _firestore
        .collection('rentals')
        .where('ownerId', isEqualTo: ownerId)
        .get();

    return {
      'totalTools': toolsSnapshot.docs.length,
      'totalRentals': rentalsSnapshot.docs.length,
      'activeRentals': rentalsSnapshot.docs
          .where((doc) =>
              (doc.data()['status'] as String?) == RentalStatus.active.name)
          .length,
    };
  }
}
