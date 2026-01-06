import 'package:oda_black_car_service/ui/widgets/header_widget.dart';
import 'package:oda_black_car_service/utils/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_credit_card/flutter_credit_card.dart';

class AddCreditCardPage extends StatefulWidget {
  static const routeName = "add-credit-card";
  const AddCreditCardPage({super.key});
  @override
  _AddCreditCardPageState createState() => _AddCreditCardPageState();
}

class _AddCreditCardPageState extends State<AddCreditCardPage> {
  String cardNumber = '';
  String expiryDate = '';
  String cardHolderName = '';
  String cvvCode = '';
  bool isCvvFocused = false;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  void onCreditCardModelChange(CreditCardModel creditCardModel) {
    setState(() {
      cardNumber = creditCardModel.cardNumber;
      expiryDate = creditCardModel.expiryDate;
      cardHolderName = creditCardModel.cardHolderName;
      cvvCode = creditCardModel.cvvCode;
      isCvvFocused = creditCardModel.isCvvFocused;
    });
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
            child: SizedBox(
              width: mQ.width,
              height: mQ.height * 0.8,
              child: Column(
                children: <Widget>[
                  CreditCardWidget(
                    cardBgColor: Colors.white,
                    textStyle: CustomStyles.cardBoldDarkTextStyle,
                    height: 180,
                    cardNumber: cardNumber,
                    expiryDate: expiryDate,
                    cardHolderName: cardHolderName,
                    cvvCode: cvvCode,
                    showBackView: isCvvFocused,
                    onCreditCardWidgetChange: (CreditCardBrand) {},
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: CreditCardForm(
                        cardNumber: cardNumber,
                        expiryDate: expiryDate,
                        cardHolderName: cardHolderName,
                        cvvCode: cvvCode,
                        formKey: formKey,
                        onCreditCardModelChange: onCreditCardModelChange,
                      ),
                    ),
                  ),
                ],
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
                  "Add New Card",
                  style: CustomStyles.cardBoldTextStyle,
                ),
              ],
            ),
          ),
          Positioned(
            top: 50.0,
            right: 0,
            child: MaterialButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  // Handle card save logic here
                  Navigator.of(context).pop();
                }
              },
              color: Colors.white,
              textColor: Colors.green,
              padding: const EdgeInsets.all(6),
              shape: const CircleBorder(),
              child: const Icon(
                Icons.save,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
