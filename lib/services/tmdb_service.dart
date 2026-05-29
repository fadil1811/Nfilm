import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/movie.dart';

class TmdbService {
  static const String _token = "eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI1NGJiZmUxNTFjZTFhNGFjOTI0NTU5OTljNGIwNzYyZSIsIm5iZiI6MTc3OTg4NzYzNy4xLCJzdWIiOiI2YTE2ZWUxNWRiMDY0YjQ3ZGNiNDYyYjMiLCJzY29wZXMiOlsiYXBpX3JlYWQiXSwidmVyc2lvbiI6MX0.Cu7k0DnSKGMq8xaCyWYbu8K39WYPWcmi1byTECxDooA";
  static const String _baseUrl = "https://api.themoviedb.org/3";
  static const String _imageBaseUrl = "https://image.tmdb.org/t/p/w500";
  static const String _backdropBaseUrl = "https://image.tmdb.org/t/p/original";

  static const Map<int, String> genreMap = {
    28: 'Action', 12: 'Adventure', 16: 'Animation', 35: 'Comedy', 80: 'Crime',
    99: 'Documentary', 18: 'Drama', 10751: 'Family', 14: 'Fantasy', 36: 'History',
    27: 'Horror', 10402: 'Music', 9648: 'Mystery', 10749: 'Romance', 878: 'Sci-Fi',
    10759: 'Action & Adventure', 10762: 'Kids', 10765: 'Sci-Fi & Fantasy'
  };

  Map<String, String> get _headers => {'Authorization': 'Bearer $_token', 'Content-Type': 'application/json'};

  Future<List<Movie>> fetchPopular(String type) async {
    final url = type == 'movie' ? '$_baseUrl/movie/popular?language=id-ID' : '$_baseUrl/tv/popular?language=id-ID';
    try {
      final res = await http.get(Uri.parse(url), headers: _headers);
      if (res.statusCode == 200) return _parseResults(json.decode(res.body)['results'], type);
    } catch (_) {}
    return [];
  }

  Future<List<Movie>> search(String query) async {
    if (query.isEmpty) return [];
    try {
      final res = await http.get(Uri.parse('$_baseUrl/search/multi?query=${Uri.encodeComponent(query)}&language=id-ID'), headers: _headers);
      if (res.statusCode == 200) {
        final results = json.decode(res.body)['results'] as List;
        return _parseResults(results.where((i) => i['media_type'] == 'movie' || i['media_type'] == 'tv').toList(), '');
      }
    } catch (_) {}
    return [];
  }

  List<Movie> _parseResults(List data, String defaultType) {
    return data.map((item) {
      final isMovie = item['media_type'] == 'movie' || defaultType == 'movie';
      final gIds = List<int>.from(item['genre_ids'] ?? []);
      return Movie(
        id: item['id'],
        title: item['title'] ?? item['name'] ?? item['original_title'] ?? 'Untitled',
        type: isMovie ? 'movie' : 'series',
        genres: gIds.isEmpty ? ['General'] : gIds.map((id) => genreMap[id] ?? 'Drama').take(2).toList(),
        genreIds: gIds,
        year: _parseYear(isMovie ? item['release_date'] : item['first_air_date']),
        rating: (item['vote_average'] as num?)?.toDouble() ?? 0.0,
        poster: item['poster_path'] != null ? '$_imageBaseUrl${item['poster_path']}' : 'https://images.unsplash.com/photo-1440404653325-ab127d49abc1?q=80&w=600',
        backdrop: item['backdrop_path'] != null ? '$_backdropBaseUrl${item['backdrop_path']}' : '',
        desc: item['overview'] ?? 'Sinopsis tidak tersedia.',
        country: (item['origin_country'] != null && (item['origin_country'] as List).isNotEmpty) ? item['origin_country'][0] : (isMovie ? 'US' : 'KR'),
      );
    }).toList();
  }

  int _parseYear(String? date) => (date == null || date.isEmpty) ? 2026 : (DateTime.tryParse(date)?.year ?? 2026);
}