import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:frontend/api/api_service.dart';
import 'package:frontend/models/recipe_model.dart';
import 'package:frontend/screens/recipe/recipe_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _isSearching = false;
  String _searchQuery = '';
  List<Recipe> _searchResults = [];

  Map<String, List<dynamic>> _ingredientsByCategory = {};
  List<Map<String, dynamic>> _allIngredients = [];
  bool _isLoadingIngredients = true;

  List<String> _recentSearches = [];
  final TextEditingController _ingredientSearchController =
      TextEditingController();
  String _ingredientFilter = '';

  final List<String> _popularSearches = [
    'Rendang',
    'Gudeg',
    'Bakso',
    'Soto',
    'Rawon',
    'Pecel',
    'Ketoprak',
    'Laksa',
  ];

  String _selectedCategory = 'Semua';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _animationController.forward();
    _loadIngredients();
    _loadRecentSearches();
  }

  Future<void> _loadIngredients() async {
    try {
      final ingredientsByCategory = await _apiService.getIngredients();
      final List<Map<String, dynamic>> allIngredients = [];

      ingredientsByCategory.forEach((category, ingredients) {
        for (var ingredient in ingredients) {
          String ingredientName;
          if (ingredient is String) {
            ingredientName = ingredient;
          } else if (ingredient is Map &&
              ingredient.containsKey('nama_bahan')) {
            ingredientName = ingredient['nama_bahan'];
          } else {
            continue;
          }

          if (ingredientName.isNotEmpty) {
            allIngredients.add({
              'name': ingredientName,
              'category': category,
              'selected': false,
            });
          }
        }
      });

      if (mounted) {
        setState(() {
          _ingredientsByCategory = ingredientsByCategory;
          _allIngredients = allIngredients;
          _isLoadingIngredients = false;
        });
      }
    } catch (e) {
      print('Error loading ingredients: $e');
      if (mounted) {
        setState(() {
          _isLoadingIngredients = false;

          _allIngredients = [];
          _ingredientsByCategory = {};
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat daftar bahan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final searches = prefs.getStringList('recent_searches') ?? [];
      if (mounted) {
        setState(() {
          _recentSearches = searches;
        });
      }
    } catch (e) {
      print('Error loading recent searches: $e');
    }
  }

  Future<void> _saveRecentSearch(String query) async {
    if (query.isEmpty || query.contains(',')) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> searches = prefs.getStringList('recent_searches') ?? [];

      searches.remove(query);

      searches.insert(0, query);

      if (searches.length > 10) {
        searches = searches.sublist(0, 10);
      }

      await prefs.setStringList('recent_searches', searches);

      if (mounted) {
        setState(() {
          _recentSearches = searches;
        });
      }
    } catch (e) {
      print('Error saving recent search: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _ingredientSearchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) async {
    setState(() {
      _searchQuery = query;
      _isSearching = true;
    });

    HapticFeedback.lightImpact();

    try {
      List<Recipe> results;

      if (query.contains(',')) {
        List<String> ingredients =
            query.split(',').map((e) => e.trim()).toList();
        print('Searching with manual ingredients: $ingredients');
        results = await _apiService.getRecommendations(ingredients);
      } else {
        final allRecipes = await _apiService.getLatestRecipes();
        results = allRecipes
            .where((recipe) =>
                recipe.title.toLowerCase().contains(query.toLowerCase()))
            .toList();

        if (query.isNotEmpty) {
          _saveRecentSearch(query);
        }
      }

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      print('Search error: $e');
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mencari resep: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleIngredient(int index) {
    setState(() {
      _allIngredients[index]['selected'] = !_allIngredients[index]['selected'];
    });
    HapticFeedback.selectionClick();
  }

  List<Map<String, dynamic>> get _selectedIngredients {
    return _allIngredients
        .where((ingredient) => ingredient['selected'])
        .toList();
  }

  void _searchWithSelectedIngredients() async {
    if (_selectedIngredients.isEmpty) return;

    final ingredients =
        _selectedIngredients.map((e) => e['name'] as String).toList();
    final query = ingredients.join(', ');

    setState(() {
      _searchQuery = query;
      _isSearching = true;
    });

    HapticFeedback.lightImpact();

    try {
      print('Searching with selected ingredients: $ingredients');
      final results = await _apiService.getRecommendations(ingredients);

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      print('Search error: $e');
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mencari resep: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'protein':
      case 'daging':
        return '🥩';
      case 'sayuran':
      case 'vegetables':
        return '🥬';
      case 'buah':
      case 'fruits':
        return '🍎';
      case 'bumbu':
      case 'spices':
        return '🌶️';
      case 'biji-bijian':
      case 'grains':
        return '🌾';
      case 'seafood':
      case 'laut':
        return '🐟';
      case 'dairy':
      case 'susu':
        return '🥛';
      default:
        return '🥘';
    }
  }

  List<Map<String, dynamic>> _getIngredientsByCategory(String category) {
    if (category == 'Semua') {
      return _filteredIngredients;
    }
    return _filteredIngredients
        .where((ingredient) => ingredient['category'] == category)
        .toList();
  }

  List<String> get _uniqueCategories {
    Set<String> categories = {'Semua'};
    for (var ingredient in _allIngredients) {
      if (ingredient['category'] != null) {
        categories.add(ingredient['category'] as String);
      }
    }
    return categories.toList()..sort();
  }

  Widget _buildCategoryTabs() {
    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _uniqueCategories.length,
        itemBuilder: (context, index) {
          final category = _uniqueCategories[index];
          final isSelected = category == _selectedCategory;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF4CAF50) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      isSelected ? const Color(0xFF4CAF50) : Colors.grey[300]!,
                ),
              ),
              child: Text(
                category,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.grey[700],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              _buildHeader(),
              _buildSearchBar(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await _loadIngredients();
                  },
                  child: _searchQuery.isEmpty
                      ? _buildSearchSuggestions()
                      : _buildSearchResults(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cari Resep',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D3748),
                ),
              ),
              Text(
                'Temukan resep yang tepat untukmu',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const Spacer(),
          if (_selectedIngredients.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.filter_list,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_selectedIngredients.length}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          style: GoogleFonts.inter(fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Ketik nama makanan atau bahan...',
            hintStyle: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.grey[500],
            ),
            prefixIcon: Icon(
              Icons.search,
              color: Colors.grey[600],
              size: 24,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: Colors.grey[600],
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  )
                : Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.mic,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          onSubmitted: _performSearch,
        ),
      ),
    );
  }

  Widget _buildSearchSuggestions() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIngredientsSection(),
          const SizedBox(height: 32),
          _buildRecentSearches(),
          const SizedBox(height: 32),
          _buildPopularSearches(),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredIngredients {
    if (_ingredientFilter.isEmpty) {
      return _allIngredients;
    }
    return _allIngredients
        .where((ingredient) => ingredient['name']
            .toString()
            .toLowerCase()
            .contains(_ingredientFilter.toLowerCase()))
        .toList();
  }

  Widget _buildIngredientsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pilih Bahan',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2D3748),
              ),
            ),
            if (_selectedIngredients.isNotEmpty)
              TextButton(
                onPressed: () {
                  setState(() {
                    for (var ingredient in _allIngredients) {
                      ingredient['selected'] = false;
                    }
                  });
                },
                child: Text(
                  'Reset',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF4CAF50),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _ingredientSearchController,
          decoration: InputDecoration(
            hintText: 'Cari bahan...',
            prefixIcon: const Icon(Icons.search, size: 20),
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF4CAF50)),
            ),
            suffixIcon: _ingredientFilter.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _ingredientSearchController.clear();
                        _ingredientFilter = '';
                      });
                    },
                  )
                : null,
          ),
          onChanged: (value) {
            setState(() {
              _ingredientFilter = value;
            });
          },
        ),
        const SizedBox(height: 16),
        if (_isLoadingIngredients)
          const Center(
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 8),
                Text('Memuat daftar bahan...',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          )
        else if (_allIngredients.isEmpty)
          const Center(
            child: Text(
              'Tidak ada bahan tersedia',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _ingredientFilter.isEmpty
                      ? '${_allIngredients.length} bahan tersedia'
                      : '${_filteredIngredients.length} bahan ditemukan',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              _buildCategoryTabs(),
              SizedBox(
                height: 200,
                child: _filteredIngredients.isEmpty
                    ? Center(
                        child: Text(
                          'Bahan tidak ditemukan',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: List.generate(
                              _getIngredientsByCategory(_selectedCategory)
                                  .length, (index) {
                            final ingredient = _getIngredientsByCategory(
                                _selectedCategory)[index];
                            final isSelected = ingredient['selected'];

                            final originalIndex = _allIngredients.indexWhere(
                                (e) => e['name'] == ingredient['name']);

                            return GestureDetector(
                              onTap: () => _toggleIngredient(originalIndex),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF4CAF50)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF4CAF50)
                                        : Colors.grey[300]!,
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 5,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _getIconForCategory(
                                          ingredient['category'] ?? ''),
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      ingredient['name'] ?? '',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: isSelected
                                            ? Colors.white
                                            : const Color(0xFF2D3748),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
              ),
              if (_selectedIngredients.isNotEmpty) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      _searchWithSelectedIngredients();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cari Resep dengan ${_selectedIngredients.length} Bahan',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
      ],
    );
  }

  Widget _buildRecentSearches() {
    if (_recentSearches.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pencarian Terakhir',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2D3748),
              ),
            ),
            TextButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('recent_searches');
                if (mounted) {
                  setState(() {
                    _recentSearches = [];
                  });
                }
              },
              child: Text(
                'Hapus',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _recentSearches.map((search) {
            return GestureDetector(
              onTap: () => _performSearch(search),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.history,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      search,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF2D3748),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPopularSearches() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pencarian Populer',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _popularSearches.map((search) {
            return GestureDetector(
              onTap: () => _performSearch(search),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFFF6B35).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.trending_up,
                      size: 16,
                      color: const Color(0xFFFF6B35),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      search,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFFFF6B35),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Color(0xFF4CAF50),
            ),
            SizedBox(height: 16),
            Text('Mencari resep...'),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty && _searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Tidak ada resep ditemukan',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coba kata kunci lain atau pilih bahan',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Hasil untuk "$_searchQuery"',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D3748),
                ),
              ),
              const Spacer(),
              Text(
                '${_searchResults.length} resep',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                return _buildSearchResultCard(_searchResults[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultCard(Recipe recipe) {
    return Hero(
      tag: 'recipe-${recipe.id}',
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  RecipeDetailScreen(recipe: recipe),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                );
              },
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  image: recipe.imageUrl?.isNotEmpty == true
                      ? DecorationImage(
                          image: NetworkImage(recipe.imageUrl!),
                          fit: BoxFit.cover,
                          onError: (exception, stackTrace) {},
                        )
                      : null,
                ),
                child: recipe.imageUrl?.isNotEmpty != true
                    ? const Icon(
                        Icons.restaurant,
                        color: Color(0xFFFF6B35),
                        size: 32,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2D3748),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      recipe.description,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildTag('30 min', Icons.access_time),
                        _buildTag('⭐ 4.5', Icons.star),
                        if (recipe.description.toLowerCase().contains("ayam"))
                          _buildTag('Ayam', Icons.food_bank),
                        if (recipe.description.toLowerCase().contains("pedas"))
                          _buildTag('Pedas', Icons.whatshot),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
