import 'package:flutter/material.dart';
import '../models/banner_model.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';

class ProductProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  // Home Screen Data
  List<BannerModel> _banners = [];
  List<CategoryModel> _categories = [];
  List<ProductModel> _featuredProducts = [];
  List<ProductModel> _bestsellerProducts = [];
  List<ProductModel> _newArrivalProducts = [];
  List<ProductModel> _goldProducts = [];
  List<ProductModel> _brassProducts = [];
  List<ProductModel> _copperProducts = [];
  bool _isLoadingHome = false;
  String? _homeError;

  // Listing Screen Data
  List<ProductModel> _listingProducts = [];
  bool _isLoadingListing = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _pageSize = 20;
  String? _listingError;

  // Active Filters & Sorting
  String? _searchQuery;
  int? _selectedCategoryId;
  int? _selectedSubcategoryId;
  String? _selectedMaterial;
  double? _minPrice;
  double? _maxPrice;
  bool? _inStockOnly;
  String _selectedSortBy = 'relevance'; // relevance, newest, price_low_high, price_high_low, popularity

  // Search autocomplete suggestions
  List<ProductModel> _searchSuggestions = [];
  bool _isSearching = false;

  // Getters
  List<BannerModel> get banners => _banners;
  List<CategoryModel> get categories => _categories;
  List<ProductModel> get featuredProducts => _featuredProducts;
  List<ProductModel> get bestsellerProducts => _bestsellerProducts;
  List<ProductModel> get newArrivalProducts => _newArrivalProducts;
  List<ProductModel> get goldProducts => _goldProducts;
  List<ProductModel> get brassProducts => _brassProducts;
  List<ProductModel> get copperProducts => _copperProducts;
  bool get isLoadingHome => _isLoadingHome;
  String? get homeError => _homeError;

  List<ProductModel> get listingProducts => _listingProducts;
  bool get isLoadingListing => _isLoadingListing;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get listingError => _listingError;

  String? get searchQuery => _searchQuery;
  int? get selectedCategoryId => _selectedCategoryId;
  int? get selectedSubcategoryId => _selectedSubcategoryId;
  String? get selectedMaterial => _selectedMaterial;
  double? get minPrice => _minPrice;
  double? get maxPrice => _maxPrice;
  bool? get inStockOnly => _inStockOnly;
  String get selectedSortBy => _selectedSortBy;
  List<ProductModel> get searchSuggestions => _searchSuggestions;
  bool get isSearching => _isSearching;

  // Load Home Screen Dynamic Data
  Future<void> loadHomeData() async {
    _isLoadingHome = true;
    _homeError = null;
    notifyListeners();

    try {
      // Parallel fetch for speed
      final results = await Future.wait([
        _apiService.getBanners().catchError((_) => <BannerModel>[]),
        _apiService.getCategories().catchError((_) => <CategoryModel>[]),
        _apiService.getProducts(isFeatured: true, limit: 8).catchError((_) => <ProductModel>[]),
        _apiService.getProducts(isBestseller: true, limit: 8).catchError((_) => <ProductModel>[]),
        _apiService.getProducts(isNewArrival: true, limit: 8).catchError((_) => <ProductModel>[]),
        _apiService.getProducts(material: 'Gold', limit: 8).catchError((_) => <ProductModel>[]),
        _apiService.getProducts(material: 'Brass', limit: 8).catchError((_) => <ProductModel>[]),
        _apiService.getProducts(material: 'Copper', limit: 8).catchError((_) => <ProductModel>[]),
      ]);

      _banners = results[0] as List<BannerModel>;
      _categories = results[1] as List<CategoryModel>;
      _featuredProducts = results[2] as List<ProductModel>;
      _bestsellerProducts = results[3] as List<ProductModel>;
      _newArrivalProducts = results[4] as List<ProductModel>;
      _goldProducts = results[5] as List<ProductModel>;
      _brassProducts = results[6] as List<ProductModel>;
      _copperProducts = results[7] as List<ProductModel>;

      // If category-specific lists are empty, filter from all products
      if (_goldProducts.isEmpty || _brassProducts.isEmpty || _copperProducts.isEmpty) {
        final all = await _apiService.getProducts(limit: 50).catchError((_) => <ProductModel>[]);
        if (_goldProducts.isEmpty) {
          _goldProducts = all.where((p) => p.isGoldJewellery).take(8).toList();
        }
        if (_brassProducts.isEmpty) {
          _brassProducts = all.where((p) => p.material?.toLowerCase().contains('brass') == true).take(8).toList();
        }
        if (_copperProducts.isEmpty) {
          _copperProducts = all.where((p) => p.material?.toLowerCase().contains('copper') == true).take(8).toList();
        }
      }
    } catch (e) {
      _homeError = 'Failed to load store catalog. Please check connection.';
    } finally {
      _isLoadingHome = false;
      notifyListeners();
    }
  }

  // Load Products with Filters & Pagination
  Future<void> fetchProducts({
    bool refresh = false,
    String? search,
    int? categoryId,
    int? subcategoryId,
    String? material,
    double? minPrice,
    double? maxPrice,
    bool? inStock,
    String? sortBy,
  }) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _listingProducts.clear();
      _isLoadingListing = true;
      _listingError = null;

      // Update active filters if provided
      if (search != null) _searchQuery = search;
      if (categoryId != null) _selectedCategoryId = categoryId;
      if (subcategoryId != null) _selectedSubcategoryId = subcategoryId;
      if (material != null) _selectedMaterial = material;
      if (minPrice != null) _minPrice = minPrice;
      if (maxPrice != null) _maxPrice = maxPrice;
      if (inStock != null) _inStockOnly = inStock;
      if (sortBy != null) _selectedSortBy = sortBy;
    } else {
      if (_isLoadingMore || !_hasMore) return;
      _isLoadingMore = true;
    }

    notifyListeners();

    try {
      final items = await _apiService.getProducts(
        search: _searchQuery,
        categoryId: _selectedCategoryId,
        subcategoryId: _selectedSubcategoryId,
        material: _selectedMaterial,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        inStock: _inStockOnly,
        sortBy: _selectedSortBy,
        page: _currentPage,
        limit: _pageSize,
      );

      if (refresh) {
        _listingProducts = items;
      } else {
        _listingProducts.addAll(items);
      }

      if (items.length < _pageSize) {
        _hasMore = false;
      } else {
        _currentPage++;
      }
    } catch (e) {
      _listingError = 'Failed to load products.';
    } finally {
      _isLoadingListing = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // Live autocomplete search
  Future<void> searchSuggestionsFor(String query) async {
    if (query.trim().length < 2) {
      _searchSuggestions = [];
      _isSearching = false;
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    try {
      final results = await _apiService.getProducts(search: query.trim(), limit: 6);
      _searchSuggestions = results;
    } catch (_) {
      _searchSuggestions = [];
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  void clearSearchSuggestions() {
    _searchSuggestions = [];
    _isSearching = false;
    notifyListeners();
  }

  void resetFilters() {
    _searchQuery = null;
    _selectedCategoryId = null;
    _selectedSubcategoryId = null;
    _selectedMaterial = null;
    _minPrice = null;
    _maxPrice = null;
    _inStockOnly = null;
    _selectedSortBy = 'relevance';
    notifyListeners();
  }

  // Fetch single product details with related items
  Future<ProductModel?> getProductDetails(int id) async {
    try {
      return await _apiService.getProductDetails(id);
    } catch (_) {
      return null;
    }
  }

  Future<List<ProductModel>> getRelatedProducts(ProductModel product) async {
    try {
      final list = await _apiService.getProducts(
        categoryId: product.categoryId,
        limit: 6,
      );
      return list.where((p) => p.id != product.id).take(4).toList();
    } catch (_) {
      return [];
    }
  }
}
