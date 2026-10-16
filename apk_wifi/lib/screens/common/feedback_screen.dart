import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/feedback_model.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/glowing_button.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _saranController = TextEditingController();
  final TextEditingController _kesanController = TextEditingController();
  List<FeedbackModel> _feedbacks = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadFeedback();
  }

  @override
  void dispose() {
    _saranController.dispose();
    _kesanController.dispose();
    super.dispose();
  }

  Future<void> _loadFeedback() async {
    final list = await ApiService.instance.getFeedback();
    if (mounted) {
      setState(() {
        _feedbacks = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSubmit() async {
    final saran = _saranController.text.trim();
    final kesan = _kesanController.text.trim();

    if (saran.isEmpty && kesan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tolong isi saran atau kesan Anda terlebih dahulu!'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final ok = await ApiService.instance.submitFeedback(saran: saran, kesan: kesan);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (ok) {
      _saranController.clear();
      _kesanController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Terima kasih! Saran & kesan Anda berhasil dikirim.'),
          backgroundColor: AppTheme.success,
        ),
      );
      _loadFeedback();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mengirimkan masukan. Coba lagi.'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saran & Kesan'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadFeedback,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              CustomCard(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withOpacity(0.15),
                    AppTheme.secondary.withOpacity(0.15),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryGlow,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.rate_review, color: AppTheme.primary, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Formulir Evaluasi & Masukan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Bantu kami meningkatkan kualitas layanan ISP fiber optic Sima.net.',
                            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Form Card
              CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Saran Perbaikan / Pengembangan',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _saranController,
                      maxLines: 3,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Contoh: Tambahkan pembayaran via e-wallet atau rute FO baru...',
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Kesan Layanan Sima.net',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _kesanController,
                      maxLines: 2,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Contoh: Internet sangat stabil, teknisi ramah dan tepat waktu...',
                      ),
                    ),
                    const SizedBox(height: 16),
                    GlowingButton(
                      text: 'KIRIM SARAN & KESAN',
                      icon: Icons.send,
                      isLoading: _isSubmitting,
                      width: double.infinity,
                      onPressed: _handleSubmit,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Feedback list section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Riwayat Saran & Kesan Pengguna',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  Text(
                    '${_feedbacks.length} masukan',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_feedbacks.isEmpty)
                const CustomCard(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'Belum ada saran & kesan. Jadilah yang pertama memberikan masukan!',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                )
              else
                ..._feedbacks.map((f) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: CustomCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: AppTheme.primary.withOpacity(0.2),
                                    child: Text(
                                      f.userNama.isNotEmpty ? f.userNama[0].toUpperCase() : 'U',
                                      style: const TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    f.userNama,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                f.formattedDate,
                                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                          if (f.saran.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('💡 ', style: TextStyle(fontSize: 13)),
                                Expanded(
                                  child: Text(
                                    'Saran: ${f.saran}',
                                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (f.kesan.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('💬 ', style: TextStyle(fontSize: 13)),
                                Expanded(
                                  child: Text(
                                    'Kesan: ${f.kesan}',
                                    style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
            ],
          ),
        ),
      ),
    );
  }
}
