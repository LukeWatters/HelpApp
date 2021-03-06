import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart' as geo;

class DatabaseService {
  final String uid;
  final String groupId;
  DatabaseService({this.uid, this.groupId});

  // Collection reference
  final CollectionReference userCollection =
      FirebaseFirestore.instance.collection('users');
  final CollectionReference groupCollection =
      FirebaseFirestore.instance.collection('groups');
  FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // update userdata
  Future updateUserData(String fullName, String email, String password) async {
    String token = await _messaging.getToken();
    return await userCollection.doc(uid).set({
      'fullName': fullName,
      'email': email,
      'password': password,
      'groups': [],
      'profilePic': '',
      'token': token,
      "active group": ''
    });
  }

  // create group
  Future createGroup(String userName, String groupName) async {
    String token = await _messaging.getToken();
    DocumentReference groupDocRef = await groupCollection.add({
      'groupName': groupName,
      'groupIcon': '',
      'admin': userName,
      'members': [],
      'tokens': [],
      'groupId': '',
      'recentMessage': '',
      'recentMessageSender': ''
    });
    await groupDocRef.update({
      'members': FieldValue.arrayUnion([uid + '__' + userName]),
      'groupId': groupDocRef.id,
    });

    DocumentReference userDocRef = userCollection.doc(uid);
    await userDocRef.update({
      'groups': FieldValue.arrayUnion([groupDocRef.id + '_' + groupName])
    });

    return await groupDocRef.update({
      'tokens': FieldValue.arrayUnion([token])
    });
  }

  // toggling the user group join
  Future togglingGroupJoin(
      String groupId, String groupName, String userName) async {
    DocumentReference userDocRef = userCollection.doc(uid);
    DocumentSnapshot userDocSnapshot = await userDocRef.get();
    String token = await _messaging.getToken();

    DocumentReference groupDocRef = groupCollection.doc(groupId);

    List<dynamic> groups = await userDocSnapshot.get(FieldPath(['groups']));

    if (groups.contains(groupId + '_' + groupName)) {
      //print('hey');
      await userDocRef.update({
        'groups': FieldValue.arrayRemove([groupId + '_' + groupName])
      });

      await groupDocRef.update({
        'members': FieldValue.arrayRemove([uid + '_' + userName])
      });
    } else {
      //print('nay');
      await userDocRef.update({
        'groups': FieldValue.arrayUnion([groupId + '_' + groupName])
      });

      await groupDocRef.update({
        'members': FieldValue.arrayUnion([uid + '_' + userName])
      });

      await groupDocRef.update({
        'tokens': FieldValue.arrayUnion([token])
      });
    }
  }

  // has user joined the group
  Future<bool> isUserJoined(
      String groupId, String groupName, String userName) async {
    DocumentReference userDocRef = userCollection.doc(uid);
    DocumentSnapshot userDocSnapshot = await userDocRef.get();

    List<dynamic> groups = await userDocSnapshot.get(FieldPath(['groups']));

    if (groups.contains(groupId + '_' + groupName)) {
      //print('he');
      return true;
    } else {
      //print('ne');
      return false;
    }
  }

  // get user location
  double lat;
  double longi;
  List<String> mylocation;
  Future savelocation(String userName) async {
    geo.Position position = await geo.Geolocator.getCurrentPosition(
        desiredAccuracy: geo.LocationAccuracy.bestForNavigation);
    lat = position.latitude;
    longi = position.longitude;
    mylocation = [lat.toString(), longi.toString()];
    setlocation(mylocation, userName);
  }

//save user location in firestore
  setlocation(List coords, String userName) {
    Map<String, dynamic> locationmap = {
      "Location": coords,
      "isSafe": true,
      "user": groupId,
      "UserID": userName
    };

    FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('user locations')
        .add(locationmap);
  }

  // save flagged locations to marked location collection
  storelocation(String userName) async {
    geo.Position position = await geo.Geolocator.getCurrentPosition(
        desiredAccuracy: geo.LocationAccuracy.high);
    lat = position.latitude;
    longi = position.longitude;
    mylocation = [lat.toString(), longi.toString()];
    storelocationToDb(mylocation, userName);
  }

  storelocationToDb(List mylocation, String userName) {
    Map<String, dynamic> markedlocationmap = {
      "Location": mylocation,
      "Time": DateTime.now(),
      "User": userName
    };
// Saves to the marked locations collection in DB
    FirebaseFirestore.instance
        .collection("Marked locations")
        .doc("$userName's" + " marked locations")
        .set(markedlocationmap);
  }

  // get user data
  Future getUserData(String email) async {
    QuerySnapshot snapshot =
        await userCollection.where('email', isEqualTo: email).get();
    print(snapshot.docs[0].data);
    return snapshot;
  }

  // get user groups
  getUserGroups() async {
    return FirebaseFirestore.instance.collection("users").doc(uid).snapshots();
  }

  // send message
  sendMessage(String groupId, chatMessageData) {
    FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .add(chatMessageData);
    FirebaseFirestore.instance.collection('groups').doc(groupId).update({
      'recentMessage': chatMessageData['message'],
      'recentMessageSender': chatMessageData['sender'],
      'recentMessageTime': chatMessageData['time'].toString(),
    });
  }

  // get chats of a particular group
  getChats(String groupId) async {
    return FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .orderBy('time')
        .snapshots();
  }

  // search groups
  searchByName(String groupName) {
    return FirebaseFirestore.instance
        .collection("groups")
        .where('groupName', isEqualTo: groupName)
        .get();
  }

  searchByUserName(String userName) {
    return FirebaseFirestore.instance
        .collection("users")
        .where('fullName', isEqualTo: userName)
        .get();
  }

  raiseAlert(String userName) {
    FirebaseFirestore.instance
        .collection("live location updates")
        .doc("$userName " + "location")
        .collection("Is Safe")
        .add({"isSafe": false});
    // .set({"isSafe": false}, SetOptions(merge: true));
  }
}
