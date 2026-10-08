class Designer {
  final String name;
  final String imagePath;
  final String designation;
  final String? description;

  Designer({
    required this.name,
    required this.imagePath,
    required this.designation,
    this.description,
  });
}