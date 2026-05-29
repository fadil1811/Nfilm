import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../constants/app_colors.dart';

// =========================================================
// Widget item kartu film untuk diletakkan di grid beranda
// =========================================================
class MovieCard extends StatelessWidget {
  final Movie movie;
  const MovieCard({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/detail', arguments: movie),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface, 
          borderRadius: BorderRadius.circular(8), 
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(movie.poster, fit: BoxFit.cover),
                  _buildBadge(top: 8, left: 8, text: 'HD', color: AppColors.primary),
                  Positioned(
                    top: 8, right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(4)),
                      child: Row(children: [
                        const Icon(Icons.star, color: Colors.amber, size: 10), 
                        const SizedBox(width: 2),
                        Text(
                          movie.rating.toStringAsFixed(1), 
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber),
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.genres.join(', ').toUpperCase(), 
                    style: const TextStyle(fontSize: 9, color: AppColors.primary, fontWeight: FontWeight.bold), 
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    movie.title, 
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white), 
                    maxLines: 2, 
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(movie.year.toString(), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(4)),
                        child: Text(
                          movie.type == 'movie' ? 'Movie' : 'Series', 
                          style: const TextStyle(fontSize: 9, color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBadge({required double top, required double left, required String text, required Color color}) {
    return Positioned(
      top: top, left: left,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
        child: Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }
}