// lib/services/firebase_service.dart

import 'package:firebase_database/firebase_database.dart';

class FirebaseService {
  final DatabaseReference _dbRef =
      FirebaseDatabase.instance.ref('testCollection');

  // Method to add data to Realtime Database
  Future<void> addData() async {
    try {
      await _dbRef.push().set({
        'name': 'New Item',
        'description': 'This is a new item.',
        'createdAt': ServerValue.timestamp,
      });
      print("Data added successfully");
    } catch (e) {
      print("Error adding data: $e");
    }
  }

  // Method to get data from Realtime Database
  Future<List<Map<String, dynamic>>> getData() async {
    try {
      final snapshot = await _dbRef.get();
      if (snapshot.exists) {
        Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
        List<Map<String, dynamic>> dataList = [];
        data.forEach((key, value) {
          dataList.add(Map<String, dynamic>.from(value));
        });
        return dataList;
      } else {
        return [];
      }
    } catch (e) {
      print("Error retrieving data: $e");
      return [];
    }
  }
}
