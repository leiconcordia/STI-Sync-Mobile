import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:sti_sync/firebase_options.dart';

void main() {
  testWidgets('debug firestore', (WidgetTester tester) async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    
    final courses = await FirebaseFirestore.instance.collection('courses').get();
    for (var c in courses.docs) {
      print('COURSE: ${c.id} -> ${c.data()}');
    }
    
    final sections = await FirebaseFirestore.instance.collection('sections').get();
    for (var s in sections.docs) {
      print('SECTION: ${s.id} -> ${s.data()}');
    }
    
    final sems = await FirebaseFirestore.instance.collection('semesters').get();
    for (var s in sems.docs) {
      print('SEMESTER: ${s.id} -> ${s.data()}');
    }

    final depts = await FirebaseFirestore.instance.collection('departments').get();
    for (var d in depts.docs) {
      print('DEPARTMENT: ${d.id} -> ${d.data()}');
    }
  });
}
