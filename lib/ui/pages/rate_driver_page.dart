import 'package:oda_black_car_service/ui/pages/book_taxi_page.dart';
import 'package:oda_black_car_service/ui/widgets/header_widget.dart';
import 'package:oda_black_car_service/utils/styles.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:smooth_star_rating_nsafe/smooth_star_rating.dart';


class RateDriverPage extends StatefulWidget {
  static const routeName = "rate-driver";

  const RateDriverPage({super.key});

  @override
  _RateDriverPageState createState() => _RateDriverPageState();
}

class _RateDriverPageState extends State<RateDriverPage> {
  double rating = 0.0;
  String reviewDescription = '';
  _buildDurationTime(String title, String subtitle) {
    return Column(
      children: <Widget>[
        Text(title,
            textAlign: TextAlign.center,
            style: CustomStyles.smallLightTextStyle),
        Text(
          subtitle,
          style: CustomStyles.cardBoldDarkTextStyle2,
        ),
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
              top: mQ.height * 0.18,
              child: SizedBox(
                height: mQ.height * 0.8,
                width: mQ.width,
                child: ListView(
                  children: <Widget>[
                    Container(
                      width: 150,
                      height: 150,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xffd6d6d6),
                        boxShadow: [
                          BoxShadow(
                              color: Color(0x29000000),
                              offset: Offset(0, 5),
                              blurRadius: 6,
                              spreadRadius: 0)
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          FontAwesomeIcons.user,
                          color: Colors.white,
                          size: 75,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Text("Your Driver",
                        textAlign: TextAlign.center,
                        style: CustomStyles.smallLightTextStyle),
                    Text(
                      "Mesay Kebede",
                      textAlign: TextAlign.center,
                      style: CustomStyles.cardBoldDarkTextStyle,
                    ),
                    const SizedBox(
                      height: 25,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        _buildDurationTime("Time", "10 min"),
                        _buildDurationTime("Price", "120 ETB"),
                        _buildDurationTime("Distance", "10 km"),
                      ],
                    ),
                    SizedBox(
                      height: mQ.height * 0.05,
                    ),
                    Text("Mesay",
                        textAlign: TextAlign.center,
                        style: CustomStyles.smallLightTextStyle),
                    Text(
                      "How is your trip ?",
                      textAlign: TextAlign.center,
                      style: CustomStyles.cardBoldDarkTextStyle,
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Center(
                        child: SmoothStarRating(
                      rating: rating,
                      size: 45,
                      filledIconData: Icons.star,
                      halfFilledIconData: Icons.star_half,
                      defaultIconData: Icons.star_border,
                      starCount: 5,
                      allowHalfRating: false,
                      spacing: 2.0,
                      onRatingChanged: (value) {
                        setState(() {
                          rating = value;
                        });
                      },
                    )),
                    const SizedBox(
                      height: 10,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: TextField(
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Write your experience with the driver...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          contentPadding: EdgeInsets.all(15.0),
                        ),
                        onChanged: (value) {
                          setState(() {
                            reviewDescription = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                  ],
                ),
              )),
              // Display the review description if entered
              if (reviewDescription.isNotEmpty)
                Positioned(
                  top: mQ.height * 0.65,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      reviewDescription,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
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
                  "You are in place !",
                  style: CustomStyles.cardBoldTextStyle,
                ),
              ],
            ),
          ),
          Positioned(
              bottom: 10,
              right: 5,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Text(
                    "Submit",
                    style: CustomStyles.cardBoldDarkTextStyleGreen,
                  ),
                  MaterialButton(
                    onPressed: () {
                      Navigator.of(context)
                          .pushReplacementNamed(BookTaxiPage.routeName);
                    },
                    color: Colors.green,
                    textColor: Colors.white,
                    padding: const EdgeInsets.all(6),
                    shape: const CircleBorder(),
                    child: const Icon(
                      Icons.arrow_forward,
                      size: 15,
                    ),
                  )
                ],
              )),
        ],
      ),
    );
  }
}
