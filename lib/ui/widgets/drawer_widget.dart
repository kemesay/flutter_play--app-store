import 'package:oda_black_car_service/ui/pages/credit_card_page.dart';
import 'package:oda_black_car_service/ui/pages/promo_code_page.dart';
import 'package:oda_black_car_service/ui/pages/ride_history_page.dart';
import 'package:oda_black_car_service/ui/pages/settings_page.dart';
import 'package:oda_black_car_service/ui/screens/home/pages/support_page.dart';
import 'package:oda_black_car_service/utils/constants.dart';
import 'package:oda_black_car_service/utils/styles.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:share_plus/share_plus.dart';

class DrawerWidget extends StatelessWidget {
  const DrawerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: <Widget>[
          ListTile(
            leading: const Icon(
              FontAwesomeIcons.user,
              color: Constatnts.primaryColor,
              size: 40,
            ),
            title: const Text(
              "Good Morning",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            ),
            subtitle: Text(
              "Mesay Kebede",
              style: CustomStyles.cardBoldDarkDrawerTextStyle,
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.only(left: 35, top: 25),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                GestureDetector(
                  onTap: () {
                    Navigator.of(context)
                        .popAndPushNamed(RideHistoryPage.routeName);
                  },
                  child: Text(
                    "Ride History",
                    style: CustomStyles.cardBoldDarkDrawerTextStyle,
                  ),
                ),
                const SizedBox(
                  height: 15,
                ),
                GestureDetector(
                  onTap: () {
                    // Enable share functionality now that package is available
                    Share.share(
                      "https://ethiosmartride.com",
                      subject: "Invite Your Friend To ODA Black Car Service",
                    );
                  },
                  child: Text(
                    "Invite Friends",
                    style: CustomStyles.cardBoldDarkDrawerTextStyle,
                  ),
                ),
                const SizedBox(
                  height: 15,
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context)
                        .popAndPushNamed(PromoCodePage.routeName);
                  },
                  child: Text(
                    "Promo Codes",
                    style: CustomStyles.cardBoldDarkDrawerTextStyle,
                  ),
                ),
                const SizedBox(
                  height: 15,
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context)
                        .popAndPushNamed(CreditCardPage.routeName);
                  },
                  child: Text(
                    "Credit Card",
                    style: CustomStyles.cardBoldDarkDrawerTextStyle,
                  ),
                ),
                const SizedBox(
                  height: 15,
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context)
                        .popAndPushNamed(SettingsPage.routeName);
                  },
                  child: Text(
                    "Settings",
                    style: CustomStyles.cardBoldDarkDrawerTextStyle,
                  ),
                ),
                const SizedBox(
                  height: 15,
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context)
                        .popAndPushNamed(SupportPage.routeName);
                  },
                  child: Text(
                    "Support",
                    style: CustomStyles.cardBoldDarkDrawerTextStyle,
                  ),
                ),
                const SizedBox(
                  height: 15,
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pushNamed('/');
                  },
                  child: Text(
                    "Log Out",
                    style: CustomStyles.cardBoldDarkTextStyle,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
