// ignore_for_file: unused_field

import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_maps/secrets.dart'; // Stores the Google Maps API Key
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'dart:math' show cos, sqrt, asin;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Storage Distance Calculator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MapView(),
    );
  }
}

/* 

  Main view

*/
class MainView extends StatefulWidget {
  const MainView({Key? key}) : super(key: key);

  @override
  _MainViewState createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          children: <Widget>[
            Container(
              height: 500,
              color: Colors.red,
              child: MapView(),
            ),
          ],
        ),
      ),
    );
  }
}

class Locations {
  //modal class for Person object
  String branch;
  double lat;
  double lng;

  Locations({required this.branch, required this.lat, required this.lng});

  @override
  String toString() {
    return 'Locations: {branch: ${branch}, lat: ${lat}, lng: ${lng}}';
  }

  String getBranch() {
    return this.branch;
  }

  double getLat() {
    return this.lat;
  }

  double getLng() {
    return this.lng;
  }
}

class Storage {
  String id;
  String name;
  double lat;
  double lag;

  Storage(
      {required this.id,
      required this.name,
      required this.lat,
      required this.lag});

  static List<Storage> getStorages() {
    return <Storage>[
      Storage(
          id: 'DC-LKB',
          name: 'คลังแห้งลาดกระบัง',
          lat: 13.72081,
          lag: 100.8280),
      Storage(
          id: 'CDC-LKB',
          name: 'คลังเย็นลาดกระบัง',
          lat: 13.72130,
          lag: 100.8260),
      Storage(
          id: 'BDC-RK',
          name: 'คลังขนมปังร่มเกล้า',
          lat: 13.74019,
          lag: 100.75926),
      Storage(
          id: 'EXTRA', name: 'คลังยาสำโรง', lat: 13.652528, lag: 100.592361),
      Storage(
          id: 'BDC-SR', name: 'คลังขนมปังสำโรง', lat: 13.65225, lag: 100.5922),
      Storage(
          id: 'BDC-CC', name: 'คลังขนมปังโชคชัย', lat: 13.79605, lag: 100.5676),
      Storage(id: 'LAZADA', name: 'คลังลาซาด้า', lat: 13.60062, lag: 100.5738),
      Storage(
          id: 'DC-BBT',
          name: 'คลังแห้งบางบัวทอง',
          lat: 13.97623,
          lag: 100.3947),
      Storage(
          id: 'CDC-BBT',
          name: 'คลังเย็นบางบัวทอง',
          lat: 13.97623,
          lag: 100.3947),
      Storage(
          id: 'DC-MHC', name: 'คลังแห้งมหาชัย', lat: 13.50824, lag: 100.1455),
      Storage(
          id: 'BDC-MHC',
          name: 'คลังขนมปังมหาชัย',
          lat: 13.50824,
          lag: 100.1455),
      Storage(
          id: 'BDC-SRT',
          name: 'คลังขนมปังสุราษฎร์',
          lat: 9.145243,
          lag: 99.31538),
      Storage(
          id: 'DC-SRT', name: 'คลังแห้งสุราษฎร์', lat: 9.145243, lag: 99.31538),
      Storage(
          id: 'DC-HDY', name: 'คลังแห้งหาดใหญ่', lat: 7.023897, lag: 100.3929),
    ];
  }
}

class MapView extends StatefulWidget {
  @override
  _MapViewState createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  // Seven list from json
  List _sevenItems = [];

  String storageSelected = "เลือกคลังสินค้า";

  List<Locations> _locationsList = [];
  String _locationString = "";

  List storageLists = [
    "เลือกคลังสินค้า",
    "คลังลาดกระบัง",
    "คลังขนมปังร่มเกล้า",
    "คลังสำโรง",
    "คลังขนมปังโชคชัย",
    "คลังบางบัวทอง",
    "คลังมหาชัย"
  ];

  List<Storage> _storages = Storage.getStorages();

  List<DropdownMenuItem<Storage>> _dropdownMenuItems = [];
  // Storage _selectedStorage;

  // Fetch content from the json file
  // Future<void> readStorageJson() async {
  //   final String response =
  //       await rootBundle.loadString('assets/storage_data.json');
  //   final data = await json.decode(response);
  //   setState(() {
  //     items = data["items"];
  //   });
  //   print('Info : Load Json success');
  // }

  CameraPosition _initialLocation =
      CameraPosition(target: LatLng(13.7563, 100.5018));

  late GoogleMapController mapController;

  late Position _currentPosition;
  String _currentAddress = '';

  final startAddressController = TextEditingController();
  final destinationAddressController = TextEditingController();

  final startAddressFocusNode = FocusNode();
  final desrinationAddressFocusNode = FocusNode();

  String _startAddress = '';
  String _destinationAddress = '';
  String? _placeDistance;

  Set<Marker> markers = {};
  Map<PolylineId, Polyline> polylines = {};

  final Set<Polyline> _polyline = {};

  List<LatLng> polylineCoordinates = [];

  late PolylinePoints polylinePoints;

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  Widget _textField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required double width,
    required Icon prefixIcon,
    Widget? suffixIcon,
    required Function(String) locationCallback,
  }) {
    return Container(
      width: width * 0.8,
      child: TextField(
        onChanged: (value) {
          locationCallback(value);
        },
        controller: controller,
        focusNode: focusNode,
        decoration: new InputDecoration(
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(10.0),
            ),
            borderSide: BorderSide(
              color: Colors.grey.shade400,
              width: 2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(10.0),
            ),
            borderSide: BorderSide(
              color: Colors.blue.shade300,
              width: 2,
            ),
          ),
          contentPadding: EdgeInsets.all(15),
          hintText: hint,
        ),
      ),
    );
  }

  // Method for retrieving the current location
  _getCurrentLocation() async {
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((Position position) async {
      setState(() {
        _currentPosition = position;
        print('CURRENT POS: $_currentPosition');
        mapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 18.0,
            ),
          ),
        );
      });
      await _getAddress();
    }).catchError((e) {
      print(e);
    });
  }

  // Method for retrieving the address
  _getAddress() async {
    try {
      List<Placemark> p = await placemarkFromCoordinates(
          _currentPosition.latitude, _currentPosition.longitude);

      Placemark place = p[0];

      setState(() {
        _currentAddress =
            "${place.name}, ${place.locality}, ${place.postalCode}, ${place.country}";
        startAddressController.text = _currentAddress;
        _startAddress = _currentAddress;
      });
    } catch (e) {
      print(e);
    }
  }

  bool _searchStorageLocation(String value) {
    var data = _storages.where((element) => value == (element.name.toString()));
    if (data.isEmpty) {
      // Not found!
      print('_storages Not found');
      return false;
    } else {
      // Found!
      print('_storages found');
      return true;
    }
  }

  getLatFromLocationStorage(String value) {
    var data =
        _storages.firstWhere((element) => value == (element.name.toString()));
    return data.lat;
  }

  getLagFromLocationStorage(String value) {
    var data =
        _storages.firstWhere((element) => value == (element.name.toString()));
    return data.lag;
  }

  getLatFromLocationSeven(String value) {
    var data = _sevenItems
        .firstWhere((element) => value == (element["id"].toString()));
    return data["lat"];
  }

  getLagFromLocationSeven(String value) {
    var data = _sevenItems
        .firstWhere((element) => value == (element["id"].toString()));
    return data["lng"];
  }

  // Fetch content from the json file
  Future<void> readJson() async {
    final String response =
        await rootBundle.loadString('assets/seven_all_data.json');
    final data = await json.decode(response);
    setState(() {
      _sevenItems = data["data"];
    });
    print('Info : Load Json success');
  }

  bool checkSevenString(String value) {
    var arr = value.split(" ");
    for (var i = 0; i < arr.length; i++) {
      // ถ้าตัวใดตัวหนึ่งเป็น false ให้ return false
      if (isSevenMatching(arr[i]) == false) {
        return false;
      }
    }
    return true;
  }

  // ignore: unused_element
  Future<bool> _generateListLocation() async {
    try {
      double totalDistance = 0.0;

      polylineCoordinates.clear();
      polylines.clear();
      markers.clear();
      _placeDistance = null;

      var latStorage = getLatFromLocationStorage(_startAddress);
      var lngStorage = getLagFromLocationStorage(_startAddress);

      double destinationLat = getLatFromLocationStorage(_startAddress);
      double destinationLng = getLagFromLocationStorage(_startAddress);

      String storageCoordinatesString = '($latStorage, $lngStorage)';

      // Add คลัง
      Marker storageMarker = Marker(
        markerId: MarkerId(storageCoordinatesString),
        position: LatLng(latStorage, lngStorage),
        infoWindow: InfoWindow(
          title: '$_startAddress',
          // snippet: 'Branch $branch',
        ),
        icon: BitmapDescriptor.defaultMarker,
      );

      markers.add(storageMarker);

      var sevenListBranch = _locationString.split(" ");
      for (var i = 0; i < sevenListBranch.length; i++) {
        var branch = sevenListBranch[i];
        var lat = getLatFromLocationSeven(sevenListBranch[i]);
        var lng = getLagFromLocationSeven(sevenListBranch[i]);

        _locationsList.add(Locations(branch: branch, lat: lat, lng: lng));

        String coordinatesString = '($lat, $lng)';

        Marker locationMarker = Marker(
          markerId: MarkerId(coordinatesString),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(
            title: 'รหัสสาขา $branch',
            // snippet: 'Branch $branch',
          ),
          icon: BitmapDescriptor.defaultMarker,
        );

        markers.add(locationMarker);

        // มากกว่า 1 สาขา
        if (i < sevenListBranch.length - 1) {
          // สร้างจากคลังไปสาขาแรก
          if (i == 0) {
            await _createPolylines(latStorage, lngStorage, lat, lng, 0);
            print('poly leng start ' + polylineCoordinates.length.toString());
          }
          destinationLat = getLatFromLocationSeven(sevenListBranch[i + 1]);
          destinationLng = getLagFromLocationSeven(sevenListBranch[i + 1]);

          // สร้างระหว่างทาง
          await _createPolylines(lat, lng, destinationLat, destinationLng, 1);
          print('poly leng ' + polylineCoordinates.length.toString());

          // จากสาขาสุดท้ายกลับคลัง
          if (i == sevenListBranch.length - 2) {
            await _createPolylines(
                destinationLat, destinationLng, latStorage, lngStorage, 2);
            print('poly leng des ' + polylineCoordinates.length.toString());

            // Calculating the total distance by adding the distance
            // between small segments
            for (int i = 0; i < polylineCoordinates.length - 1; i++) {
              totalDistance += _coordinateDistance(
                polylineCoordinates[i].latitude,
                polylineCoordinates[i].longitude,
                polylineCoordinates[i + 1].latitude,
                polylineCoordinates[i + 1].longitude,
              );
            }

            print('Distance ' + totalDistance.toString());

            setState(() {
              _placeDistance = totalDistance.toStringAsFixed(2);
              print('DISTANCE: $_placeDistance km');
            });
          }
        }
        // มีสาขาเดียว
        else if (sevenListBranch.length == 1) {
          await _createPolylines(lat, lng, latStorage, lngStorage, 2);
          await _createPolylines(latStorage, lngStorage, lat, lng, 2);

          // Calculating the total distance by adding the distance
          // between small segments
          for (int i = 0; i < polylineCoordinates.length - 1; i++) {
            totalDistance += _coordinateDistance(
              polylineCoordinates[i].latitude,
              polylineCoordinates[i].longitude,
              polylineCoordinates[i + 1].latitude,
              polylineCoordinates[i + 1].longitude,
            );
          }

          print('Distance ' + totalDistance.toString());

          setState(() {
            _placeDistance = totalDistance.toStringAsFixed(2);
            print('DISTANCE: $_placeDistance km');
          });
        }
      }
      double startLatitude = _startAddress == _currentAddress
          ? _currentPosition.latitude
          : getLatFromLocationStorage(_startAddress);

      double startLongitude = _startAddress == _currentAddress
          ? _currentPosition.longitude
          : getLagFromLocationStorage(_startAddress);

      double destinationLatitude = destinationLat;
      double destinationLongitude = destinationLng;

      // Calculating to check that the position relative
      // to the frame, and pan & zoom the camera accordingly.
      double miny = (startLatitude <= destinationLatitude)
          ? startLatitude
          : destinationLatitude;
      double minx = (startLongitude <= destinationLongitude)
          ? startLongitude
          : destinationLongitude;
      double maxy = (startLatitude <= destinationLatitude)
          ? destinationLatitude
          : startLatitude;
      double maxx = (startLongitude <= destinationLongitude)
          ? destinationLongitude
          : startLongitude;

      double southWestLatitude = miny;
      double southWestLongitude = minx;

      double northEastLatitude = maxy;
      double northEastLongitude = maxx;

      // Accommodate the two locations within the
      // camera view of the map
      mapController.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            northeast: LatLng(northEastLatitude, northEastLongitude),
            southwest: LatLng(southWestLatitude, southWestLongitude),
          ),
          100.0,
        ),
      );

      return true;
    } catch (e) {
      print(e);
    }
    return false;
  }

  // if every string match in list
  // return true and unlock find route
  // if not
  // return false and show error message
  bool isSevenMatching(String value) {
    // var arr = value.split(value);
    // var data = "";
    // var num = arr.length;
    // for (var i = 0; i <= num; i++) {
    //   data = arr.where((element) => value == (element["id"].toString()));
    // }

    var data =
        _sevenItems.where((element) => value == (element["id"].toString()));
    if (data.isEmpty) {
      // Not found!
      print('_sevenItems $value not found');
      return false;
    } else {
      // Found!
      print('_sevenItems $value found');
      return true;
    }
  }

  // ignore: unused_element
  _createListLocation() {
    // แยก array ยัดลง list
  }

  // Method for calculating the distance between two places
  Future<bool> _calculateDistance() async {
    try {
      // Retrieving placemarks from addresses
      // List<Location> startPlacemark = await locationFromAddress(_startAddress);
      // List<Location> destinationPlacemark =
      //     await locationFromAddress(_destinationAddress);

      // Use the retrieved coordinates of the current position,
      // instead of the address if the start position is user's
      // current position, as it results in better accuracy.
      // double startLatitude = _startAddress == _currentAddress
      //     ? _currentPosition.latitude
      //     : startPlacemark[0].latitude;

      // double startLongitude = _startAddress == _currentAddress
      //     ? _currentPosition.longitude
      //     : startPlacemark[0].longitude;

      double startLatitude = _startAddress == _currentAddress
          ? _currentPosition.latitude
          : getLatFromLocationStorage(_startAddress);

      double startLongitude = _startAddress == _currentAddress
          ? _currentPosition.longitude
          : getLagFromLocationStorage(_startAddress);

      double destinationLatitude = getLatFromLocationSeven(_destinationAddress);
      double destinationLongitude =
          getLagFromLocationSeven(_destinationAddress);

      String startCoordinatesString = '($startLatitude, $startLongitude)';
      String destinationCoordinatesString =
          '($destinationLatitude, $destinationLongitude)';

      // Start Location Marker
      Marker startMarker = Marker(
        markerId: MarkerId(startCoordinatesString),
        position: LatLng(startLatitude, startLongitude),
        infoWindow: InfoWindow(
          title: 'Start $startCoordinatesString',
          snippet: _startAddress,
        ),
        icon: BitmapDescriptor.defaultMarker,
      );

      // Destination Location Marker
      Marker destinationMarker = Marker(
        markerId: MarkerId(destinationCoordinatesString),
        position: LatLng(destinationLatitude, destinationLongitude),
        infoWindow: InfoWindow(
          title: 'Destination $destinationCoordinatesString',
          snippet: _destinationAddress,
        ),
        icon: BitmapDescriptor.defaultMarker,
      );

      // Adding the markers to the list
      markers.add(startMarker);
      markers.add(destinationMarker);

      print(
        'START COORDINATES: ($startLatitude, $startLongitude)',
      );
      print(
        'DESTINATION COORDINATES: ($destinationLatitude, $destinationLongitude)',
      );

      // Calculating to check that the position relative
      // to the frame, and pan & zoom the camera accordingly.
      double miny = (startLatitude <= destinationLatitude)
          ? startLatitude
          : destinationLatitude;
      double minx = (startLongitude <= destinationLongitude)
          ? startLongitude
          : destinationLongitude;
      double maxy = (startLatitude <= destinationLatitude)
          ? destinationLatitude
          : startLatitude;
      double maxx = (startLongitude <= destinationLongitude)
          ? destinationLongitude
          : startLongitude;

      double southWestLatitude = miny;
      double southWestLongitude = minx;

      double northEastLatitude = maxy;
      double northEastLongitude = maxx;

      // Accommodate the two locations within the
      // camera view of the map
      mapController.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            northeast: LatLng(northEastLatitude, northEastLongitude),
            southwest: LatLng(southWestLatitude, southWestLongitude),
          ),
          50.0,
        ),
      );

      // Calculating the distance between the start and the end positions
      // with a straight path, without considering any route
      // double distanceInMeters = await Geolocator.bearingBetween(
      //   startLatitude,
      //   startLongitude,
      //   destinationLatitude,
      //   destinationLongitude,
      // );

      await _createPolylines(startLatitude, startLongitude, destinationLatitude,
          destinationLongitude, 1);

      double totalDistance = 0.0;

      // Calculating the total distance by adding the distance
      // between small segments
      for (int i = 0; i < polylineCoordinates.length - 1; i++) {
        totalDistance += _coordinateDistance(
          polylineCoordinates[i].latitude,
          polylineCoordinates[i].longitude,
          polylineCoordinates[i + 1].latitude,
          polylineCoordinates[i + 1].longitude,
        );
      }

      setState(() {
        _placeDistance = totalDistance.toStringAsFixed(2);
        print('DISTANCE: $_placeDistance km');
      });

      return true;
    } catch (e) {
      print(e);
    }
    return false;
  }

  // Formula for calculating distance between two coordinates
  // https://stackoverflow.com/a/54138876/11910277
  double _coordinateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  // Create the polylines for showing the route between two places
  _createPolylines(
      double startLatitude,
      double startLongitude,
      double destinationLatitude,
      double destinationLongitude,
      int colorCode) async {
    polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      Secrets.API_KEY, // Google Maps API Key
      PointLatLng(startLatitude, startLongitude),
      PointLatLng(destinationLatitude, destinationLongitude),
      travelMode: TravelMode.driving,
    );
    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    }
    PolylineId id = PolylineId('poly');
    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.red,
      points: polylineCoordinates,
      width: 3,
    );
    polylines[id] = polyline;
  }

  @override
  void initState() {
    // _dropdownMenuItems = buildDropdownMenuItems(_storages);
    // storageSelected = _dropdownMenuItems[0];
    super.initState();
    _getCurrentLocation();
    readJson();
  }

  // List<DropdownMenuItem<Storage>> buildDropdownMenuItems(List storages) {
  //   List<DropdownMenuItem<Storage>> items = [];
  //   for (Storage storage in storages) {
  //     items.add(
  //       DropdownMenuItem(
  //         value: storage,
  //         child: Text(storage.name),
  //       ),
  //     );
  //   }
  //   return items;
  // }

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    return Container(
      height: height,
      width: width,
      child: Scaffold(
        key: _scaffoldKey,
        body: Stack(
          children: <Widget>[
            // Map View
            GoogleMap(
              markers: Set<Marker>.from(markers),
              initialCameraPosition: _initialLocation,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              mapType: MapType.normal,
              zoomGesturesEnabled: true,
              zoomControlsEnabled: false,
              polylines: Set<Polyline>.of(polylines.values),
              onMapCreated: (GoogleMapController controller) {
                mapController = controller;
              },
            ),
            // Show zoom buttons
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 10.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    ClipOval(
                      child: Material(
                        color: Colors.blue.shade100, // button color
                        child: InkWell(
                          splashColor: Colors.blue, // inkwell color
                          child: SizedBox(
                            width: 50,
                            height: 50,
                            child: Icon(Icons.add),
                          ),
                          onTap: () {
                            mapController.animateCamera(
                              CameraUpdate.zoomIn(),
                            );
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    ClipOval(
                      child: Material(
                        color: Colors.blue.shade100, // button color
                        child: InkWell(
                          splashColor: Colors.blue, // inkwell color
                          child: SizedBox(
                            width: 50,
                            height: 50,
                            child: Icon(Icons.remove),
                          ),
                          onTap: () {
                            mapController.animateCamera(
                              CameraUpdate.zoomOut(),
                            );
                          },
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
            // Show the place input fields & button for
            // showing the route
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white70,
                      borderRadius: BorderRadius.all(
                        Radius.circular(20.0),
                      ),
                    ),
                    width: width * 0.9,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          DropdownButton(
                            value: storageSelected,
                            onChanged: (newValue) {
                              setState(() {
                                storageSelected = newValue as String;

                                if (storageSelected != 'เลือกคลังสินค้า') {
                                  if (_searchStorageLocation(storageSelected))
                                    // _startAddress = _currentAddress;
                                    _startAddress = newValue;
                                  // readJson();
                                }
                                // startAddressController.text = _currentAddress;
                              });
                            },
                            items: storageLists.map((valueItem) {
                              return DropdownMenuItem(
                                  value: valueItem, child: Text(valueItem));
                            }).toList(),
                          ),
                          // SizedBox(height: 10),
                          // _textField(
                          //     label: 'เลือกคลังสินค้า',
                          //     hint: 'Choose starting point',
                          //     prefixIcon: Icon(Icons.looks_one),
                          //     suffixIcon: IconButton(
                          //       icon: Icon(Icons.my_location),
                          //       onPressed: () {
                          //         startAddressController.text = _currentAddress;
                          //         _startAddress = _currentAddress;
                          //       },
                          //     ),
                          //     controller: startAddressController,
                          //     focusNode: startAddressFocusNode,
                          //     width: width,
                          //     locationCallback: (String value) {
                          //       setState(() {
                          //         _startAddress = value;
                          //       });
                          //     }),
                          SizedBox(height: 10),
                          _textField(
                              label: 'ป้อนรหัสสาขาเซเว่น',
                              hint: 'เช่น 00000 00001',
                              prefixIcon: Icon(Icons.looks_two),
                              controller: destinationAddressController,
                              focusNode: desrinationAddressFocusNode,
                              width: width,
                              locationCallback: (String value) {
                                setState(() {
                                  if (checkSevenString(value)) {
                                    _destinationAddress = value;
                                    _locationString = value;
                                  } else {
                                    _destinationAddress = '';
                                    _locationString = '';
                                    // polylines.clear();
                                    // _placeDistance = null;
                                    // markers.clear();
                                    // polylineCoordinates.clear();
                                  }
                                  // if (isSevenMatching(value)) {
                                  //   _destinationAddress = value;
                                  //   _locationString = value;
                                  // }
                                });
                              }),
                          SizedBox(height: 10),
                          Visibility(
                            visible: _placeDistance == null ? false : true,
                            child: Text(
                              'ระยะทางทั้งหมด: $_placeDistance กิโลเมตร',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(height: 5),
                          ElevatedButton(
                            onPressed: (_locationString != '' &&
                                    storageSelected != 'เลือกคลังสินค้า')
                                // onPressed: (_startAddress != '' &&
                                //         _destinationAddress != '')
                                ? () async {
                                    startAddressFocusNode.unfocus();
                                    desrinationAddressFocusNode.unfocus();
                                    setState(() {
                                      if (markers.isNotEmpty) markers.clear();
                                      if (polylines.isNotEmpty)
                                        polylines.clear();
                                      if (polylineCoordinates.isNotEmpty)
                                        polylineCoordinates.clear();
                                      _placeDistance = null;
                                    });
                                    _generateListLocation()
                                        .then((isCalculated) {
                                      if (isCalculated) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content:
                                                Text('คำนวนระยะทางสำเร็จแล้ว'),
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'เกิดข้อผิดพลาด คำนวนระยะทางล้มเหลว'),
                                          ),
                                        );
                                      }
                                    });
                                    _locationsList.clear();
                                  }
                                : null,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'คำนวนระยะทาง'.toUpperCase(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20.0,
                                ),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              primary: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Show current location button
            SafeArea(
              child: Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 10.0, bottom: 10.0),
                  child: ClipOval(
                    child: Material(
                      color: Colors.orange.shade100, // button color
                      child: InkWell(
                        splashColor: Colors.orange, // inkwell color
                        child: SizedBox(
                          width: 56,
                          height: 56,
                          child: Icon(Icons.my_location),
                        ),
                        onTap: () {
                          mapController.animateCamera(
                            CameraUpdate.newCameraPosition(
                              CameraPosition(
                                target: LatLng(
                                  _currentPosition.latitude,
                                  _currentPosition.longitude,
                                ),
                                zoom: 18.0,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
