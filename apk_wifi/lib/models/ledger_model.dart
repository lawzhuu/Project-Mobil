import 'dart:convert';
import 'package:crypto/crypto.dart';

class LedgerBlockModel {
  final int idx;
  final String waktu;
  final int paymentId;
  final int nominalIdr;
  final String prevHash;
  final String hash;

  LedgerBlockModel({
    required this.idx,
    required this.waktu,
    required this.paymentId,
    required this.nominalIdr,
    required this.prevHash,
    required this.hash,
  });

  factory LedgerBlockModel.fromJson(Map<String, dynamic> json) {
    return LedgerBlockModel(
      idx: json['idx'] is int ? json['idx'] : int.tryParse(json['idx'].toString()) ?? 0,
      waktu: json['waktu'] ?? '',
      paymentId: json['payment_id'] is int ? json['payment_id'] : int.tryParse(json['payment_id'].toString()) ?? 0,
      nominalIdr: json['nominal_idr'] is int ? json['nominal_idr'] : int.tryParse(json['nominal_idr'].toString()) ?? 0,
      prevHash: json['prev_hash'] ?? '',
      hash: json['hash'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idx': idx,
      'waktu': waktu,
      'payment_id': paymentId,
      'nominal_idr': nominalIdr,
      'prev_hash': prevHash,
      'hash': hash,
    };
  }

  // Calculate cryptographic SHA-256 hash for this block content
  String calculateHash() {
    final raw = '$idx|$waktu|$paymentId|$nominalIdr|$prevHash';
    final bytes = utf8.encode(raw);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Check if hash matches content
  bool get isHashValid => hash == calculateHash();
}
