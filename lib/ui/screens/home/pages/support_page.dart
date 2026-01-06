import 'package:oda_black_car_service/utils/constants.dart';
import 'package:oda_black_car_service/utils/styles.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../../providers/support_provider.dart';
import '../../../../../../providers/auth_provider.dart';
import '../../../../../../providers/social_media_provider.dart';
import '../../../../../../ui/widgets/custom_snackbar.dart';

class SupportPage extends StatelessWidget {
  static const routeName = "support";

  const SupportPage({super.key});

  _buildContactRow(IconData iconData, String title, String subtitle) {
    return Row(
      children: <Widget>[
        Icon(
          iconData,
          color: Constatnts.primaryColor,
        ),
        const SizedBox(
          width: 20,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 10,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w300,
              ),
            ),
            Text(subtitle, style: CustomStyles.smallTextStyle)
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF03930A), // Brand primary color
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  MaterialButton(
                    onPressed: () {
                      // Check if we can pop, otherwise go to home
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        // If we can't pop, navigate to home
                        Navigator.of(context)
                            .pushNamedAndRemoveUntil('/', (route) => false);
                      }
                    },
                    color: Colors.white,
                    textColor: const Color(0xFF03930A),
                    padding: const EdgeInsets.all(6),
                    shape: const CircleBorder(),
                    child: const Icon(
                      Icons.arrow_back,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Support",
                    style: CustomStyles.cardBoldTextStyle.copyWith(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
            // Gradient header section
            Container(
              height: 180,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF03930A), // Primary brand color
                    Color(0xFF4CB051), // Light brand color
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
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
                        Icons.headset_mic,
                        color: Color(0xFF03930A),
                        size: 50,
                      ),
                    ),
                  ),
                  // const SizedBox(height: 16),
                  // Text(
                  //   "Support & Contact Us",
                  //   textAlign: TextAlign.center,
                  //   style: CustomStyles.cardBoldTextStyle.copyWith(
                  //     fontSize: 20,
                  //     color: Colors.white,
                  //   ),
                  // ),
                ],
              ),
            ),
            // Scrollable content
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Contact methods section
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Contact Methods",
                              style:
                                  CustomStyles.cardBoldDarkTextStyle.copyWith(
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Static contact methods
                            _buildClickableContactRow(
                              Icons.web,
                              "Website",
                              "https://odatransportation.com/",
                              context,
                            ),
                            const SizedBox(height: 25),
                            _buildClickableContactRow(
                              Icons.email,
                              "Email",
                              "info@odatransportation.com",
                              context,
                            ),
                            const SizedBox(height: 25),
                            _buildClickableContactRow(
                              Icons.phone,
                              "Phone",
                              "+1 7143134269",
                              context,
                            ),
                            const SizedBox(height: 25),
                            // Dynamic social media links
                            _buildSocialMediaLinks(context),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Messaging form section
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const _SupportForm(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build social media links dynamically
  Widget _buildSocialMediaLinks(BuildContext context) {
    return Consumer<SocialMediaProvider>(
      builder: (context, socialMediaProvider, child) {
        if (socialMediaProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (socialMediaProvider.socialMedias.isEmpty) {
          // Fallback to static social media links
          return Column(
            children: [
              _buildClickableContactRow(
                FontAwesomeIcons.facebook,
                "Facebook",
                "https://www.facebook.com/Oda.Black.Car.Service",
                context,
              ),
              const SizedBox(height: 25),
              _buildClickableContactRow(
                FontAwesomeIcons.instagram,
                "Instagram",
                "https://www.instagram.com/oda.black.car.service/",
                context,
              ),
              const SizedBox(height: 25),
              _buildClickableContactRow(
                FontAwesomeIcons.yelp,
                "Yelp",
                "https://www.yelp.com/biz/oda-transportation-black-car-service-anaheim",
                context,
              ),
              const SizedBox(height: 25),
              _buildClickableContactRow(
                FontAwesomeIcons.twitter,
                "Twitter",
                "https://x.com/OdaBlackCar",
                context,
              ),
            ],
          );
        }

        // Build dynamic social media links
        return Column(
          children: socialMediaProvider.socialMedias.map((socialMedia) {
            final icon = _getSocialMediaIcon(socialMedia.title);
            return Column(
              children: [
                _buildClickableContactRow(
                  icon,
                  socialMedia.title,
                  socialMedia.link,
                  context,
                ),
                const SizedBox(height: 25),
              ],
            );
          }).toList(),
        );
      },
    );
  }

  /// Get appropriate icon for social media platform
  IconData _getSocialMediaIcon(String title) {
    switch (title.toLowerCase()) {
      case 'facebook':
      case 'facebook page':
        return FontAwesomeIcons.facebook;
      case 'instagram':
        return FontAwesomeIcons.instagram;
      case 'twitter':
      case 'x page':
        return FontAwesomeIcons.twitter;
      case 'yelp':
        return FontAwesomeIcons.yelp;
      case 'linkedin':
        return FontAwesomeIcons.linkedin;
      case 'youtube':
        return FontAwesomeIcons.youtube;
      case 'tiktok':
        return FontAwesomeIcons.tiktok;
      default:
        return FontAwesomeIcons.link; // Default icon
    }
  }

  /// Build a clickable contact row
  Widget _buildClickableContactRow(
    IconData iconData,
    String title,
    String link,
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: () async {
        try {
          Uri uri;

          // Handle different types of links
          if (title.toLowerCase() == 'email') {
            // Format email links
            uri = Uri(scheme: 'mailto', path: link);
          } else if (title.toLowerCase() == 'phone') {
            // Format phone links
            // Remove spaces and other non-numeric characters except + for international format
            final formattedPhone = link.replaceAll(RegExp(r'[^0-9+]'), '');
            uri = Uri(scheme: 'tel', path: formattedPhone);
          } else {
            // Handle website and social media links
            // Ensure website links have proper scheme
            String formattedLink = link;
            if (!link.startsWith('http://') && !link.startsWith('https://')) {
              formattedLink = 'https://$link';
            }
            uri = Uri.parse(formattedLink);
          }

          if (await canLaunchUrl(uri)) {
            // Add some debugging
            print('Launching URL: $uri');
            await launchUrl(
                uri); // Use default launch mode instead of externalApplication
          } else {
            // Add debugging
            print('Cannot launch URL: $uri');
            // For phone and email, show a more specific error message
            String errorMessage;
            if (title.toLowerCase() == 'phone') {
              errorMessage = 'No phone app found to handle this call';
            } else if (title.toLowerCase() == 'email') {
              errorMessage = 'No email app found to handle this message';
            } else {
              errorMessage = 'Could not launch $link';
            }

            if (context.mounted) {
              CustomSnackbar.show(
                context,
                errorMessage,
              );
            }
          }
        } catch (e) {
          // Add debugging
          print('Error launching URL: $e');
          if (context.mounted) {
            CustomSnackbar.show(
              context,
              'Error launching link: $e',
            );
          }
        }
      },
      child: Row(
        children: <Widget>[
          Icon(
            iconData,
            color: Constatnts.primaryColor,
          ),
          const SizedBox(
            width: 20,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w300,
                  ),
                ),
                Text(
                  link,
                  style: CustomStyles.smallTextStyle.copyWith(
                    color: Constatnts.primaryColor,
                    decoration: TextDecoration.underline,
                  ),
                )
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.grey,
          ),
        ],
      ),
    );
  }
}

class _SupportForm extends StatefulWidget {
  const _SupportForm();

  @override
  State<_SupportForm> createState() => _SupportFormState();
}

class _SupportFormState extends State<_SupportForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final supportProvider = context.watch<SupportProvider>();
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    if (user != null && _nameController.text.isEmpty) {
      _nameController.text = user.fullName;
      _emailController.text = user.email ?? '';
      _phoneController.text = user.phoneNumber ?? '';
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Send us a message",
            style: CustomStyles.cardBoldDarkTextStyle.copyWith(
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Full name',
              border: OutlineInputBorder(),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Please enter your name'
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Provide an email address';
              }
              final emailRegex = RegExp(
                  r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$");
              if (!emailRegex.hasMatch(value)) {
                return 'Enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone number',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _subjectController,
            decoration: const InputDecoration(
              labelText: 'Subject',
              border: OutlineInputBorder(),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Please enter a subject'
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _messageController,
            decoration: const InputDecoration(
              labelText: 'Message',
              border: OutlineInputBorder(),
            ),
            minLines: 3,
            maxLines: 6,
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Please enter your message'
                : null,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: supportProvider.isSubmitting
                  ? null
                  : () async {
                      if (!_formKey.currentState!.validate()) return;
                      final success =
                          await context.read<SupportProvider>().sendMessage(
                                fullName: _nameController.text.trim(),
                                email: _emailController.text.trim(),
                                phoneNumber: _phoneController.text.trim(),
                                service: _subjectController.text.trim(),
                                message: _messageController.text.trim(),
                              );
                      if (success) {
                        if (!mounted) return;
                        CustomSnackbar.show(
                          context,
                          'Message sent. Our support team will respond shortly.',
                        );
                        _messageController.clear();
                        _subjectController.clear();
                      } else {
                        if (!mounted) return;
                        CustomSnackbar.show(
                          context,
                          context.read<SupportProvider>().errorMessage ??
                              'Unable to send message',
                        );
                      }
                    },
              child: supportProvider.isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Send Message'),
            ),
          ),
          const SizedBox(height: 20), // Extra space at the bottom
        ],
      ),
    );
  }
}
