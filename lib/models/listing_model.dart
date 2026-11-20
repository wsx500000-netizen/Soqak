class ListingModel {
  ListingModel({
    required this.id,
    required this.title,
    required this.category,
    required this.location,
    required this.price,
    required this.imageUrl,
    this.description = '',
    this.isFeatured = false,
  });

  final String id;
  final String title;
  final String category;
  final String location;
  final int price;
  final String imageUrl;
  final String description;
  final bool isFeatured;
}
