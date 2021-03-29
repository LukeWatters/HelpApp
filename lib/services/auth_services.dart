import 'package:firebase_auth/firebase_auth.dart';
import 'package:testapp/helper/helperfunction.dart';
import 'package:testapp/models/users.dart';

import 'database_services.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // create user object based on FirebaseUser
  UserModel _userFromFirebaseUser(User user) {
    if (user != null) {
      return UserModel(
        uid: user.uid,
      );
    } else {
      return null;
    }
  }

  Stream<User> get user => _auth.authStateChanges();

  // sign in with email and password
  Future signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      User user = result.user;
      return _userFromFirebaseUser(user);
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // register with email and password
  Future registerWithEmailAndPassword(
      String fullName, String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      User user = result.user;

      // Create a new document for the user with uid
      await DatabaseService(uid: user.uid)
          .updateUserData(fullName, email, password);
      return _userFromFirebaseUser(user);
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future resetPass(String email) async {
    try {
      return await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print(e.toString());
    }
  }

  //sign out
  Future signOut() async {
    try {
      await HelperFunction.saveuserLoggedInSharedPreference(false);
      await HelperFunction.saveuserEmailSharedPreference('');
      await HelperFunction.saveuserNameSharedPreference('');

      return await _auth.signOut().whenComplete(() async {
        print("Logged out");
        await HelperFunction.getuserLoggedInSharedPreference().then((value) {
          print("Logged in: $value");
        });
        await HelperFunction.getuserEmailSharedPreference().then((value) {
          print("Email: $value");
        });
        await HelperFunction.getuserNameSharedPreference().then((value) {
          print("Full Name: $value");
        });
      });
    } catch (e) {
      print(e.toString());
      return null;
    }
  }
}
