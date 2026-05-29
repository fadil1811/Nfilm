import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/movie.dart';
import '../services/tmdb_service.dart';
import '../widgets/movie_card.dart';
import '../widgets/filter_chip.dart';
import '../constants/app_colors.dart';

// =========================================================
// Tampilan Halaman Utama / Beranda Nfilm PRO (HP Optimized)
// =========================================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TmdbService _api = TmdbService();
  
  List<Movie> _allData = [], _filteredData = [], _heroes = [];
  bool _isLoading = true;
  int _heroIndex = 0;
  
  String _category = 'all', _genre = 'all', _country = 'all', _sort = 'recent';

  @override
  void initState() { 
    super.initState(); 
    _loadData(); 
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final movies = await _api.fetchPopular('movie');
    final series = await _api.fetchPopular('series');
    if (mounted) {
      setState(() {
        _allData = [...movies, ...series];
        _heroes = List.from(_allData)..sort((a, b) => b.rating.compareTo(a.rating));
        if (_heroes.length > 4) _heroes = _heroes.take(4).toList();
        _applyFilters();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    var data = List<Movie>.from(_allData);
    if (_category != 'all') data = data.where((m) => m.type == _category).toList();
    if (_genre != 'all') data = data.where((m) => m.genreIds.contains(int.parse(_genre))).toList();
    if (_country != 'all') data = data.where((m) => m.country == _country).toList();

    if (_sort == 'rating') {
      data.sort((a, b) => b.rating.compareTo(a.rating));
    } else if (_sort == 'year') {
      data.sort((a, b) => b.year.compareTo(a.year));
    } else {
      data.sort((a, b) => b.id.compareTo(a.id));
    }

    setState(() => _filteredData = data);
  }

  Future<void> _search(String query) async {
    if (query.isEmpty) return _applyFilters();
    setState(() => _isLoading = true);
    final results = await _api.search(query);
    setState(() { 
      _filteredData = results; 
      _isLoading = false; 
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('N', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 28, letterSpacing: 1)),
            const Text('film', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), 
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4)), 
              child: const Text('PRO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
            )
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey), 
            onPressed: () { 
              setState(() {
                _category = 'all'; 
                _genre = 'all'; 
                _country = 'all'; 
              });
              _loadData(); 
            },
          )
        ],
      ),
      body: _isLoading && _allData.isEmpty 
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadData, 
              color: AppColors.primary,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  _buildLiveStreamBanner(),
                  _buildSearchBar(),
                  if (_heroes.isNotEmpty) _buildHeroSlider(),
                  _buildCategoryFilters(),
                  _buildGenreFilters(),
                  _buildSectionTitle(),
                  _buildMovieGrid(),
                ],
              ),
            ),
    );
  }

  Widget _buildLiveStreamBanner() {
    return Container(
      color: AppColors.primary, 
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: const Row(children: [
        Icon(FontAwesomeIcons.bolt, size: 14, color: Colors.white), 
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'Mode Live Streaming Aktif - Memutar via VidSrc API!', 
            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
      ]),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        onChanged: _search, 
        style: const TextStyle(fontSize: 14, color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Cari film atau serial favorit...', 
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
          filled: true, 
          fillColor: AppColors.surface, 
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: AppColors.primary)),
        ),
      ),
    );
  }

  Widget _buildHeroSlider() {
    final hero = _heroes[_heroIndex];
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/detail', arguments: hero),
      child: Container(
        height: 240, 
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: DecorationImage(
            image: NetworkImage(hero.backdrop.isNotEmpty ? hero.backdrop : hero.poster), 
            fit: BoxFit.cover, 
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.65), BlendMode.darken),
          ),
        ),
        child: Stack(children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end, 
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), 
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4)), 
                    child: const Text('TREN SEKARANG', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  const SizedBox(width: 8), 
                  const Icon(Icons.star, color: Colors.amber, size: 14), 
                  const SizedBox(width: 4),
                  Text(hero.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 12, color: Colors.amber, fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 6),
                Text(hero.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(hero.desc, style: const TextStyle(fontSize: 12, color: Colors.white70), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Positioned(
            top: 12, right: 12,
            child: Row(children: [
              GestureDetector(
                onTap: () => setState(() => _heroIndex = (_heroIndex - 1 + _heroes.length) % _heroes.length), 
                child: const CircleAvatar(radius: 14, backgroundColor: Colors.black54, child: Icon(Icons.chevron_left, size: 18, color: Colors.white)),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => _heroIndex = (_heroIndex + 1) % _heroes.length), 
                child: const CircleAvatar(radius: 14, backgroundColor: Colors.black54, child: Icon(Icons.chevron_right, size: 18, color: Colors.white)),
              ),
            ]),
          )
        ]),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal, 
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        FilterChipWidget(
          label: 'Semua', 
          isSelected: _category == 'all' && _country == 'all', 
          onTap: () { setState(() { _category = 'all'; _country = 'all'; }); _applyFilters(); },
        ),
        FilterChipWidget(
          label: 'Movies', 
          isSelected: _category == 'movie', 
          onTap: () { setState(() { _category = 'movie'; _country = 'all'; }); _applyFilters(); },
        ),
        FilterChipWidget(
          label: 'TV Series', 
          isSelected: _category == 'series', 
          onTap: () { setState(() { _category = 'series'; _country = 'all'; }); _applyFilters(); },
        ),
        FilterChipWidget(
          label: 'West Movies', 
          isSelected: _country == 'US', 
          onTap: () { setState(() { _country = 'US'; _category = 'all'; }); _applyFilters(); },
        ),
        FilterChipWidget(
          label: 'K-Drama', 
          isSelected: _country == 'KR', 
          onTap: () { setState(() { _country = 'KR'; _category = 'all'; }); _applyFilters(); },
        ),
      ]),
    );
  }

  Widget _buildGenreFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal, 
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        FilterChipWidget(
          label: 'Semua Genre', 
          isOutline: true, 
          isSelected: _genre == 'all', 
          onTap: () { setState(() => _genre = 'all'); _applyFilters(); },
        ),
        ...TmdbService.genreMap.entries.map((e) => FilterChipWidget(
          label: e.value, 
          isOutline: true, 
          isSelected: _genre == e.key.toString(), 
          onTap: () { setState(() => _genre = e.key.toString()); _applyFilters(); },
        ))
      ]),
    );
  }

  Widget _buildSectionTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Container(width: 4, height: 20, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8), 
            const Text('Katalog Film', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          ]),
          DropdownButton<String>(
            value: _sort, 
            dropdownColor: AppColors.surface, 
            underline: const SizedBox(),
            icon: const Icon(Icons.filter_list, size: 18, color: Colors.grey),
            style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
            items: const [
              DropdownMenuItem(value: 'recent', child: Text('Terpopuler ')),
              DropdownMenuItem(value: 'rating', child: Text('Rating ')),
              DropdownMenuItem(value: 'year', child: Text('Tahun ')),
            ],
            onChanged: (val) { if (val != null) { setState(() => _sort = val); _applyFilters(); } },
          ),
        ],
      ),
    );
  }

  Widget _buildMovieGrid() {
    if (_filteredData.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40), 
        child: Center(child: Text('Tidak ada film yang cocok.', style: TextStyle(color: Colors.grey))),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 40),
      child: GridView.builder(
        shrinkWrap: true, 
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _filteredData.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, 
          childAspectRatio: 0.65, 
          crossAxisSpacing: 12, 
          mainAxisSpacing: 16,
        ),
        itemBuilder: (_, index) => MovieCard(movie: _filteredData[index]),
      ),
    );
  }
}