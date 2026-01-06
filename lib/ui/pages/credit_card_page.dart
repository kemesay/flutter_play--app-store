import 'package:oda_black_car_service/ui/widgets/header_widget.dart';
import 'package:oda_black_car_service/utils/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_credit_card/flutter_credit_card.dart';


import 'add_credit_card_page.dart';

class CreditCardPage extends StatelessWidget {
  static const routeName = "credit-card";

  const CreditCardPage({super.key});

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
              child: SizedBox(
                width: mQ.width,
                height: mQ.height * 0.75,
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    return CreditCardWidget(
                      cardBgColor: Colors.white,
                      textStyle: CustomStyles.cardBoldDarkTextStyle,
                      height: 180,
                      cardNumber: "5399 4678 0987 5677",
                      expiryDate: "02/19",
                      cardHolderName: "Melkamu .H",
                      cvvCode: "789",
                      showBackView: false, onCreditCardWidgetChange: (CreditCardBrand ) {  },
                    );
                  },
                  itemCount: 5,
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
                  "Credit Card",
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
                    "Add New Card",
                    style: CustomStyles.cardBoldDarkTextStyleGreen,
                  ),
                  MaterialButton(
                    onPressed: () {
                      Navigator.of(context)
                          .pushNamed(AddCreditCardPage.routeName);
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
