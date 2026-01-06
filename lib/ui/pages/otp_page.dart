import 'package:oda_black_car_service/ui/widgets/header_widget.dart';
import 'package:oda_black_car_service/utils/styles.dart';
import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'book_taxi_page.dart';

class OtpPage extends StatefulWidget {
  static const routeName = "otp-page";

  const OtpPage({super.key});
  @override
  // ignore: library_private_types_in_public_api
  _OtpPageState createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  @override
  Widget build(BuildContext context) {
    final mQ = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(
        children: <Widget>[
          Stack(
            children: <Widget>[
              HeaderWidget(height: mQ.height * 0.5),
              Positioned(
                top: 20.0,
                left: 0.0,
                child: MaterialButton(
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
              )
            ],
          ),
          SizedBox(
            height: mQ.height * 0.03,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                Text("Phone Verification", style: CustomStyles.smallTextStyle),
                SizedBox(height: mQ.height * 0.01),
                Text(
                  "Enter your OTP code below",
                  style: CustomStyles.mediumTextStyle,
                ),
              ],
            ),
          ),
          SizedBox(
            height: mQ.height * 0.05,
          ),
          Card(
            margin: const EdgeInsets.only(left: 20, right: 20),
            elevation: 6.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(3.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      flex: 3,
                      child: PinCodeTextField(
                        appContext: context,  // Add the appContext parameter here
                        keyboardType: TextInputType.number, // Corrected to keyboardType
                        length: 6,
                        obscureText: false, // Correct spelling of 'obscureText'
                        animationType: AnimationType.fade,
                        animationDuration: const Duration(milliseconds: 300),
                        autoFocus: true,
                        pinTheme: PinTheme(
                          shape: PinCodeFieldShape.underline,  // Define the shape here
                          inactiveColor: Colors.black,  // Inactive color for unfilled fields
                          fieldHeight: 30,  // Field height
                          fieldWidth: 25,  // Field width
                          borderRadius: BorderRadius.circular(5),  // Define border radius here
                        ),
                        onChanged: (value) {
                          setState(() {
                            // currentText = value;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: MaterialButton(
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
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(
            height: mQ.height * 0.1,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20),
            child: RichText(
              textAlign: TextAlign.start,
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'Resend Code in',
                    style: TextStyle(
                      color: Color(0xff303030),
                      fontSize: 12,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  TextSpan(
                    text: ' 10 Seconds',
                    style: TextStyle(
                      color: Color(0xff303030),
                      fontSize: 12,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
