class CategoryModel {
  final String title;
  final String? image, svgSrc;
  final List<CategoryModel>? subCategories;

  CategoryModel({
    required this.title,
    this.image,
    this.svgSrc,
    this.subCategories,
  });
}

final List<CategoryModel> demoCategoriesWithImage = [
  CategoryModel(title: "نساء", image: "https://i.imgur.com/5M89G2P.png"),
  CategoryModel(title: "رجال", image: "https://i.imgur.com/UM3GdWg.png"),
  CategoryModel(title: "أطفال", image: "https://i.imgur.com/Lp0D6k5.png"),
  CategoryModel(title: "إكسسوارات", image: "https://i.imgur.com/3mSE5sN.png"),
];

final List<CategoryModel> demoCategories = [
  CategoryModel(
    title: "العروض",
    svgSrc: "assets/icons/Sale.svg",
    subCategories: [
      CategoryModel(title: "كل الملابس"),
      CategoryModel(title: "وصل حديثاً"),
      CategoryModel(title: "معاطف وجاكيتات"),
      CategoryModel(title: "فساتين"),
      CategoryModel(title: "جينز"),
    ],
  ),
  CategoryModel(
    title: "رجال ونساء",
    svgSrc: "assets/icons/Man&Woman.svg",
    subCategories: [
      CategoryModel(title: "كل الملابس"),
      CategoryModel(title: "وصل حديثاً"),
      CategoryModel(title: "معاطف وجاكيتات"),
    ],
  ),
  CategoryModel(
    title: "أطفال",
    svgSrc: "assets/icons/Child.svg",
    subCategories: [
      CategoryModel(title: "كل الملابس"),
      CategoryModel(title: "وصل حديثاً"),
      CategoryModel(title: "معاطف وجاكيتات"),
    ],
  ),
  CategoryModel(
    title: "إكسسوارات",
    svgSrc: "assets/icons/Accessories.svg",
    subCategories: [
      CategoryModel(title: "كل الإكسسوارات"),
      CategoryModel(title: "وصل حديثاً"),
    ],
  ),
];
