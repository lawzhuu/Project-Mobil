import '../models/ledger_model.dart';
import 'api_service.dart';

class VerificationResult {
  final bool isValid;
  final int totalBlocks;
  final int? corruptedBlockIndex;
  final String message;

  VerificationResult({
    required this.isValid,
    required this.totalBlocks,
    this.corruptedBlockIndex,
    required this.message,
  });
}

class BlockchainService {
  static final BlockchainService instance = BlockchainService._internal();
  BlockchainService._internal();

  // ==============================================================================
  // FITUR SCAN 6: AUDIT SCAN INTEGRITAS BLOCKCHAIN LEDGER (SHA-256 CRYPTOGRAPHIC SCAN)
  // ==============================================================================
  // Cara kerja Audit Integritas:
  // 1. LINKAGE SCAN (Pemeriksaan Rantai Penghubung):
  //    - Memastikan nilai 'prevHash' pada blok ke-N sama persis dengan 'hash' pada blok ke-(N-1).
  //    - Jika ada baris pembayaran yang diselundupkan atau dihapus, rantai otomatis terputus!
  // 2. CRYPTOGRAPHIC DIGEST SCAN (Pemeriksaan Sidik Jari Kriptografi SHA-256):
  //    - Menghitung ulang (recalculate) nilai SHA-256 dari seluruh payload data blok.
  //    - Berkat Avalanche Effect pada algoritma SHA-256: Jika ada 1 huruf saja di database
  //      yang diubah oleh hacker, nilai hash baru akan berbeda 100%, sehingga audit scan
  //      langsung mendeteksi manipulasi (Tamper Detection).
  // ==============================================================================
  VerificationResult verifyLocalChain(List<LedgerBlockModel> chain) {
    if (chain.isEmpty) {
      return VerificationResult(
        isValid: true,
        totalBlocks: 0,
        message: 'Rantai ledger kosong. Belum ada pembayaran diverifikasi.',
      );
    }

    for (int i = 0; i < chain.length; i++) {
      final block = chain[i];

      // Check linkage with previous block
      if (i > 0) {
        final prevBlock = chain[i - 1];
        if (block.prevHash != prevBlock.hash) {
          return VerificationResult(
            isValid: false,
            totalBlocks: chain.length,
            corruptedBlockIndex: block.idx,
            message: 'Rantai terputus pada Block #${block.idx}: prev_hash tidak identik dengan hash Block #${prevBlock.idx}.',
          );
        }
      }

      // Check SHA-256 cryptographic digest integrity
      if (!block.isHashValid) {
        return VerificationResult(
          isValid: false,
          totalBlocks: chain.length,
          corruptedBlockIndex: block.idx,
          message: 'Integritas Block #${block.idx} rusak: digest hash tersimpan tidak sesuai dengan recalculate SHA-256.',
        );
      }
    }

    return VerificationResult(
      isValid: true,
      totalBlocks: chain.length,
      message: 'Semua ${chain.length} block pada ledger terbukti valid dan terverifikasi secara matematis SHA-256 tanpa manipulasi.',
    );
  }

  // Verify against backend server
  Future<VerificationResult> verifyServerChain() async {
    final res = await ApiService.instance.verifyLedger();
    if (res['success'] == true) {
      return VerificationResult(
        isValid: res['is_valid'] == true,
        totalBlocks: res['total_blocks'] ?? 0,
        corruptedBlockIndex: res['corrupted_index'],
        message: res['message'] ?? 'Verifikasi selesai.',
      );
    }
    return VerificationResult(
      isValid: false,
      totalBlocks: 0,
      message: res['message'] ?? 'Gagal menghubungi server.',
    );
  }
}
