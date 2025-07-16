class Recipe {
  final int id;
  final String title;
  final String? imageUrl;
  final String description;

  Recipe({
    required this.id,
    required this.title,
    this.imageUrl,
    required this.description,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'],
      title: json['title'],
      imageUrl: json[
          'image'], 
      description: json['deskripsi_singkat'],
    );
  }


  String? get image => imageUrl;
}
