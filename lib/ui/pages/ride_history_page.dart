import 'package:oda_black_car_service/ui/widgets/header_widget.dart';
import 'package:oda_black_car_service/ui/widgets/ride_history_widget.dart';
import 'package:oda_black_car_service/utils/styles.dart';
import 'package:flutter/material.dart';


class RideHistoryPage extends StatelessWidget {
  static const String routeName = "ride-history-page";

  const RideHistoryPage({super.key});

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
              top: mQ.height * 0.18,
              left: 5,
              right: 5,
              child: SizedBox(
                height: mQ.height * 0.8,
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    return const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: RideHistoryWidget(),
                    );
                  },
                  itemCount: 10,
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
                  "Ride History",
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
