import { Decimal } from 'decimal.js';

export interface CeilingCalcInputs {
  lengthMeters: number;
  widthMeters: number;
  ratePerSqFt: number;
  taxPercentage?: number;
  includeTax?: boolean;
}

export interface CeilingCalcResult {
  sqm: number;
  sqftRaw: number;
  sqftRounded: number;
  baseAmount: number;
  taxAmount: number;
  totalAmount: number;
}

/**
 * DEFINITIVE MATHEMATICAL CALCULATION LOGIC FOR CEILING COST ESTIMATION.
 * Hardcoded as specified to ensure maximum data accuracy and zero floating-point errors.
 *
 * STEP 1: Area in sqm = Length (m) * Width (m)
 * STEP 2: Convert to sqft = sqm * 10.7639
 * STEP 3: Round UP sqft = CEIL(sqftRaw)
 * STEP 4: Base Amount = sqftRounded * Rate (per sqft)
 * STEP 5: Total Amount = Base Amount + Optional Tax
 */
export const calculateCeilingCost = (inputs: CeilingCalcInputs): CeilingCalcResult => {
  const {
    lengthMeters,
    widthMeters,
    ratePerSqFt,
    taxPercentage = 0,
    includeTax = false
  } = inputs;

  // Initialize high-precision decimal instances
  const L = new Decimal(lengthMeters || 0);
  const W = new Decimal(widthMeters || 0);
  const R = new Decimal(ratePerSqFt || 0);

  // STEP 1: Calculate Area in sqm
  const sqm = L.mul(W);

  // STEP 2: Convert sqm to Square Feet (sqft) by multiplying by EXACTLY 10.7639
  const SQFT_CONVERSION_FACTOR = new Decimal('10.7639');
  const sqftRaw = sqm.mul(SQFT_CONVERSION_FACTOR);

  // STEP 3: STRICT BUSINESS LOGIC - Round UP to protect against material/labor loss
  const sqftRounded = sqftRaw.ceil();

  // STEP 4: Multiply rounded sqft integer by the Rate to get the Base Amount
  const baseAmount = sqftRounded.mul(R);

  // STEP 5: Optional Tax Calculation
  let taxAmount = new Decimal(0);
  if (includeTax && taxPercentage > 0) {
    const taxRate = new Decimal(taxPercentage).div(100);
    taxAmount = baseAmount.mul(taxRate);
  }

  const totalAmount = baseAmount.plus(taxAmount);

  return {
    sqm: sqm.toNumber(),
    sqftRaw: sqftRaw.toNumber(),
    sqftRounded: sqftRounded.toNumber(),
    baseAmount: baseAmount.toNumber(),
    taxAmount: taxAmount.toNumber(),
    totalAmount: totalAmount.toNumber(),
  };
};

/**
 * Helper to convert any area to rounded sqft according to the strict business logic.
 * 1. Convert to sqm if needed.
 * 2. Multiply by EXACTLY 10.7639.
 * 3. Round UP (CEIL).
 */
export const convertAreaToRoundedSqFt = (area: number, unit: string): number => {
  if (!area || area <= 0) return 0;

  let areaSqm: Decimal;
  const rawArea = new Decimal(area);

  if (unit === 'Meters' || unit === 'SqM') {
    areaSqm = rawArea;
  } else if (unit === 'SqFt') {
    // If already in SqFt, we still apply the "round up" logic as per strict business requirement
    return rawArea.ceil().toNumber();
  } else if (unit === 'Inches') {
    // 1 sqft = 144 sqin. Formula: (sqin / 144) -> rounded up
    // But user wants Meters -> SqFt.
    // If unit is inches, we convert sqin to sqft first.
    return rawArea.div(144).ceil().toNumber();
  } else if (unit === 'mm') {
    // 1 sqm = 1,000,000 sqmm
    areaSqm = rawArea.div(1000000);
  } else {
    areaSqm = rawArea;
  }

  const factor = new Decimal('10.7639');
  return areaSqm.mul(factor).ceil().toNumber();
};

