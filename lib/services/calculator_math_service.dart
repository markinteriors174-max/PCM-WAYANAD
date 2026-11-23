class CalculatorMathService {
  double calculateDeductedCoveLength(double width, double height) {
    if (width <= 0) return 0.0;
    double deduction = height > 0 ? (2 * height) : 0.0;
    double res = width - deduction;
    return res > 0 ? res : width;
  }
}
