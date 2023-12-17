use crate::BigUint56;
use crate::consts::{BITS_PER_LIMB, NUM_LIMBS, MAX_BITS, MAX_BYTES};

/// Shifts the BigUint56 instance to the left by a specified number of bits `n`.
/// where `0 <= n < Limb::BITS`,
/// Returns the shifted result and the carry.
fn shl_limb(a: BigUint56, n: u56) -> (BigUint56, u56) {
    if (n == 0) { 
        (a, 0)
    }
    assert(n <= BITS_PER_LIMB as u56);
    let mut res = a;
    let rshift = BITS_PER_LIMB as u56 - n;
    let carry = a.limbs[NUM_LIMBS - 1] >> rshift ;
    if (n > 0) {
        res.limbs[0] = a.limbs[0] << n;
        for i in 1..NUM_LIMBS {
            res.limbs[i] = (a.limbs[i] << n) | (a.limbs[i - 1] >> rshift);
        }
    }
    (res, carry)
}

/// Shifts the BigUint56 instance to the right by a specified number of bits `n`.
/// where `0 <= n < Limb::BITS`,
/// Returns the shifted result and the borrow.
fn shr_limb(a: BigUint56, n: u56) -> (BigUint56, u56) {
    if (n == 0) { 
        (a, 0)
    }
    assert(n <= BITS_PER_LIMB as u56);
    let mut res = a;
    let lshift = BITS_PER_LIMB as u56 - n;
    let borrow = a.limbs[NUM_LIMBS - 1] >> lshift;
    if (n > 0) {
        for i in 0..NUM_LIMBS-1 {
            res.limbs[i] = (a.limbs[i] >> n) | (a.limbs[i + 1] << lshift);
        }
        res.limbs[NUM_LIMBS - 1] = a.limbs[NUM_LIMBS - 1] >> n;
    }
    (res, borrow)
}

/// Shifts the BigUint56 instance to the left by a specified number of bits `n`.
pub fn shl(a: BigUint56, n: u56) -> BigUint56 {
    if (n == 0) { 
        a
    }
    assert(n <= MAX_BITS as u56);

    let mut res = BigUint56::zero();

    let shift_num = n / (BITS_PER_LIMB as u56);
    let rem = n % (BITS_PER_LIMB as u56);

    // for i in shift_num..NUM_LIMBS {
    for i in 0..NUM_LIMBS {
        if i as u56 >= shift_num {
            res.limbs[i as u56] = a.limbs[i as u56 - shift_num];
        }
    }

    let (shl, _carry) = shl_limb(res, rem);
    shl
}

/// Shifts the BigUint56 instance to the right by a specified number of bits.
pub fn shr(a: BigUint56, n: u56) -> BigUint56 {
    if (n == 0) { 
        a
    }
    assert(n <= MAX_BITS as u56);

    let mut res = BigUint56::zero();

    let shift_num = n / (BITS_PER_LIMB as u56);
    let rem = n % (BITS_PER_LIMB as u56);
    // for i in 0..shift_num {
    for i in 0..NUM_LIMBS {
        if i as u56 + shift_num < NUM_LIMBS as u56 {
            res.limbs[i] = a.limbs[i + shift_num as Field];
        }
    }
    let (shr, _borrow) = shr_limb(res, rem);
    shr
}

#[test]
fn test_shl1() {
    let a = BigUint56::from_bytes([1, 2]);
    let b = shl(a, 0);

    assert(a.eq(b));
}

#[test]
fn test_shl2() {
    let a = BigUint56::from_bytes([1, 2]);
    let b = shl(a, MAX_BITS as u56);

    assert(b.is_zero());
}

#[test]
fn test_shl3() {
    let a = BigUint56::from_bytes([1, 2]);
    let b = shl(a, 1);

    let bytes = b.to_bytes();

    let mut expected = [0 as u8; MAX_BYTES];
    expected[0] = 2;
    expected[1] = 4;

    assert(bytes == expected);
}

#[test]
fn test_shl4() {
    let a = BigUint56::from_bytes([1, 2]);
    let b = shl(a, 8);

    assert(b.eq(BigUint56::from_bytes([0, 1, 2])));
}

#[test]
fn test_shr1() {
    let a = BigUint56::from_bytes([1, 2]);
    let b = shr(a, 0);

    assert(a.eq(b));
}

#[test]
fn test_shr2() {
    let a = BigUint56::from_bytes([1, 2]);
    let b = shr(a, MAX_BITS as u56);

    assert(b.is_zero());
}

#[test]
fn test_shr3() {
    let a = BigUint56::from_bytes([1, 2]);
    let b = shr(a, 1);

    let bytes = b.to_bytes();

    let mut expected = [0 as u8; MAX_BYTES];
    expected[0] = 0;
    expected[1] = 1;

    assert(bytes == expected);
}

#[test]
fn test_shr4() {
    let a = BigUint56::from_bytes([0, 1, 2]);
    let b = shr(a, 8);

    assert(b.eq(BigUint56::from_bytes([1, 2])));
}