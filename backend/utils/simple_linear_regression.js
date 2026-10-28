/**
 * Native Simple Linear Regression (Least Squares)
 * Replaces 'ml-regression' to eliminate CommonJS/ESM compatibility errors (ERR_REQUIRE_ESM)
 * in serverless environments like Vercel.
 */
class SimpleLinearRegression {
  constructor(x, y) {
    if (!Array.isArray(x) || !Array.isArray(y) || x.length !== y.length || x.length === 0) {
      throw new Error('x and y must be non-empty arrays of the same length');
    }
    const n = x.length;
    let sumX = 0;
    let sumY = 0;
    let sumXY = 0;
    let sumXX = 0;

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
      this.slope = (n * sumXY - sumX * sumY) / denominator;
      this.intercept = (sumY - this.slope * sumX) / n;
    }
  }

  predict(x) {
    if (Array.isArray(x)) {
      return x.map(val => this.slope * val + this.intercept);
    }
    return this.slope * x + this.intercept;
  }

  score(x, y) {
    const yMean = y.reduce((a, b) => a + b, 0) / y.length;
    let ssTot = 0;
    let ssRes = 0;
    for (let i = 0; i < x.length; i++) {
      const pred = this.predict(x[i]);
      ssTot += Math.pow(y[i] - yMean, 2);
      ssRes += Math.pow(y[i] - pred, 2);
    }
    const r2 = ssTot === 0 ? 1 : 1 - (ssRes / ssTot);
    return { r2: Math.max(0, Math.min(1, r2)) };
  }

  toJSON() {
    return {
      name: 'linearRegression',
      slope: this.slope,
      intercept: this.intercept
    };
  }
}

module.exports = { SimpleLinearRegression };
