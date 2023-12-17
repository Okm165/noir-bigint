mod consts;
mod addition;
mod subtraction;
mod shift;

use dep::std::println;
use crate::consts::{NUM_LIMBS, MAX_BYTES, BYTES_PER_LIMB, MAX_BITS, BITS_PER_LIMB};

// TODO/NOTES:
// 1. Noir doesn't support expressions on globals so these are hardcoded
// 2. Noir doesn't support const generics, so we can't have a generic limb type
//
// The ideal implementation would be with a generic limb type `T`, but Noir
// doesn't support const generics so this is non-trivial to implement.
//  struct BigUint<T, NUM_LIMBS> {
//      limbs : [T; NUM_LIMBS],
//  }

/// A structure representing a large unsigned integer using a fixed number of limbs.
/// Each limb is a 56-bit unsigned integer.
/// 1. 56 is divisible by 8, making byte conversion easier.
/// 2. Multiplication requires a double width value, and u112 is the maximum representable in Noir.
struct BigUint56 {
    limbs: [u56; NUM_LIMBS],
}

impl BigUint56 {
    /// Creates a new BigUint56 initialized to zero.
    pub fn zero() -> Self {
        Self { limbs: [0 as u56; NUM_LIMBS] }
    }

    /// Creates a new BigUint56 initialized to one.
    pub fn one() -> Self {
        let mut one = BigUint56::zero();
        one.limbs[0] = 1;
        one
    }

    /// Constructs a BigUint56 from a single `u56` value.
    pub fn from_u56(val: u56) -> Self {
        let mut buint = BigUint56::zero();
        buint.limbs[0] = val;
        buint
    }

    /// Constructs a BigUint56 from a byte array in little-endian format.
    pub fn from_bytes(bytes: [u8]) -> Self {
        // TODO: Do I need this check?
        assert(bytes.len() as u56 <= MAX_BYTES as u56);

        let mut res = BigUint56::zero();
        for i in 0..bytes.len() {
            let limb_index = (i as u56) / (BYTES_PER_LIMB as u56);
            let byte_index = (i as u56) % (BYTES_PER_LIMB as u56);

            res.limbs[limb_index as Field] |= (bytes[i] as u56) << (byte_index * 8);
        }

        res
    }

    /// Returns the little-endian byte array representation of the BigUint56.
    fn to_bytes(self: Self) -> [u8; MAX_BYTES] {
        let mut res = [0 as u8; MAX_BYTES];

        for i in 0..NUM_LIMBS {
            let limb_bytes = (self.limbs[i] as Field).to_le_bytes(BYTES_PER_LIMB as u32);
            for j in 0..BYTES_PER_LIMB {
                let idx = i * BYTES_PER_LIMB + j;
                res[idx] = limb_bytes[j as Field];
            }
        }

        res
    }

    /// Returns the bit array representation of the BigUint56, with LSB at index 0.
    fn to_bits(self: Self) -> [u1; MAX_BITS] {
        let mut res = [0 as u1; MAX_BITS];

        for i in 0..NUM_LIMBS {
            let limb_bits = (self.limbs[i] as Field).to_le_bits(BITS_PER_LIMB as u32);
            for j in 0..BITS_PER_LIMB {
                let idx = i * (BITS_PER_LIMB as Field) + (j as Field);
                res[idx] = limb_bits[j as Field];
            }
        }

        res
    }

    

    

    // /// Multiplies two BigUint56 instances using long multiplication.
    // /// Returns a tuple containing the lower and higher parts of the multiplication result.
    // fn mul(self: Self, other: Self) -> (Self, Self) {
    //     let mut lo = BigUint56::zero();
    //     let mut hi = BigUint56::zero();

    //     for i in 0..NUM_LIMBS {
    //         let mut carry = 0 as u56;

    //         for j in 0..NUM_LIMBS {
    //             let k = i + j;

    //             if k as u56 >= NUM_LIMBS as u56 {
    //                 let (n, c) = utils::mac(hi.limbs[k - NUM_LIMBS], self.limbs[i], other.limbs[j], carry);
    //                 hi.limbs[k - NUM_LIMBS] = n;
    //                 carry = c;
    //             } else {
    //                 let (n, c) = utils::mac(lo.limbs[k], self.limbs[i], other.limbs[j], carry);
    //                 lo.limbs[k] = n;
    //                 carry = c;
    //             }
    //         };

    //         hi.limbs[i] = carry;
    //     };

    //     (lo, hi)
    // }

    /// Returns the number of bits needed to represent the BigUint56 instance.
    fn nbits(self: Self) -> u56 {
        let bits = BigUint56::to_bits(self);
        let mut res = 0;
        let mut done = false;
        for i in 0..MAX_BITS {
            if !done {
                if bits[MAX_BITS - i - 1] != 0 {
                    res = (MAX_BITS - i - 1) as u56 + 1;
                    done = true;
                }
            }
        }

        res
    }


    // /// Divides the BigUint56 instance by another, returning the quotient and remainder using long division.
    // // WARNING: This is a simple binary long division. More efficient algorithms should be considered.
    // // TODO: Maybe https://github.com/okuyiga/noir-bigint/blob/d60cc5246c8b0d175c4d6b1f4aaceed7fb725695/bigint/src/division.nr
    // fn div(self: Self, other: Self) -> (Self, Self) {
    //     assert(!other.is_zero());

    //     if self.lt(other) {
    //         (BigUint56::zero(), self)
    //     } else {
    //         let mut rem = self;
    //         let mut quo = BigUint56::zero();

    //         let bit_diff = self.nbits() - other.nbits();
    //         let mut c = other.shl(bit_diff);

    //         for i in 0..MAX_BITS+1 {
    //             if i as u56 <= bit_diff {
    //                 if rem.gte(c) {
    //                     rem = rem.sub(c);
    //                     quo = quo.shl1().add(BigUint56::one());
    //                 } else {
    //                     quo = quo.shl1();
    //                 }
    //                 c = c.shr1();
    //             }
    //         };

    //         (quo, rem)
    //     }
    // }

    /// Checks if the two BigUint56 instances are equal.
    fn eq(self: Self, other: Self) -> bool {
        let mut is_eq = true;
        for i in 0..NUM_LIMBS {
            is_eq = is_eq & (self.limbs[i] == other.limbs[i]);
        }
        is_eq
    }

    /// Checks if the BigUint56 instance is greater than or equal to another.
    fn gte(self: Self, other: Self) -> bool {
        let (_diff, borrow) = subtraction::sbb(self, other);
        borrow == 0
    }

    /// Checks if the BigUint56 instance is strictly greater than another.
    fn gt(self: Self, other: Self) -> bool {
        let (diff, borrow) = subtraction::sbb(self, other);
        (borrow == 0) & !diff.eq(BigUint56::zero())
    }

    /// Checks if the BigUint56 instance is less than or equal to another.
    fn lte(self: Self, other: Self) -> bool {
        other.gte(self)
    }

    /// Checks if the BigUint56 instance is strictly less than another.
    fn lt(self: Self, other: Self) -> bool {
        other.gt(self)
    }

    /// Checks if the BigUint56 instance is zero.
    fn is_zero(self: Self) -> bool {
        self.eq(BigUint56::zero())
    }

    // /// Returns self + other % modulus.
    // /// Assumes `self + other` as unbounded integer is `< 2*modulus`.
    // fn addmod(self: Self, other: Self, modulus: Self) -> Self {
    //     let (sum1, carry) = self.adc(other);

    //     // Attempt to subtract the modulus, to ensure the result is in the field.
    //     let (sum2, borrow1) = sum1.sbb(modulus);
    //     let (_diff, borrow2) = utils::sbb(carry, 0 as u56, borrow1);

    //     if borrow2 == 0 {
    //         sum2
    //     } else {
    //         sum2.add(modulus)
    //     }
    // }

    // Returns self * other % modulus.
    // TODO: Implement
    // fn mul_mod(self: Self, other: Self, modulus: Self)

    // Prints the BigUint56 instance as a byte array.
    fn println(self: Self) {
        let bytes = self.to_bytes();
        println(bytes);
    }
}

#[test]
fn test_from_bytes1() {
    let bytes = [2 as u8];
    let a = BigUint56::from_bytes(bytes);
    assert(a.eq(BigUint56 { limbs: [2, 0, 0, 0, 0] }));
}

#[test]
fn test_from_bytes2() {
    let bytes = [255 as u8; 7];
    let a = BigUint56::from_bytes(bytes);
    assert(a.eq(BigUint56 { limbs: [0xffffffffffffff, 0, 0, 0, 0] }));
}

#[test]
fn test_from_bytes3() {
    let bytes = [255 as u8; 8];
    let a = BigUint56::from_bytes(bytes);
    assert(a.eq(BigUint56 { limbs: [0xffffffffffffff, 255, 0, 0, 0] }));
}

// #[test]
// fn test_mul1() {
//     let a = BigUint56::from_bytes([2]);
//     let b = BigUint56::from_bytes([3]);
//     let (lo, hi) = a.mul(b);

//     assert(lo.eq(BigUint56::from_bytes([6])));
//     assert(hi.is_zero());
// }

// #[test]
// fn test_mul2() {
//     let a = BigUint56 { limbs: [0xffffffffffffff; 5] };
//     let b = BigUint56 { limbs: [0xffffffffffffff; 5] };
//     let (lo, hi) = a.mul(b);

//     assert(lo.eq(BigUint56::one()));
//     assert(
//         hi.eq(
//             BigUint56 { limbs: [0xfffffffffffffe, 0xffffffffffffff, 0xffffffffffffff, 0xffffffffffffff, 0xffffffffffffff] }
//         )
//     );
// }

#[test]
fn test_cmp1() {
    let a = BigUint56::from_bytes([2, 0]);
    let b = BigUint56::from_bytes([0, 2]);

    assert(!a.eq(b));

    assert(a.lte(b));
    assert(!a.gte(b));

    assert(a.lt(b));
    assert(!a.gt(b));
}

#[test]
fn test_cmp2() {
    let a = BigUint56::from_bytes([0, 2]);
    let b = BigUint56::from_bytes([0, 2]);

    assert(a.eq(b));

    assert(a.lte(b));
    assert(a.gte(b));

    assert(!a.lt(b));
    assert(!a.gt(b));
}

#[test]
fn test_bits1() {
    let a = BigUint56::from_bytes([0]);
    let b = a.nbits();

    assert(b == 0);
}

#[test]
fn test_bits2() {
    let a = BigUint56::from_bytes([1]);
    let b = a.nbits();

    assert(b == 1);
}

#[test]
fn test_bits3() {
    let a = BigUint56::from_bytes([0xff]);
    let b = a.nbits();

    assert(b == 8);
}

#[test]
fn test_bits4() {
    let a = BigUint56::from_bytes([1, 5]);
    let b = a.nbits();

    assert(b == 11);
}

// #[test]
// fn test_div1() {
//     let a = BigUint56::from_bytes([7]);
//     let b = BigUint56::from_bytes([3]);

//     let (q, r) = a.div(b);

//     assert(q.eq(BigUint56::from_bytes([2])));
//     assert(r.eq(BigUint56::from_bytes([1])));
// }

// #[test]
// fn test_div2() {
//     let a = BigUint56::from_bytes([7]);
//     let b = BigUint56::from_bytes([8]);

//     let (q, r) = a.div(b);

//     assert(q.eq(BigUint56::from_bytes([0])));
//     assert(r.eq(BigUint56::from_bytes([7])));
// }

// #[test]
// fn test_div3() {
//     let a = BigUint56 { limbs: [2, 0, 1, 0, 0] };
//     let b = BigUint56 { limbs: [0, 1, 0, 0, 0] };

//     let (q, r) = a.div(b);

//     assert(q.eq(BigUint56 { limbs: [0, 1, 0, 0, 0] }));
//     assert(r.eq(BigUint56 { limbs: [2, 0, 0, 0, 0] }));
// }

// #[test]
// fn test_div4() {
//     let a = BigUint56::from_bytes([7]);
//     let b = BigUint56::from_bytes([1]);

//     let (q, r) = a.div(b);

//     assert(q.eq(BigUint56::from_bytes([7])));
//     assert(r.eq(BigUint56::from_bytes([0])));
// }

// #[test]
// fn test_addmod1() {
//     let a = BigUint56::from_bytes([2]);
//     let b = BigUint56::from_bytes([7]);
//     let c = BigUint56::from_bytes([5]);

//     let d = a.addmod(b, c);
//     assert(d.eq(BigUint56::from_bytes([4])));
// }
