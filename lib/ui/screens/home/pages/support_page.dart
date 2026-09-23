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
import '../../../theme/app_tokens.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/app_primary_button.dart';
import '../../../widgets/app_section_header.dart';

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
      backgroundColor: AppColors.brand,
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
                    textColor: AppColors.brand,
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
                    AppColors.brand,
                    AppColors.brandLight,
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
                        color: AppColors.brand,
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
                      AppCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const AppSectionHeader(title: "Contact Methods"),
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
                      // Messaging form — opens as a scrollable pop-up instead
                      // of sitting inline here, so it's reachable in one tap
                      // instead of scrolling all the way past Contact Methods
                      // to find it.
                      AppCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const AppSectionHeader(title: "Still need help?"),
                            const SizedBox(height: 8),
                            Text(
                              "Send our support team a message and we'll get back to you shortly.",
                              style: CustomStyles.smallTextStyle
                                  .copyWith(color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: AppPrimaryButton(
                                label: 'Send us a message',
                                icon: Icons.mail_outline,
                                onPressed: () =>
                                    _showSupportFormSheet(context),
                              ),
                            ),
                          ],
                        ),
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

  /// Opens the "Send us a message" form as a scrollable, draggable pop-up
  /// sheet rather than inline content — reachable in one tap, and the sheet
  /// itself scrolls internally so all five fields plus the submit button stay
  /// reachable even with the keyboard open on a small screen.
  void _showSupportFormSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Padding(
            // Keeps the focused field above the keyboard instead of hidden
            // behind it.
            padding:
                EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const _SupportForm(),
                ],
              ),
            ),
          ),
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
          const AppSectionHeader(title: "Send us a message"),
          const SizedBox(height: 20),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Full name',
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
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _subjectController,
            decoration: const InputDecoration(
              labelText: 'Subject',
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
            ),
            minLines: 3,
            maxLines: 6,
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Please enter your message'
                : null,
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: AppPrimaryButton(
              label: 'Send Message',
              isLoading: supportProvider.isSubmitting,
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
            ),
          ),
          const SizedBox(height: 20), // Extra space at the bottom
        ],
      ),
    );
  }
}
