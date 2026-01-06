import 'package:oda_black_car_service/ui/widgets/header_widget.dart';
import 'package:oda_black_car_service/utils/constants.dart';
import 'package:oda_black_car_service/utils/styles.dart';
import 'package:flutter/material.dart';

class PromoCodePage extends StatelessWidget {
  static const routeName = "promo-code";

  const PromoCodePage({super.key});
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
                  height: mQ.height * 0.3,
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
                  child: SizedBox(
                    width: 200,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        TextField(
                          textAlign: TextAlign.center,
                          style: CustomStyles.cardBoldDarkTextStyle,
                          autofocus: true,
                          cursorColor: Constatnts.primaryColor,
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Text(
                          "PROMO CODE",
                          style: CustomStyles.cardBoldDarkTextStyle2,
                        ),
                      ],
                    ),
                  ),
                ),
              )),
          Positioned(
              bottom: 10,
              right: 5,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Text(
                    "Enter Code",
                    style: CustomStyles.cardBoldDarkTextStyleGreen,
                  ),
                  MaterialButton(
                    onPressed: () {},
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
                  "Promo Codes",
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
