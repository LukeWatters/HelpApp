import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:testapp/services/database_services.dart';

class MyMap extends StatefulWidget {
  final name;
  MyMap({this.name});
  @override
  _MyMapState createState() => _MyMapState();
}

double lat = 0;
double long = 0;

class _MyMapState extends State<MyMap> {
  Set<Marker> _markers = {};
  bool _loading = false;
  getuserlocation() async {
    //hard coded for testing
    await FirebaseFirestore.instance
        .collection('Marked locations')
        .doc()
        .get()
        .then((value) {
      lat = double.parse(value.data()['Location'][0]);
      long = double.parse(value.data()['Location'][1]);
      print(lat);
      print(long);
      setState(() {
        _loading = false;
        _markers.add(Marker(
          infoWindow: InfoWindow(
            title: widget.name,
          ),
          markerId: MarkerId('<MARKER_ID>'),
          position: LatLng(lat, long),
        ));
      });
    });
  }

  @override
  void initState() {
    setState(() {
      _loading = true;
    });
    getuserlocation();
    DatabaseService().savelocation();
  }

  @override
  void setState(fn) {
    super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    var cp = CameraPosition(
      target: LatLng(lat, long),
      zoom: 20,
      tilt: 50,
    );
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.name ?? "Group users location"),
          backgroundColor: Colors.black87,
        ),
        body: _loading
            ? Center(child: CircularProgressIndicator())
            : Container(
                child: GoogleMap(
                mapType: MapType.hybrid,
                initialCameraPosition: cp,
                markers: _markers,
              )));
  }
}
