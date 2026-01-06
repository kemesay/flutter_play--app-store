import 'package:flutter/material.dart';
import 'package:flutter_credit_card/flutter_credit_card.dart';
import 'package:oda_black_car_service/utils/styles.dart'; // Assuming this contains CustomStyles

class CreditCardWIdget extends StatelessWidget {
  const CreditCardWIdget({super.key});

  @override
  Widget build(BuildContext context) {
    return CreditCardWidget(
      // Required fields
      cardNumber: "5399 4678 0987 5677",
      expiryDate: "02/19",
      cardHolderName: "Melkamu .H",
      cvvCode: "789",
      showBackView: false, // Set to true if you want to show the back of the card

      // Optimized visual styling
      cardBgColor: Colors.white,
      textStyle: CustomStyles.cardBoldDarkTextStyle,
      height: 180, // Set height according to your design

      // Required callback for card brand changes
      onCreditCardWidgetChange: (CreditCardBrand creditCardBrand) {
        // Optionally handle brand changes here
        print('Credit card brand changed: ${creditCardBrand.brandName}');
      },
    );
  }
}
