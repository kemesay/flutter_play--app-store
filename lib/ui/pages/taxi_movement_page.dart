import 'package:oda_black_car_service/model/place_model.dart';
import 'package:oda_black_car_service/ui/pages/rate_driver_page.dart';
import 'package:oda_black_car_service/utils/constants.dart';
import 'package:oda_black_car_service/utils/styles.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
class TaxiMovementPage extends StatefulWidget {
  static String routeName = "taxi-movement-page";
  final PlaceDetail fromPlaceDetail;
  final PlaceDetail toPlaceDetail;
  final Set<Polyline> polylines;
  final List<LatLng> polylineCoordinates;
  final LatLngBounds bound;
  const TaxiMovementPage({
    super.key,
    required this.fromPlaceDetail,
    required this.toPlaceDetail,
    required this.polylines,
    required this.polylineCoordinates,
    required this.bound,
  });

  @override
  _TaxiMovementPageState createState() => _TaxiMovementPageState();
}
class _TaxiMovementPageState extends State<TaxiMovementPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final Completer<GoogleMapController> _controller = Completer();
  bool isMapCreated = false;
  final Key _mapKey = UniqueKey();
  late Timer _demoTimer; // Marking it as `late`
  final Set<Marker> _markers = {};
  late LatLng _initialCameraPosition; // Marking it as `late`
  late String _mapStyle; // Marking it as `late`
  late BitmapDescriptor _mylocation; // Marking it as `late`
  late BitmapDescriptor _taxilocation; // Marking it as `late`
  bool _hasTripEnded = false;

  @override
  void dispose() {
    _demoTimer.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    BitmapDescriptor.asset(
            const ImageConfiguration(devicePixelRatio: 2.5),
            'assets/images/mylocation.png')
        .then((onValue) {
      _taxilocation = onValue;
    });

    BitmapDescriptor.asset(
            const ImageConfiguration(devicePixelRatio: 2.5),
            'assets/images/mydestination.png')
        .then((onValue) {
      _mylocation = onValue;
    });

    _initialCameraPosition =
        LatLng(widget.toPlaceDetail.lat, widget.toPlaceDetail.lng);

    rootBundle.loadString('assets/images/map_style.txt').then((string) {
      _mapStyle = string;
    });
  }

  int index = 0;

  void updatePolyLinePoints() {
    _demoTimer = Timer.periodic(const Duration(milliseconds: 300), (t) {
      updateTaxiOnMap(widget.polylineCoordinates[index]);
    });
  }
  void updateTaxiOnMap(LatLng taxiPosition) async {
    CameraPosition cPosition = CameraPosition(
      zoom: 13,
      tilt: 40,
      bearing: 30,
      target: LatLng(taxiPosition.latitude, taxiPosition.longitude),
    );
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(cPosition));
    setState(() {
      var newTaxiPosition =
          LatLng(taxiPosition.latitude, taxiPosition.longitude);
      _markers.removeWhere((m) => m.markerId.value == 'pickup');
      _markers.add(Marker(
          markerId: const MarkerId('pickup'),
          position: newTaxiPosition, // updated position
          icon: _taxilocation));
      if (index == widget.polylineCoordinates.length - 1) {
        _hasTripEnded = true;
        _demoTimer.cancel();
        // journey has ended
      } else {
        index++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const Drawer(),
      body: Stack(
        children: <Widget>[
          SizedBox(
              height: MediaQuery.of(context).size.height, //- 230.0,
              child: GoogleMap(
                key: _mapKey,
                mapType: MapType.normal,
                zoomGesturesEnabled: true,
                markers: _markers,
                initialCameraPosition:
                    CameraPosition(target: _initialCameraPosition, zoom: 13),
                onMapCreated: (GoogleMapController controller) {
                  controller.setMapStyle(_mapStyle);
                  _controller.complete(controller);
                  setState(() {
                    _markers.add(Marker(
                        markerId: const MarkerId("my destination"),
                        position: LatLng(
                            widget.toPlaceDetail.lat, widget.toPlaceDetail.lng),
                        icon: _mylocation,
                        infoWindow: const InfoWindow(
                          title: "My destination",
                        )));

                    _markers.add(Marker(
                        markerId: const MarkerId("pickup"),
                        position: LatLng(widget.fromPlaceDetail.lat,
                            widget.fromPlaceDetail.lng),
                        icon: _taxilocation,
                        infoWindow: const InfoWindow(
                          title: "Pick Up Location",
                        )));
                  });

                  Future.delayed(const Duration(milliseconds: 100), () {
                    CameraUpdate u2 =
                        CameraUpdate.newLatLngBounds(widget.bound, 50);
                    controller.animateCamera(u2);
                  });
                },
              )),
          Positioned(
            top: 50.0,
            left: 10.0,
            right: 10.0,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    MaterialButton(
                      onPressed: () {
                        _hasTripEnded
                            ? Navigator.of(context)
                                .pushReplacementNamed(RateDriverPage.routeName)
                            : Navigator.of(context).pop();
                      },
                      color: _hasTripEnded ? Colors.red : Colors.green,
                      textColor: Colors.white,
                      padding: const EdgeInsets.all(6),
                      shape: const CircleBorder(),
                      child: Icon(
                        _hasTripEnded ? FontAwesomeIcons.car : Icons.arrow_back,
                        size: 15,
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          !_hasTripEnded
                              ? "taxi will arrive"
                              : "taxi at destination",
                          style: CustomStyles.smallLightTextStyle,
                        ),
                        Text(
                          !_hasTripEnded
                              ? "Your Destination in 5 minutes"
                              : "Your trip has ended",
                          style: CustomStyles.normalTextStyle,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: !_hasTripEnded ? Constatnts.primaryColor : Colors.red,
        onPressed: () {
          !_hasTripEnded
              ? updatePolyLinePoints()
              : Navigator.of(context)
                  .pushReplacementNamed(RateDriverPage.routeName);
        },
        child: const Icon(FontAwesomeIcons.taxi),
      ),
    );
  }
}
