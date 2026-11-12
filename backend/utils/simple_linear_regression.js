// ==============================================================================
// PANDUAN PEMULA & MATEMATIKA: ALGORITMA REGRESI LINIER (ORDINARY LEAST SQUARES)
// ==============================================================================
// Kelas ini mengimplementasikan Machine Learning Regresi Linier secara murni (Native JS):
// 1. PERSAMAAN GARIS REGRESI:
//    y = mx + c
//    - y : Nilai yang ingin diprediksi (misal: Pemasukan / Omset).
//    - x : Variabel bebas / indeks waktu (misal: Bulan ke-0, 1, 2, ...).
//    - m (Slope) : Kemiringan garis / laju kenaikan omset per bulan.
//    - c (Intercept) : Titik potong sumbu Y / estimasi nilai dasar saat x = 0.
//
// 2. TINGKAT KEYAKINAN (R² SCORE / KOEFISIEN DETERMINASI):
//    - R² = 1 - (SS_res / SS_tot)
//    - Nilai 1.0 (100%) menunjukkan kecocokan sempurna (garis regresi pas melintasi data).
//    - Nilai di atas 0.85 (85%) sudah sangat baik untuk proyeksi keuangan bisnis ISP.
// ==============================================================================

class SimpleLinearRegression {
  // Konstruktor melatih model dengan pasangan data X dan Y
  constructor(x, y) {
    if (!Array.isArray(x) || !Array.isArray(y) || x.length !== y.length || x.length === 0) {
      throw new Error('x and y must be non-empty arrays of the same length');
    }
    const n = x.length;
    let sumX = 0;
    let sumY = 0;
    let sumXY = 0;
    let sumXX = 0;

    // Menghitung akumulasi statistik dasar
    for (let i = 0; i < n; i++) {
      sumX += x[i];
      sumY += y[i];
      sumXY += x[i] * y[i];
      sumXX += x[i] * x[i];
    }

    const denominator = n * sumXX - sumX * sumX;
    if (denominator === 0) {
      this.slope = 0;
      this.intercept = sumY / n;
    } else {
      // Rumus Matematis Slope (m) & Intercept (c) metode kuadrat terkecil
      this.slope = (n * sumXY - sumX * sumY) / denominator;
      this.intercept = (sumY - this.slope * sumX) / n;
    }
  }

  // Menghitung prediksi nilai Y untuk nilai X di masa depan (y = mx + c)
  predict(x) {
    if (Array.isArray(x)) {
      return x.map(val => this.slope * val + this.intercept);
    }
    return this.slope * x + this.intercept;
  }

  // Mengukur akurasi model menggunakan skor R² (Koefisien Determinasi)
  score(x, y) {
    const yMean = y.reduce((a, b) => a + b, 0) / y.length;
    let ssTot = 0; // Total deviasi kuadrat terhadap rata-rata
    let ssRes = 0; // Sisa residu kuadrat prediksi terhadap data asli
    for (let i = 0; i < x.length; i++) {
      const pred = this.predict(x[i]);
      ssTot += Math.pow(y[i] - yMean, 2);
      ssRes += Math.pow(y[i] - pred, 2);
    }
    const r2 = ssTot === 0 ? 1 : 1 - (ssRes / ssTot);
    return { r2: Math.max(0, Math.min(1, r2)) };
  }

  // Menyerialisasi parameter model ke bentuk JSON
  toJSON() {
    return {
      name: 'linearRegression',
      slope: this.slope,
      intercept: this.intercept
    };
  }
}

module.exports = { SimpleLinearRegression };
