class SocialMedia {
  final String link;
  final String title;

  SocialMedia({
    required this.link,
    required this.title,
  });

  factory SocialMedia.fromJson(Map<String, dynamic> json) {
    return SocialMedia(
      link: json['link'] as String,
      title: json['title'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'link': link,
      'title': title,
    };
  }
}
