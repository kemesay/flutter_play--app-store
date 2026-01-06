import 'dart:async';
import 'package:oda_black_car_service/model/card_model.dart';
import 'package:oda_black_car_service/model/place_model.dart';
import 'package:oda_black_car_service/model/ride_option_model.dart';
import 'package:oda_black_car_service/ui/widgets/drawer_widget.dart';
import 'package:oda_black_car_service/utils/constants.dart';
import 'package:oda_black_car_service/utils/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:uuid/uuid.dart';

class BookTaxiPage extends StatefulWidget {
  static const routeName = "book-taxi-page";

  const BookTaxiPage({super.key});

  @override
  _BookTaxiPageState createState() => _BookTaxiPageState();
}

class _BookTaxiPageState extends State<BookTaxiPage> {
  late LatLng myLocation;
  final Set<Marker> _markers = {};
  late String _mapStyle;
  late BitmapDescriptor _taxilocation;
  late BitmapDescriptor _mylocation;
  late BitmapDescriptor _mydestination;
  final Completer<GoogleMapController> _controller = Completer();
  bool isMapCreated = false;
  final Key _mapKey = UniqueKey();
  int _selectedIndex = -1;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _fromLocationController = TextEditingController();
  final TextEditingController _toLocationController = TextEditingController();
  var uuid = const Uuid();
  var sessionToken;
  var googleMapServices;
  late PlaceDetail _fromPlaceDetail;
  late PlaceDetail _toPlaceDetail;
  Set<Polyline> _polylines = {};
  List<LatLng> polylineCoordinates = [];
  PolylinePoints polylinePoints = PolylinePoints(apiKey: Constatnts.API_KEY);
  bool _hasGottenCordinates = false;
  late LatLngBounds bound;

  final List<UserCardModel> _cards = [
    UserCardModel(
        id: "1",
        imageUrl: 'assets/images/img_visa_logo.png',
        cardNumber: "**** **** **** 5687"),
    UserCardModel(
        id: "2",
        imageUrl: 'assets/images/img_visa_logo.png',
        cardNumber: "**** **** **** 9987"),
    UserCardModel(
        id: "3",
        imageUrl: 'assets/images/img_visa_logo.png',
        cardNumber: "**** **** **** 7879")
  ];

  List<RideOptionModel> ridesOptions = [
    RideOptionModel(
        id: "1",
        price: 9.90,
        estimatedTime: "5 MIN",
        rideType: "Standard",
        index: 0,
        imageUrl: "assets/images/standard.png"),
    RideOptionModel(
        id: "2",
        price: 10.90,
        index: 1,
        estimatedTime: "6 MIN",
        rideType: "Comfort",
        imageUrl: "assets/images/comfort.png"),
    RideOptionModel(
        id: "3",
        price: 49.90,
        index: 2,
        estimatedTime: "5 MIN",
        rideType: "Luxury",
        imageUrl: "assets/images/luxury.png"),
  ];

  late UserCardModel _selectedalvalue;
  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    BitmapDescriptor.asset(const ImageConfiguration(devicePixelRatio: 2.5),
            'assets/images/taxi.png')
        .then((onValue) {
      _taxilocation = onValue;
    });

    BitmapDescriptor.asset(const ImageConfiguration(devicePixelRatio: 2.5),
            'assets/images/mylocation.png')
        .then((onValue) {
      _mylocation = onValue;
    });

    BitmapDescriptor.asset(const ImageConfiguration(devicePixelRatio: 2.5),
            'assets/images/mydestination.png')
        .then((onValue) {
      _mydestination = onValue;
    });

    rootBundle.loadString('assets/images/map_style.txt').then((string) {
      _mapStyle = string;
    });
    super.initState();

    _selectedalvalue = _cards[0];

    myLocation = const LatLng(37.382782, 127.1189054);
    _markers.add(Marker(
        markerId: const MarkerId("my location"),
        position: LatLng(myLocation.latitude, myLocation.longitude),
        icon: _mylocation,
        infoWindow: const InfoWindow(
          title: "Pick Up Location",
        ),
        onTap: () {}));
  }

  setPolylines() async {
    polylineCoordinates.clear();
    _polylines.clear();

    // Create PointLatLng for origin and destination
    PointLatLng origin =
        PointLatLng(_fromPlaceDetail.lat, _fromPlaceDetail.lng);
    PointLatLng destination =
        PointLatLng(_toPlaceDetail.lat, _toPlaceDetail.lng);

    // Create the PolylineRequest
    PolylineRequest request = PolylineRequest(
      origin: origin,
      destination: destination,
      mode:
          TravelMode.driving, // You can change this to walking, bicycling, etc.
      // googleApiKey: Constatnts.API_KEY,
    );

    // Get the PolylineResult using the PolylineRequest
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      request: request,
    );

    // Check if the result contains points
    if (result.points.isNotEmpty) {
      // Iterate through the result points and add them to polylineCoordinates
      for (var point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }
    }

    // Update the state with the new polyline
    setState(() {
      Polyline polyline = Polyline(
        polylineId: const PolylineId('poly'),
        color: Colors.black,
        width: 4,
        points: polylineCoordinates,
      );
      _polylines.add(polyline);
      _hasGottenCordinates = true;
    });
  }

  void _moveCamera(
      PlaceDetail fromplaceDetail, PlaceDetail toPlaceDetail) async {
    if (_markers.isNotEmpty) {
      setState(() {
        _markers.clear();
      });
    }
    getLatLngBounds(LatLng(fromplaceDetail.lat, fromplaceDetail.lng),
        LatLng(toPlaceDetail.lat, toPlaceDetail.lng));
    GoogleMapController controller = await _controller.future;
    CameraUpdate u2 = CameraUpdate.newLatLngBounds(bound, 50);
    controller.animateCamera(u2).then((void v) {
      check(u2, controller);
    });

    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId(fromplaceDetail.placeId),
          position: LatLng(fromplaceDetail.lat, fromplaceDetail.lng),
          icon: _mylocation,
          infoWindow: InfoWindow(
            title: "pick up",
            snippet: fromplaceDetail.formattedAddress,
          ),
        ),
      );

      _markers.add(
        Marker(
          markerId: MarkerId(toPlaceDetail.placeId),
          position: LatLng(toPlaceDetail.lat, toPlaceDetail.lng),
          icon: _mydestination,
          infoWindow: InfoWindow(
            title: "destination",
            snippet: toPlaceDetail.formattedAddress,
          ),
        ),
      );
    });

    await setPolylines();
  }

  void getLatLngBounds(LatLng from, LatLng to) {
    if (from.latitude > to.latitude && from.longitude > to.longitude) {
      bound = LatLngBounds(southwest: to, northeast: from);
    } else if (from.longitude > to.longitude) {
      bound = LatLngBounds(
          southwest: LatLng(from.latitude, to.longitude),
          northeast: LatLng(to.latitude, from.longitude));
    } else if (from.latitude > to.latitude) {
      bound = LatLngBounds(
          southwest: LatLng(to.latitude, from.longitude),
          northeast: LatLng(from.latitude, to.longitude));
    } else {
      bound = LatLngBounds(southwest: from, northeast: to);
    }
  }

  void check(CameraUpdate u, GoogleMapController c) async {
    c.animateCamera(u);
    LatLngBounds l1 = await c.getVisibleRegion();
    LatLngBounds l2 = await c.getVisibleRegion();
    print(l1.toString());
    print(l2.toString());
    if (l1.southwest.latitude == -90 || l2.southwest.latitude == -90) {
      check(u, c);
    }
  }

  void _clearCordinate() {
    setState(() {
      _fromLocationController.clear();
      _toLocationController.clear();
      _hasGottenCordinates = false;
      _polylines = {};
      _markers.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const DrawerWidget(),
      body: Stack(
        children: <Widget>[
          Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            color: Colors.white,
          ),
          Container(
              margin: const EdgeInsets.only(top: 0),
              height: MediaQuery.of(context).size.height * 0.6,
              // ignore: unnecessary_null_comparison
              child: myLocation == null
                  ? const Center(
                      child: Text("Loading Map"),
                    )
                  : GoogleMap(
                      key: _mapKey,
                      mapType: MapType.normal,
                      zoomGesturesEnabled: true,
                      markers: _markers,
                      polylines: _polylines,
                      initialCameraPosition:
                          CameraPosition(target: myLocation, zoom: 15),
                      onMapCreated: (GoogleMapController controller) {
                        controller.setMapStyle(_mapStyle);
                        _controller.complete(controller);
                      },
                    )),
          Positioned(top: 65, left: 5, right: 5, child: _buildHelloWidget()),
          _hasGottenCordinates
              ? _buildSelectRideWidget()
              : _buildToFromDestination(),
          Positioned(
            top: 25.0,
            left: 5.0,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                  icon: const Icon(
                    Icons.menu,
                    color: Colors.green,
                  ),
                  onPressed: () {
                    _scaffoldKey.currentState?.openDrawer();
                  }),
            ),
          ),
          Positioned(
            top: 25.0,
            right: 5.0,
            child: _hasGottenCordinates
                ? GestureDetector(
                    onTap: () {
                      _clearCordinate();
                    },
                    child: const Icon(
                      Icons.cancel,
                      color: Colors.green,
                      size: 40,
                    ),
                  )
                : const Text(""),
          )
        ],
      ),
    );
  }

  Widget _buildToFromDestination() {
    return Positioned(
        bottom: 5,
        left: 5,
        right: 5,
        child: Card(
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            child: const Column(
              children: <Widget>[
                SizedBox(
                  height: 45,
                ),
              ],
            ),
          ),
        ));
  }

  Widget _buildHelloWidget() {
    return _hasGottenCordinates
        ? const Text("")
        : Card(
            child: Container(
              color: Colors.white,
              child: ListTile(
                leading: const Icon(
                  FontAwesomeIcons.user,
                  color: Constatnts.primaryColor,
                  size: 40,
                ),
                title: Text(
                  "Hello Mesay",
                  style: CustomStyles.smallTextStyle,
                ),
                subtitle: Text(
                  "Where are you Going to ?",
                  style: CustomStyles.normalTextStyle,
                ),
              ),
            ),
          );
  }

  Widget _buildSelectRideWidget() {
    return Positioned(
      bottom: 5,
      left: 5,
      right: 5,
      child: Card(
        child: Container(
          margin: const EdgeInsets.all(10),
          color: Colors.white,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                "Select Ride",
                style: CustomStyles.normalTextStyle,
              ),
              SizedBox(
                height: 140,
                child: ListView.builder(
                    itemCount: ridesOptions.length,
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedIndex = index;
                          });
                        },
                        child: Card(
                          margin: const EdgeInsets.all(15.0),
                          elevation: 10,
                          color: _selectedIndex == ridesOptions[index].index
                              ? Constatnts.primaryColor
                              : Colors.white,
                          child: SizedBox(
                            width: 200,
                            child: Padding(
                              padding: const EdgeInsets.all(15.0),
                              child: Row(
                                children: <Widget>[
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        ridesOptions[index].rideType,
                                        style: _selectedIndex ==
                                                ridesOptions[index].index
                                            ? CustomStyles.cardBoldTextStyle
                                            : CustomStyles
                                                .cardBoldDarkTextStyle,
                                      ),
                                      Text(
                                        "N ${ridesOptions[index].price.toString()}",
                                        style: _selectedIndex ==
                                                ridesOptions[index].index
                                            ? CustomStyles.cardNormalTextStyle
                                            : CustomStyles
                                                .cardNormalDarkTextStyle,
                                      ),
                                      Text(
                                        ridesOptions[index].estimatedTime,
                                        style: _selectedIndex ==
                                                ridesOptions[index].index
                                            ? CustomStyles.cardNormalTextStyle
                                            : CustomStyles
                                                .cardNormalDarkTextStyle,
                                      )
                                    ],
                                  ),
                                  Expanded(
                                      child: Image.asset(
                                          ridesOptions[index].imageUrl))
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  SizedBox(
                    width: 200,
                    height: 50.0,
                    child: DropdownButton<UserCardModel>(
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.green,
                      ),
                      items: _cards.map((UserCardModel value) {
                        return DropdownMenuItem<UserCardModel>(
                            value: value,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: <Widget>[
                                Image.asset(
                                  value.imageUrl,
                                  height: 10,
                                ),
                                Text(
                                  value.cardNumber,
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ],
                            ));
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedalvalue = value!;
                        });
                      },
                      underline: const SizedBox(),
                      isExpanded: true,
                      elevation: 0,
                      value: _selectedalvalue,
                    ),
                  ),
                  MaterialButton(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    color: Constatnts.primaryColor,
                    onPressed: () {
                      // Define the bounds based on from and to locations
                      LatLngBounds bounds = LatLngBounds(
                        southwest: LatLng(
                          _fromPlaceDetail.lat < _toPlaceDetail.lat
                              ? _fromPlaceDetail.lat
                              : _toPlaceDetail.lat,
                          _fromPlaceDetail.lng < _toPlaceDetail.lng
                              ? _fromPlaceDetail.lng
                              : _toPlaceDetail.lng,
                        ),
                        northeast: LatLng(
                          _fromPlaceDetail.lat > _toPlaceDetail.lat
                              ? _fromPlaceDetail.lat
                              : _toPlaceDetail.lat,
                          _fromPlaceDetail.lng > _toPlaceDetail.lng
                              ? _fromPlaceDetail.lng
                              : _toPlaceDetail.lng,
                        ),
                      );
                    },
                    child: Text(
                      "Confirm",
                      style: CustomStyles.cardBoldTextStyle,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
