// Top-level constants related to the size of BigUint56 limbs and bytes.
global BITS_PER_LIMB: Field = 56; /// Number of bits per limb.
global NUM_LIMBS: Field = 5; /// Number of limbs.

global BYTES_PER_LIMB: Field = 7; /// Number of bytes per limb (BITS_PER_LIMB / 8).
global MAX_BITS: Field = 280; /// Maximum number of bits (BITS_PER_LIMB * NUM_LIMBS).
global MAX_BYTES: Field = 35; /// Maximum number of bytes (NUM_LIMBS * BYTES_PER_LIMB).