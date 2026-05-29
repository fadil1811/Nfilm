import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import '../models/movie.dart';
import '../constants/app_colors.dart';

// =========================================================================
// Halaman Detail & Pemutar Video WebView - Terkunci di Dalam Aplikasi (No Browser)
// Dioptimalkan dengan Pemblokir Iklan Otomatis (Ad-Blocker) & Akselerasi Speed
// =========================================================================
class DetailScreen extends StatefulWidget {
  final Movie movie;
  const DetailScreen({super.key, required this.movie});
  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late final WebViewController _controller;
  int _season = 1, _episode = 1;
  bool _isBookmarked = false;
  bool _isLoadingVideo = true;
  Timer? _loadingTimeout;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  @override
  void dispose() {
    _loadingTimeout?.cancel();
    super.dispose();
  }

  void _initPlayer() {
    // 1. Konfigurasi platform untuk mengizinkan pemutaran inline media tanpa batasan gestur di iOS
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // Gunakan User-Agent Safari/Chrome mobile yang sangat ringan dan efisien untuk mempercepat handshake CDN
      ..setUserAgent("Mozilla/5.0 (iPhone; CPU iPhone OS 17_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Mobile/15E148 Safari/604.1")
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoadingVideo = true;
            });
            
            // AUTO-DISMISS TIMEOUT: Paksa hilangkan layar loading setelah 6 detik 
            // agar tombol play tidak tertutup selamanya meskipun ada pelacak iklan yang diblokir.
            _loadingTimeout?.cancel();
            _loadingTimeout = Timer(const Duration(seconds: 6), () {
              if (mounted) {
                setState(() {
                  _isLoadingVideo = false;
                });
              }
            });
          },
          onPageFinished: (String url) {
            _loadingTimeout?.cancel();
            if (mounted) {
              setState(() {
                _isLoadingVideo = false;
              });
            }
            // Bersihkan data penyimpanan sisa (cookies/storage) dari iklan yang lolos untuk melonggarkan memori RAM
            _controller.clearLocalStorage();
          },
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url.toLowerCase();
            
            // 1. KUNCI UTAMA: Izinkan semua lalu lintas domain video resmi TERLEBIH DAHULU.
            // Langkah ini mencegah domain resmi terblokir jika mereka memiliki parameter "pop" atau "ads" di URL-nya.
            final isAllowedDomain = url.contains('vidsrc') || 
                                    url.contains('2embed') || 
                                    url.contains('recaptcha') || 
                                    url.contains('google.com/recaptcha') ||
                                    url.contains('gstatic') ||
                                    url.contains('cloudflare') ||
                                    url.contains('stream') ||
                                    url.contains('player') ||
                                    url.contains('embed') ||
                                    url.contains('m3u8') ||
                                    url.contains('vtt');

            if (isAllowedDomain) {
              return NavigationDecision.navigate;
            }

            // 2. AD-BLOCKER: Blokir domain iklan eksternal, popup, popunder, dan tracker pelambat stream
            final isSpamOrAd = url.contains('click') || 
                               url.contains('pop') || 
                               url.contains('ads') || 
                               url.contains('adsystem') || 
                               url.contains('banner') || 
                               url.contains('doubleclick') || 
                               url.contains('creative') || 
                               url.contains('analytics') || 
                               url.contains('histats') || 
                               url.contains('traffic') || 
                               url.contains('stat') || 
                               url.contains('count') || 
                               url.contains('crypto') || 
                               url.contains('coin') || 
                               url.contains('miner') || 
                               url.contains('bet') || 
                               url.contains('casino') || 
                               url.contains('poker') || 
                               url.contains('slot');

            if (isSpamOrAd) {
              // Blokir aktivitas pemuatan iklan sesegera mungkin
              return NavigationDecision.prevent;
            }
            
            // Blokir skema non-http
            if (!url.startsWith('http://') && !url.startsWith('https://')) {
              return NavigationDecision.prevent;
            }
            
            // Batasi navigasi liar lainnya agar bandwidth fokus ke stream video utama
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse(_getEmbedUrl()));

    // 3. Konfigurasi platform Android khusus untuk menonaktifkan batasan gestur pemutaran media
    final platform = _controller.platform;
    if (platform is AndroidWebViewController) {
      platform.setMediaPlaybackRequiresUserGesture(false);
    }
  }

  String _getEmbedUrl() => widget.movie.type == 'movie' 
      ? "https://vidsrc.to/embed/movie/${widget.movie.id}" 
      : "https://vidsrc.to/embed/tv/${widget.movie.id}/$_season/$_episode";

  void _updatePlayer() {
    _controller.loadRequest(Uri.parse(_getEmbedUrl()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.movie.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Area Pemutar Video Iframe 16:9 dengan Indikator Loading khusus
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                children: [
                  WebViewWidget(controller: _controller),
                  if (_isLoadingVideo)
                    Container(
                      color: Colors.black,
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: AppColors.primary),
                            SizedBox(height: 12),
                            Text(
                              'Menyiapkan pemutar video...',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            )
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Kontrol Panel Video
            Container(
              padding: const EdgeInsets.all(12), 
              color: AppColors.background,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildServerBadge(),
                      // Menampilkan info mode pemutaran aman
                      const Row(
                        children: [
                          Icon(Icons.flash_on, color: Colors.amber, size: 16),
                          SizedBox(width: 4),
                          Text('Mode Cepat & Aman Aktif', style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      )
                    ],
                  ),
                  if (widget.movie.type == 'series') ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildDropdown(value: _season, max: 4, prefix: 'Season', onChanged: (v) { setState(() => _season = v!); _updatePlayer(); })),
                        const SizedBox(width: 12),
                        Expanded(child: _buildDropdown(value: _episode, max: 20, prefix: 'Episode', onChanged: (v) { setState(() => _episode = v!); _updatePlayer(); })),
                      ],
                    ),
                  ]
                ],
              ),
            ),

            // Metadata Detail Film
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    _buildBadge(widget.movie.type.toUpperCase(), AppColors.primary), const SizedBox(width: 8),
                    _buildBadge('HD', Colors.amber), const SizedBox(width: 8),
                    const Icon(Icons.star, color: Colors.amber, size: 16), const SizedBox(width: 4),
                    Text(widget.movie.rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const Spacer(),
                    Text(widget.movie.year.toString(), style: const TextStyle(color: Colors.grey, fontSize: 14)),
                  ]),
                  const SizedBox(height: 16),
                  Text(widget.movie.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.border),
                  _buildDetailRow('Genre', widget.movie.genres.join(', ')),
                  _buildDetailRow('Asal Negara', widget.movie.country),
                  _buildDetailRow('Subtitle', 'Indonesia (Hardsub)'),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 8),
                  const Text('Sinopsis Singkat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(widget.movie.desc, style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.5)),
                  const SizedBox(height: 24),
                  _buildActionButtons(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServerBadge() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.2), border: Border.all(color: AppColors.primary.withOpacity(0.5)), borderRadius: BorderRadius.circular(4)),
    child: Row(children: [
      Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
      const SizedBox(width: 6), 
      const Text('Server Utama (VidSrc)', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
    ]),
  );

  Widget _buildDropdown({required int value, required int max, required String prefix, required Function(int?) onChanged}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.border)),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<int>(
        value: value, isExpanded: true, dropdownColor: AppColors.surface, icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
        items: List.generate(max, (i) => DropdownMenuItem(value: i + 1, child: Text('$prefix ${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 13)))),
        onChanged: onChanged,
      ),
    ),
  );

  Widget _buildBadge(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: color.withOpacity(0.2), border: Border.all(color: color.withOpacity(0.5)), borderRadius: BorderRadius.circular(4)),
    child: Text(text, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
  );

  Widget _buildDetailRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6.0),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13))),
      Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))),
    ]),
  );

  Widget _buildActionButtons() => Row(children: [
    Expanded(child: ElevatedButton.icon(
      onPressed: () => setState(() => _isBookmarked = !_isBookmarked),
      icon: Icon(_isBookmarked ? Icons.bookmark : Icons.bookmark_border),
      label: Text(_isBookmarked ? 'Tersimpan' : 'Daftar Tonton'),
      style: ElevatedButton.styleFrom(backgroundColor: AppColors.surface, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
    )),
    const SizedBox(width: 12),
    Expanded(child: ElevatedButton.icon(
      onPressed: () {}, icon: const Icon(Icons.share_outlined), label: const Text('Bagikan'),
      style: ElevatedButton.styleFrom(backgroundColor: AppColors.surface, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
    )),
  ]);
}