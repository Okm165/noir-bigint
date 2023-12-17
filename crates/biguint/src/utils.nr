use crate::BITS_PER_LIMB as BITS;
use dep::std;

// Compute a + (b * c) + carry, returning the result and the new carry over.
pub fn mac(a: u56, b: u56, c: u56, carry: u56) -> (u56, u56) {
    let ret = (a as Field) + ((b as Field) * (c as Field)) + (carry as Field);
    (ret as u56, (ret as u112 >> BITS as u112) as u56)
}
