import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String token;

  UserModel({
    this.uid,
    this.name,
    this.email,
    this.token,
  });

  factory UserModel.fromDoc(DocumentSnapshot doc) {
    return UserModel(
      uid: doc.id,
      name: doc['name'],
      email: doc['email'],
      token: doc['token'],
    );
  }
}
