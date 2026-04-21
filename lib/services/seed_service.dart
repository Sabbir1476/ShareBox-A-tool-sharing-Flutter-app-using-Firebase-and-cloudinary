import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/tool_model.dart';

class SeedService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Seed database with initial tools
  /// Run this once during app startup or manually
  Future<void> seedInitialTools() async {
    try {
      debugPrint('🌱 Starting database seeding...');
      // Check if tools already exist to avoid duplicates
      final snapshot = await _firestore.collection('tools').limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        debugPrint('📊 Database already seeded (${snapshot.docs.length} tools found). Skipping...');
        return;
      }

      debugPrint('📝 Creating ${10} new tools...');

      final dummyUserId = 'admin_user_${DateTime.now().millisecondsSinceEpoch}';

      final tools = [
        {
          'name': 'Power Drill',
          'category': 'powerTools',
          'pricePerDay': 500.0,
          'description': 'Heavy duty power drill, 20V battery. Perfect for all drilling needs.',
          'images': [],
          'ownerId': dummyUserId,
          'ownerName': 'ShareBox Admin',
          'ownerImage': null,
          'location': 'Dhaka',
          'isAvailable': true,
          'createdAt': Timestamp.now(),
          'rating': 4.5,
          'reviewCount': 12,
          'totalRentals': 24,
        },
        {
          'name': 'Circular Saw',
          'category': 'powerTools',
          'pricePerDay': 400.0,
          'description': 'Industrial circular saw for woodcutting. Blade included.',
          'images': [],
          'ownerId': dummyUserId,
          'ownerName': 'ShareBox Admin',
          'ownerImage': null,
          'location': 'Dhaka',
          'isAvailable': true,
          'createdAt': Timestamp.now(),
          'rating': 4.8,
          'reviewCount': 18,
          'totalRentals': 35,
        },
        {
          'name': 'Hammer Set',
          'category': 'handTools',
          'pricePerDay': 200.0,
          'description': 'Complete hammer set with 5 different sizes and carrying case.',
          'images': [],
          'ownerId': dummyUserId,
          'ownerName': 'ShareBox Admin',
          'ownerImage': null,
          'location': 'Gazipur',
          'isAvailable': true,
          'createdAt': Timestamp.now(),
          'rating': 4.3,
          'reviewCount': 8,
          'totalRentals': 16,
        },
        {
          'name': 'Wrench Set',
          'category': 'automotiveTools',
          'pricePerDay': 250.0,
          'description': 'Complete metric wrench set, 10-32mm. Perfect for automotive work.',
          'images': [],
          'ownerId': dummyUserId,
          'ownerName': 'ShareBox Admin',
          'ownerImage': null,
          'location': 'Narayanganj',
          'isAvailable': true,
          'createdAt': Timestamp.now(),
          'rating': 4.7,
          'reviewCount': 15,
          'totalRentals': 28,
        },
        {
          'name': 'Garden Shears',
          'category': 'gardenTools',
          'pricePerDay': 150.0,
          'description': 'High quality pruning shears. Great for garden maintenance.',
          'images': [],
          'ownerId': dummyUserId,
          'ownerName': 'ShareBox Admin',
          'ownerImage': null,
          'location': 'Dhaka',
          'isAvailable': true,
          'createdAt': Timestamp.now(),
          'rating': 4.4,
          'reviewCount': 10,
          'totalRentals': 20,
        },
        {
          'name': 'Ladder',
          'category': 'constructionTools',
          'pricePerDay': 300.0,
          'description': 'Aluminum 6-meter extension ladder. Heavy duty and lightweight.',
          'images': [],
          'ownerId': dummyUserId,
          'ownerName': 'ShareBox Admin',
          'ownerImage': null,
          'location': 'Chittagong',
          'isAvailable': true,
          'createdAt': Timestamp.now(),
          'rating': 4.6,
          'reviewCount': 20,
          'totalRentals': 42,
        },
        {
          'name': 'Welding Machine',
          'category': 'constructionTools',
          'pricePerDay': 1000.0,
          'description': '220V welding machine. Includes all necessary cables and electrodes.',
          'images': [],
          'ownerId': dummyUserId,
          'ownerName': 'ShareBox Admin',
          'ownerImage': null,
          'location': 'Gazipur',
          'isAvailable': true,
          'createdAt': Timestamp.now(),
          'rating': 4.9,
          'reviewCount': 25,
          'totalRentals': 50,
        },
        {
          'name': 'Shop Vacuum',
          'category': 'cleaningTools',
          'pricePerDay': 350.0,
          'description': '50L industrial vacuum cleaner. Wet and dry use.',
          'images': [],
          'ownerId': dummyUserId,
          'ownerName': 'ShareBox Admin',
          'ownerImage': null,
          'location': 'Savar',
          'isAvailable': true,
          'createdAt': Timestamp.now(),
          'rating': 4.5,
          'reviewCount': 12,
          'totalRentals': 22,
        },
        {
          'name': 'Electrical Tester',
          'category': 'electricalTools',
          'pricePerDay': 250.0,
          'description': 'Digital multimeter and voltage tester. Safe for all electrical testing.',
          'images': [],
          'ownerId': dummyUserId,
          'ownerName': 'ShareBox Admin',
          'ownerImage': null,
          'location': 'Dhaka',
          'isAvailable': true,
          'createdAt': Timestamp.now(),
          'rating': 4.7,
          'reviewCount': 14,
          'totalRentals': 26,
        },
        {
          'name': 'Pipe Wrench',
          'category': 'plumbingTools',
          'pricePerDay': 180.0,
          'description': 'Heavy duty pipe wrench 12-18 inches. Great for plumbing work.',
          'images': [],
          'ownerId': dummyUserId,
          'ownerName': 'ShareBox Admin',
          'ownerImage': null,
          'location': 'Narayanganj',
          'isAvailable': true,
          'createdAt': Timestamp.now(),
          'rating': 4.6,
          'reviewCount': 11,
          'totalRentals': 19,
        },
      ];

      // Add all tools to Firestore
      WriteBatch batch = _firestore.batch();
      for (final tool in tools) {
        final docRef = _firestore.collection('tools').doc();
        batch.set(docRef, tool);
      }

      await batch.commit();
      debugPrint('✅ Database seeded successfully with ${tools.length} tools');
    } catch (e) {
      debugPrint('❌ Error seeding database: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
    }
  }
}
