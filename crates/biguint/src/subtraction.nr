use dep::std;
use crate::BigUint56;
use crate::consts::{BITS_PER_LIMB, NUM_LIMBS};

// Helper function to compute a - (b + borrow) for 56-bit values.
fn subtract_with_borrow(a: u56, b: u56, borrow: u56) -> (u56, u56) {
    let ret = std::wrapping_sub(
        a as u112,
        b as u112 + (borrow as u112 >> (BITS_PER_LIMB as u112 - 1))
    );
    (ret as u56, (ret >> 56) as u56)
}

/// Subtracts two BigUint56 numbers with borrow.
/// Iterates over each limb and calculates the difference and borrow.
pub fn sbb(a: BigUint56, b: BigUint56) -> (BigUint56, u56) {
    let mut result = BigUint56::zero();
    let mut borrow = 0 as u56;
    for i in 0..NUM_LIMBS {
        let (limb_diff, new_borrow) = subtract_with_borrow(a.limbs[i], b.limbs[i], borrow);
        result.limbs[i] = limb_diff;
        borrow = new_borrow;
    }
    (result, borrow)
}

/// Subtracts two BigUint56 instances without returning the borrow.
/// Ensures that there is no underflow in the subtraction.
pub fn sub(a: BigUint56, b: BigUint56) -> BigUint56 {
    let (result, borrow) = sbb(a, b);
    assert(borrow == 0);
    result
}

#[test]
fn test_sbb1() {
    let a = BigUint56 { limbs: [1, 0, 0, 0, 0] };
    let b = BigUint56 { limbs: [2, 0, 0, 0, 0] };
    let (diff, borrow) = sbb(a, b);

    assert(diff.eq(BigUint56 { limbs: [0xffffffffffffff; 5] }));
    assert(borrow >> (BITS_PER_LIMB as u56 - 1) == 1);
}

#[test]
fn test_sub1() {
    let a = BigUint56::from_bytes([5]);
    let b = BigUint56::from_bytes([3]);
    let diff = sub(a, b);

    assert(diff.eq(BigUint56::from_bytes([2])));
}

#[test]
fn test_sub2() {
    let a = BigUint56 { limbs: [1, 2, 0, 0, 0] };
    let b = BigUint56 { limbs: [2, 0, 0, 0, 0] };
    let diff = sub(a, b);

    assert(diff.eq(BigUint56 { limbs: [0xffffffffffffff, 1, 0, 0, 0] }));
}
