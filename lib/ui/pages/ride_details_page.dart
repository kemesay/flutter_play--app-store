import 'dart:async';
import 'package:oda_black_car_service/ui/widgets/header_widget.dart';
import 'package:oda_black_car_service/utils/constants.dart';
import 'package:oda_black_car_service/utils/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
class RideDetailsPage extends StatefulWidget {
  static const routeName = "ride-details-page";

  const RideDetailsPage({super.key});

  @override
  _RideDetailsPageState createState() => _RideDetailsPageState();
}
class _RideDetailsPageState extends State<RideDetailsPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final Completer<GoogleMapController> _controller = Completer();
  late GoogleMapController mapController; // Declaring mapController as late
  bool isMapCreated = false;
  final Key _mapKey = UniqueKey();
  final Set<Marker> _markers = {};
  static const LatLng _center = LatLng(6.5244, 3.3792);
  LatLng _lastMapPosition = _center;

  String? _mapStyle;  // Nullable String to accommodate possible null values
  BitmapDescriptor? _mylocation;
  BitmapDescriptor? _taxilocation;
  final LatLng _initialCameraPosition = const LatLng(9.005130740036533, 38.766785045325534);
  final LatLng _destinationPosition = const LatLng(8.986392611040223, 38.79658346040148);

  LatLngBounds? bound;

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _controller.complete(controller);
    setState(() {
      _markers.clear();
      addMarker(_initialCameraPosition, "PickUp", "Shopping Mall", _taxilocation!);
      addMarker(_destinationPosition, "Destination", "My Home", _mylocation!);
    });
  Future.delayed(const Duration(milliseconds: 100), () {
      CameraUpdate u2 = CameraUpdate.newLatLngBounds(bound!, 50);
      mapController.animateCamera(u2).then((void v) {
        check(u2, mapController);
      });
    });
  }

  void addMarker(LatLng mLatLng, String mTitle, String mDescription,
      BitmapDescriptor marker) {
    _markers.add(Marker(
      markerId:
          MarkerId(("${mTitle}_${_markers.length}").toString()),
      position: mLatLng,
      infoWindow: InfoWindow(
        title: mTitle,
        snippet: mDescription,
      ),
      icon: marker,
    ));
  }

  @override
  void initState() {
    BitmapDescriptor.asset(const ImageConfiguration(devicePixelRatio: 2.5),
            'assets/images/mylocation.png')
        .then((onValue) {
      _taxilocation = onValue;
    });

    BitmapDescriptor.asset(const ImageConfiguration(devicePixelRatio: 2.5),
            'assets/images/mydestination.png')
        .then((onValue) {
      _mylocation = onValue;
    });

    rootBundle.loadString('assets/images/map_style.txt').then((string) {
      _mapStyle = string;
    });

    getLatLngBounds(_initialCameraPosition, _destinationPosition);

    super.initState();
  }

  void _onCameraMove(CameraPosition position) {
    _lastMapPosition = position.target;
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
    //  mapController.animateCamera(u);
    LatLngBounds l1 = await c.getVisibleRegion();
    LatLngBounds l2 = await c.getVisibleRegion();
    print(l1.toString());
    print(l2.toString());
    if (l1.southwest.latitude == -90 || l2.southwest.latitude == -90) {
      check(u, c);
    }
  }

  _buildRideInfo(
    String point,
    String title,
    String subtitle,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Column(
          children: <Widget>[
            Icon(
              FontAwesomeIcons.solidCircleDot,
              size: 12,
              color: color,
            ),
          ],
        ),
        const SizedBox(
          width: 15,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('$point - $title', style: CustomStyles.smallLightTextStyle),
            const SizedBox(
              height: 3,
            ),
            Text(
              subtitle,
              style: CustomStyles.normalTextStyle,
            ),
          ],
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final mQ = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: <Widget>[
          SizedBox(
            width: mQ.width,
            height: mQ.height,
          ),
          NoLogoHeaderWidget(height: mQ.height * 0.5),
          Positioned(
              top: 100,
              left: 10,
              right: 10,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  alignment: Alignment.center,
                  width: mQ.width,
                  height: mQ.height * 0.8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.rectangle,
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(5.0)),
                    boxShadow: [
                      BoxShadow(
                          color: Color(0x29000000),
                          offset: Offset(0, 5),
                          blurRadius: 6,
                          spreadRadius: 0)
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(left: 20.0, top: 30.0),
                          child: _buildRideInfo(
                              "From",
                              "Dembal City Center, African Avenue",
                              "My Home",
                              Colors.green),
                        ),
                        Padding(
                            padding: const EdgeInsets.only(left: 20, top: 10),
                            child: _buildRideInfo(
                                "To",
                                "Bole International Airport",
                                "National travel Enterance Gate",
                                Colors.red)),
                        Container(
                            margin: const EdgeInsets.all(20),
                            height: MediaQuery.of(context).size.height * 0.3,
                            child: GoogleMap(
                              key: _mapKey,
                              mapType: MapType.normal,
                              zoomGesturesEnabled: true,
                              markers: _markers,
                              onMapCreated: _onMapCreated,
                              initialCameraPosition: const CameraPosition(
                                target: _center,
                                zoom: 11.0,
                              ),
                              onCameraMove: _onCameraMove,
                            )),
                        ListTile(
                          leading: const Icon(
                            FontAwesomeIcons.user,
                            color: Constatnts.primaryColor,
                            size: 35,
                          ),
                          title: Text("DRIVER",
                              style: CustomStyles.smallLightTextStyle),
                          subtitle: Text(
                            "ALemu Gebru",
                            style: CustomStyles.cardBoldDarkTextStyle,
                          ),
                          trailing: Text(
                            "30 Sep 2024",
                            style: CustomStyles.smallLightTextStyle,
                          ),
                        ),
                        ListTile(
                          leading: const Icon(
                            FontAwesomeIcons.moneyCheck,
                            color: Constatnts.primaryColor,
                            size: 30,
                          ),
                          title: Text("PAYMENT",
                              style: CustomStyles.smallLightTextStyle),
                          subtitle: Text(
                            "ETB 500",
                            style: CustomStyles.cardBoldDarkTextStyle,
                          ),
                          trailing: Text(
                            "CARD PAYMENT",
                            style: CustomStyles.smallLightTextStyle,
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        )
                      ],
                    ),
                  ),
                ),
              )),
          Positioned(
            top: 50.0,
            left: 0.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                MaterialButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  color: Colors.white,
                  textColor: Colors.green,
                  padding: const EdgeInsets.all(6),
                  shape: const CircleBorder(),
                  child: const Icon(
                    Icons.arrow_back,
                    size: 15,
                  ),
                ),
                Text(
                  "Ride Details",
                  style: CustomStyles.cardBoldTextStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
