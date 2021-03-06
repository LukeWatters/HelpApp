import 'dart:async';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:testapp/helper/helperfunction.dart';
import 'package:testapp/screens/homepage.dart';
import 'package:testapp/services/database_services.dart';

class MapExample extends StatefulWidget {
  @override
  _MyMapExample createState() => _MyMapExample();
}

class _MyMapExample extends State<MapExample> {
  StreamSubscription _locationSubscription;
  Location _locationTracker = Location();
  Marker marker;
  Circle circle;
  final Set<Marker> _markers = {};
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  GoogleMapController _controller;
  FirebaseMessaging _fcm = FirebaseMessaging.instance;

  DatabaseService databasemethods = new DatabaseService();
  // data

  User _user;
  String _userName = '';
  String uid;
  String groupId;
  Stream _groups;

  @override
  void initState() {
    super.initState();
    _getUserAuthAndJoinedGroups();
  }

  static final CameraPosition initialLocation = CameraPosition(
    target: LatLng(53.3498, 6.2603),
    zoom: 14.4746,
  );

  _MyMapExample();

  Future<Uint8List> getMarker() async {
    ByteData byteData =
        await DefaultAssetBundle.of(context).load("assets/pin.png");
    return byteData.buffer.asUint8List();
  }

  void updateMarkerAndCircle(LocationData newLocalData, Uint8List imageData) {
    LatLng latlng = LatLng(newLocalData.latitude, newLocalData.longitude);
    this.setState(() {
      marker = Marker(
          markerId: MarkerId("home"),
          position: latlng,
          rotation: newLocalData.heading,
          draggable: false,
          zIndex: 2,
          flat: true,
          anchor: Offset(0.5, 0.5),
          icon: BitmapDescriptor.fromBytes(imageData));
      circle = Circle(
          circleId: CircleId("car"),
          radius: newLocalData.accuracy,
          zIndex: 1,
          strokeColor: Colors.blue,
          center: latlng,
          fillColor: Colors.blue.withAlpha(70));
    });
  }

  void getCurrentLocation() async {
    try {
      Uint8List imageData = await getMarker();
      var location = await _locationTracker.getLocation();

      updateMarkerAndCircle(location, imageData);

      if (_locationSubscription != null) {
        _locationSubscription.cancel();
      }

      _locationSubscription =
          _locationTracker.onLocationChanged.listen((newLocalData) {
        if (_controller != null) {
          _controller.animateCamera(CameraUpdate.newCameraPosition(
              new CameraPosition(
                  bearing: 192.8334901395799,
                  target: LatLng(newLocalData.latitude, newLocalData.longitude),
                  tilt: 0,
                  zoom: 18.00)));
          updateMarkerAndCircle(newLocalData, imageData);
          _savelocation(newLocalData);
        }
      });
    } on PlatformException catch (e) {
      if (e.code == 'PERMISSION_DENIED') {
        debugPrint("Permission Denied");
      }
    }
  }

  @override
  void dispose() {
    if (_locationSubscription != null) {
      _locationSubscription.cancel();
    }
    super.dispose();
  }

  _getUserAuthAndJoinedGroups() async {
    _user = await FirebaseAuth.instance.currentUser;
    await HelperFunction.getuserNameSharedPreference().then((value) {
      setState(() {
        _userName = value;
      });
    });
    DatabaseService(uid: _user.uid).getUserGroups().then((snapshots) {
      // print(snapshots);
      setState(() {
        _groups = snapshots;
      });
    });
  }

  double lat;
  double longi;
  List<String> mylocation;
  _savelocation(newLocalData) {
    lat = newLocalData.latitude;
    longi = newLocalData.longitude;
    mylocation = [lat.toString(), longi.toString()];
    setlocation(mylocation);
  }

  //save user location in firestore
  setlocation(List coords) {
    Map<String, dynamic> locationmap = {
      "Location": coords,
      "Username": _userName,
      "Time": DateTime.now(),
    };

    FirebaseFirestore.instance
        .collection('live location updates')
        .doc("user locations")
        .set(locationmap);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          elevation: 0.0,
          backgroundColor: Colors.black87,
          centerTitle: true,
          title: Text('Map View',
              style: TextStyle(
                  fontSize: 27.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          actions: [
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                    ),
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) => HomePage()));
                    }),
              ],
            )
          ]),
      body: GoogleMap(
        mapType: MapType.hybrid,
        initialCameraPosition: initialLocation,
        markers: Set.of((marker != null) ? [marker] : []),
        circles: Set.of((circle != null) ? [circle] : []),
        onMapCreated: (GoogleMapController controller) {
          _controller = controller;
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            FloatingActionButton(
              child: Icon(Icons.location_searching),
              onPressed: () {
                getCurrentLocation();
              },
            ),
            FloatingActionButton(
              backgroundColor: Colors.amber,
              child: Icon(Icons.pin_drop),
              onPressed: () {
                DatabaseService().storelocation(_userName);
                print("location marked!");
              },
            ),
            FloatingActionButton(
              backgroundColor: Colors.red,
              child: Icon(Icons.warning_sharp),
              onPressed: () {
                DatabaseService().raiseAlert(_userName);
                print("alert activated");
              },
            )
          ],
        ),
      ),
    );
  }
}
