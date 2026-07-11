import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:sti_sync/firebase_options.dart';
import 'package:sti_sync/features/scanner/models/scanner_assignment_model.dart';
import 'package:sti_sync/core/local/app_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() {
  testWidgets('debug scanner assignments', (WidgetTester tester) async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    
    // Attempt to log in or use current user
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;
    print('CURRENT USER: ${user?.uid}');
    final officerUserId = user?.uid ?? 'XNfS2SssTMT0UqX5e0dIfbL6MvM2'; // Fallback to a known user if null

    print('Fetching events for user $officerUserId...');
    final snapshot = await FirebaseFirestore.instance
        .collection('events')
        .where('scannerUserIds', arrayContains: officerUserId)
        .get();
        
    print('Found ${snapshot.docs.length} events');
    for (var doc in snapshot.docs) {
      print('EVENT ${doc.id}:');
      try {
        final model = ScannerAssignmentModel.fromEventDoc(doc, officerUserId);
        print(' - Title: ${model.eventTitle}');
        print(' - isActive: ${model.isActive}');
        print(' - canScan: ${model.canScan}');
        print(' - sessions count: ${model.sessions.length}');
        print(' - proposalStatus: ${model.proposalStatus}');
      } catch (e, st) {
        print(' - ERROR PARSING: $e\n$st');
      }
    }
    
    // Check local database
    print('\nChecking local database...');
    final db = AppDatabase();
    try {
      final localAssignments = await db.scannerDao.getAllAssignments();
      print('Found ${localAssignments.length} local assignments');
      for (var local in localAssignments) {
        try {
          final model = ScannerAssignmentModel.fromDrift(local);
          print(' - LOCAL EVENT: ${model.eventId}, sessions: ${model.sessions.length}');
        } catch (e, st) {
          print(' - LOCAL PARSE ERROR for ${local.eventId}: $e\n$st');
        }
      }
    } catch (e, st) {
      print('LOCAL DB ERROR: $e\n$st');
    }
  });
}
