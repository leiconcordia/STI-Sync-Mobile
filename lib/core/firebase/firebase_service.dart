import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for FirebaseFirestore instance
final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

/// Provider for FirebaseAuth instance
final authProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

/// Provider for FirebaseStorage instance
final storageProvider = Provider<FirebaseStorage>((ref) => FirebaseStorage.instance);
