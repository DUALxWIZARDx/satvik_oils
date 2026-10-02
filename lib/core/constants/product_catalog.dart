class CatalogProduct {
  const CatalogProduct({
    required this.id,
    required this.name,
    this.quantityVariants = ProductCatalog.quantityVariants,
  });

  final String id;
  final String name;
  final List<String> quantityVariants;
}

class ProductCatalog {
  const ProductCatalog._();

  static const List<String> quantityVariants = [
    '100ml',
    '250ml',
    '500ml',
    '1L',
    '2L',
    '5L',
  ];

  static const List<CatalogProduct> products = [
    CatalogProduct(id: 'groundnut_oil', name: 'Groundnut Oil'),
    CatalogProduct(id: 'coconut_oil', name: 'Coconut Oil'),
    CatalogProduct(id: 'white_sesame_oil', name: 'White Sesame Oil'),
    CatalogProduct(id: 'black_sesame_oil', name: 'Black Sesame Oil'),
    CatalogProduct(id: 'mustard_oil', name: 'Mustard Oil'),
    CatalogProduct(id: 'sunflower_oil', name: 'Sunflower Oil'),
    CatalogProduct(id: 'safflower_oil', name: 'Safflower Oil'),
    CatalogProduct(id: 'almond_oil', name: 'Almond Oil'),
  ];
}
