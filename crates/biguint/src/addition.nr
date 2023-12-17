use crate::BigUint56;
use crate::consts::{BITS_PER_LIMB, NUM_LIMBS};

// Helper function to compute a + b + carry for 56-bit values.
fn add_with_carry(a: u56, b: u56, carry: u56) -> (u56, u56) {
    let ret = a as u112 + b as u112 + carry as u112;
    (ret as u56, (ret as u112 >> BITS_PER_LIMB as u112) as u56)
}

/// Adds two BigUint56 numbers with carry.
/// Iterates over each limb and calculates the sum and carry.
pub fn adc(a: BigUint56, b: BigUint56) -> (BigUint56, u56) {
    let mut result = BigUint56::zero();
    let mut carry = 0 as u56;
    for i in 0..NUM_LIMBS {
        let (limb_sum, new_carry) = add_with_carry(a.limbs[i], b.limbs[i], carry);
        result.limbs[i] = limb_sum;
        carry = new_carry;
    }
    (result, carry)
}

/// Adds two BigUint56 instances without returning the carry.
/// Ensures that there is no overflow in the addition.
pub fn add(a: BigUint56, b: BigUint56) -> BigUint56 {
    let (result, carry) = adc(a, b);
    assert(carry == 0);
    result
}

#[test]
fn test_adc1() {
    let a = BigUint56 { limbs: [0xffffffffffffff; NUM_LIMBS] };
    let b = BigUint56::one();
    let (sum, carry) = adc(a, b);

    assert(sum.is_zero());
    assert(carry == 1);
}

#[test]
fn test_add1() {
    let a = BigUint56::from_bytes([1]);
    let b = BigUint56::from_bytes([2]);
    let sum = add(a, b);

    assert(sum.eq(BigUint56::from_bytes([3])));
}

#[test]
fn test_add2() {
    let a = BigUint56 { limbs: [0xffffffffffffff, 0xffffffffffffff, 0xffffffffffffff, 0xffffffffffffff, 0] };
    let b = BigUint56 { limbs: [1, 0, 0, 0, 0] };
    let sum = add(a, b);

    assert(sum.eq(BigUint56 { limbs: [0, 0, 0, 0, 1] }));
}
