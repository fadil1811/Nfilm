// =========================================================
// Cetak biru (blueprint) data film untuk keamanan tipe data
// =========================================================
class Movie {
  final int id;
  final String title;
  final String type; // 'movie' atau 'series'
  final List<String> genres;
  final List<int> genreIds;
  final int year;
  final double rating;
  final String poster;
  final String backdrop;
  final String desc;
  final String country;

  Movie({
    required this.id,
    required this.title,
    required this.type,
    required this.genres,
    required this.genreIds,
    required this.year,
    required this.rating,
    required this.poster,
    required this.backdrop,
    required this.desc,
    required this.country,
  });
}