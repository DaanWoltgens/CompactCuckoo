#include <stdint.h>

#ifndef MAIN
#define MAIN
#include "main.h"
#endif

using nodetype = uint64_cu;


inline __host__ __device__ uint64_cu MASK(int size) { return (((uint64_cu)1) << size) - 1; }


// Bit right shift function.
inline __host__ __device__ uint64_cu rshft(const uint64_cu x, uint8_t i) {
	return (x >> i);
}

// Bit left shift function for 58 bits.
inline __host__ __device__ uint64_cu lshft_58(const uint64_cu x, uint8_t i) {
	uint64_cu y = (x << i);
	return y & MASK(58);
}

// Multiplication modulo 2^58.
inline __host__ __device__ uint64_cu mult_58(const uint64_cu x, uint64_cu a) {
	return ((x * a) & MASK(58));
}

// XOR two times bit shift function for 58 bits.
inline __host__ __device__ uint64_cu xor_shft2_58(const uint64_cu x, uint8_t a, uint8_t b) {
	uint64_cu y = (x ^ lshft_58(x,a));
	y = (y ^ rshft(y,b));
	return y;
}

// Bit left shift function for 50 bits.
inline __host__ __device__ uint64_cu lshft_50(const uint64_cu x, uint8_t i) {
	uint64_cu y = (x << i);
	return y & MASK(50);
}

// Multiplication modulo 2^50.
inline __host__ __device__ uint64_cu mult_50(const uint64_cu x, uint64_cu a) {
	return ((x * a) & MASK(50));
}

// XOR two times bit shift function for 50 bits.
inline __host__ __device__ uint64_cu xor_shft2_50(const uint64_cu x, uint8_t a, uint8_t b) {
	uint64_cu y = (x ^ lshft_50(x,a));
	y = (y ^ rshft(y,b));
	return y;
}

inline __host__ __device__ nodetype RHASH64(uint8_t id, nodetype node) {
	nodetype node1 = node;
	switch (id) {
		case 0:
			node1 = xor_shft2_58(node1, 12, 46);
			node1 = xor_shft2_58(node1, 37, 21);
			node1 = mult_58(node1, 0x346d5269d6a44c1L);
			node1 ^= rshft(node1, 43);
			node1 ^= rshft(node1, 31);
			node1 ^= rshft(node1, 23);
			node1 = mult_58(node1, 0x36d3c2b4804a8e1L);
			node1 ^= rshft(node1, 28);
			break;
		case 1:
			node1 = xor_shft2_58(node1, 10, 48);
			node1 = xor_shft2_58(node1, 35, 23);
			node1 = mult_58(node1, 0x3866c0692e5e421L);
			node1 ^= rshft(node1, 40);
			node1 ^= rshft(node1, 34);
			node1 ^= rshft(node1, 19);
			node1 = mult_58(node1, 0x39838add4d38e61L);
			node1 ^= rshft(node1, 26);
			break;
		case 2:

			node1 = xor_shft2_58(node1, 14, 44);
			node1 = xor_shft2_58(node1, 39, 19);
			node1 = mult_58(node1, 0x3a5787914312801L);
			node1 ^= rshft(node1, 44);
			node1 ^= rshft(node1, 30);
			node1 ^= rshft(node1, 15);
			node1 = mult_58(node1, 0x3afb7bb024c4681L);
			node1 ^= rshft(node1, 30);
			break;
		case 3:
			node1 = xor_shft2_58(node1, 13, 45);
			node1 = xor_shft2_58(node1, 34, 24);
			node1 = mult_58(node1, 0x3b7e13a202e41c1L);
			node1 ^= rshft(node1, 39);
			node1 ^= rshft(node1, 33);
			node1 ^= rshft(node1, 25);
			node1 = mult_58(node1, 0x3be88e9173fb7c1L);
			node1 ^= rshft(node1, 28);
			break;
		case 4:
			node1 = xor_shft2_58(node1, 11, 47);
			node1 = xor_shft2_58(node1, 35, 23);
			node1 = mult_58(node1, 0x3c4109af0f01241L);
			node1 ^= rshft(node1, 23);
			node1 ^= rshft(node1, 30);
			node1 ^= rshft(node1, 26);
			node1 = mult_58(node1, 0x3c8bbb336719fc1L);
			node1 ^= rshft(node1, 20);
			break;
		case 5:
			node1 = xor_shft2_58(node1, 15, 43);
			node1 = xor_shft2_58(node1, 33, 25);
			node1 = mult_58(node1, 0x3ccba0994f7af81L);
			node1 ^= rshft(node1, 41);
			node1 ^= rshft(node1, 36);
			node1 ^= rshft(node1, 20);
			node1 = mult_58(node1, 0x3d02e8d5ad09d61L);
			node1 ^= rshft(node1, 23);
			break;
		case 6:
			node1 = xor_shft2_58(node1, 34, 24);
			node1 = xor_shft2_58(node1, 12, 46);
			node1 = mult_58(node1, 0x3d3335b9a01aac1L);
			node1 ^= rshft(node1, 38);
			node1 ^= rshft(node1, 42);
			node1 ^= rshft(node1, 24);
			node1 = mult_58(node1, 0x3d5dc5b2dd89301L);
			node1 ^= rshft(node1, 29);
			break;
		case 7:
			node1 = xor_shft2_58(node1, 23, 35);
			node1 = xor_shft2_58(node1, 35, 23);
			node1 = mult_58(node1, 0x3d839037059b321L);
			node1 ^= rshft(node1, 26);
			node1 ^= rshft(node1, 46);
			node1 ^= rshft(node1, 23);
			node1 = mult_58(node1, 0x3da557a7a356621L);
			node1 ^= rshft(node1, 26);
			break;
		case 8:
			node1 = xor_shft2_58(node1, 31, 27);
			node1 = xor_shft2_58(node1, 34, 24);
			node1 = mult_58(node1, 0x3dc3b70f5d13b41L);
			node1 ^= rshft(node1, 29);
			node1 ^= rshft(node1, 40);
			node1 ^= rshft(node1, 20);
			node1 = mult_58(node1, 0x3ddf2c9626244a1L);
			node1 ^= rshft(node1, 27);
			break;
		case 9:
			node1 = xor_shft2_58(node1, 24, 34);
			node1 = xor_shft2_58(node1, 20, 38);
			node1 = mult_58(node1, 0x3df81dfdd3d5e01L);
			node1 ^= rshft(node1, 40);
			node1 ^= rshft(node1, 33);
			node1 ^= rshft(node1, 25);
			node1 = mult_58(node1, 0x3e0ee0bdbcd6ea1L);
			node1 ^= rshft(node1, 30);
			break;
		case 10:
			node1 = xor_shft2_58(node1, 10, 48);
			node1 = xor_shft2_58(node1, 19, 39);
			node1 = mult_58(node1, 0x3e23ba68e0e7381L);
			node1 ^= rshft(node1, 26);
			node1 ^= rshft(node1, 46);
			node1 ^= rshft(node1, 23);
			node1 = mult_58(node1, 0x3e36e66407cf201L);
			node1 ^= rshft(node1, 28);
			break;
		case 11:
			node1 = xor_shft2_58(node1, 14, 44);
			node1 = xor_shft2_58(node1, 30, 28);
			node1 = mult_58(node1, 0x3e48961660141a1L);
			node1 ^= rshft(node1, 43);
			node1 ^= rshft(node1, 12);
			node1 ^= rshft(node1, 26);
			node1 = mult_58(node1, 0x3e58f4f3df8a861L);
			node1 ^= rshft(node1, 31);
			break;
		case 12:
			node1 = xor_shft2_58(node1, 19, 39);
			node1 = xor_shft2_58(node1, 41, 17);
			node1 = mult_58(node1, 0x3e68266fecc08a1L);
			node1 ^= rshft(node1, 24);
			node1 ^= rshft(node1, 39);
			node1 ^= rshft(node1, 21);
			node1 = mult_58(node1, 0x3e764a9bd2ba4c1L);
			node1 ^= rshft(node1, 25);
			break;
		case 13:
			node1 = xor_shft2_58(node1, 28, 30);
			node1 = xor_shft2_58(node1, 15, 43);
			node1 = mult_58(node1, 0x3e837baf5cdd9e1L);
			node1 ^= rshft(node1, 32);
			node1 ^= rshft(node1, 40);
			node1 ^= rshft(node1, 24);
			node1 = mult_58(node1, 0x3e8fd1c4d2d9d01L);
			node1 ^= rshft(node1, 27);
			break;
		case 14:
			node1 = xor_shft2_58(node1, 43, 15);
			node1 = xor_shft2_58(node1, 32, 26);
			node1 = mult_58(node1, 0x3e9b61d7f9527a1L);
			node1 ^= rshft(node1, 31);
			node1 ^= rshft(node1, 46);
			node1 ^= rshft(node1, 28);
			node1 = mult_58(node1, 0x3ea63db9f9aa901L);
			node1 ^= rshft(node1, 26);
			break;
		case 15:
			node1 = xor_shft2_58(node1, 35, 23);
			node1 = xor_shft2_58(node1, 42, 16);
			node1 = mult_58(node1, 0x3eb074fc94e0161L);
			node1 ^= rshft(node1, 25);
			node1 ^= rshft(node1, 44);
			node1 ^= rshft(node1, 29);
			node1 = mult_58(node1, 0x3eba165b7e383e1L);
			node1 ^= rshft(node1, 28);
			break;
		case 16:
			node1 = xor_shft2_58(node1, 35, 23);
			node1 = xor_shft2_58(node1, 49, 9);
			node1 = mult_58(node1, 0x3ec32dcb8264481L);
			node1 ^= rshft(node1, 20);
			node1 ^= rshft(node1, 29);
			node1 ^= rshft(node1, 44);
			node1 = mult_58(node1, 0x3ecbc7575141a21L);
			node1 ^= rshft(node1, 35);
			break;
		case 17:
			node1 = xor_shft2_58(node1, 45, 13);
			node1 = xor_shft2_58(node1, 29, 29);
			node1 = mult_58(node1, 0x3ed3ec3963f4841L);
			node1 ^= rshft(node1, 15);
			node1 ^= rshft(node1, 44);
			node1 ^= rshft(node1, 33);
			node1 = mult_58(node1, 0x3edba5bb75d7341L);
			node1 ^= rshft(node1, 41);
			break;
		case 18:
			node1 = xor_shft2_58(node1, 20, 38);
			node1 = xor_shft2_58(node1, 36, 22);
			node1 = mult_58(node1, 0x3ee2fc3e0dbac21L);
			node1 ^= rshft(node1, 21);
			node1 ^= rshft(node1, 41);
			node1 ^= rshft(node1, 13);
			node1 = mult_58(node1, 0x3ee9f6ba8914441L);
			node1 ^= rshft(node1, 34);
			break;
		case 19:
			node1 = xor_shft2_58(node1, 10, 48);
			node1 = xor_shft2_58(node1, 8, 50);
			node1 = mult_58(node1, 0x3ef09bb82cdbe21L);
			node1 ^= rshft(node1, 49);
			node1 ^= rshft(node1, 11);
			node1 ^= rshft(node1, 34);
			node1 = mult_58(node1, 0x3ef6f14ae3b4501L);
			node1 ^= rshft(node1, 15);
			break;
		case 20:
			node1 = xor_shft2_58(node1, 29, 29);
			node1 = xor_shft2_58(node1, 50, 8);
			node1 = mult_58(node1, 0x3efcfd121b9a201L);
			node1 ^= rshft(node1, 43);
			node1 ^= rshft(node1, 39);
			node1 ^= rshft(node1, 49);
			node1 = mult_58(node1, 0x3f02c33f9a541c1L);
			node1 ^= rshft(node1, 24);
			break;
		case 21:
			node1 = xor_shft2_58(node1, 38, 20);
			node1 = xor_shft2_58(node1, 31, 27);
			node1 = mult_58(node1, 0x3f08497eaba1a01L);
			node1 ^= rshft(node1, 50);
			node1 ^= rshft(node1, 34);
			node1 ^= rshft(node1, 48);
			node1 = mult_58(node1, 0x3f0d9313139b901L);
			node1 ^= rshft(node1, 44);
			break;
		case 22:
			node1 = xor_shft2_58(node1, 14, 44);
			node1 = xor_shft2_58(node1, 49, 9);
			node1 = mult_58(node1, 0x3f12a43ce6c0301L);
			node1 ^= rshft(node1, 11);
			node1 ^= rshft(node1, 23);
			node1 ^= rshft(node1, 11);
			node1 = mult_58(node1, 0x3f178047799bae1L);
			node1 ^= rshft(node1, 8);
			break;
		case 23:
			node1 = xor_shft2_58(node1, 20, 38);
			node1 = xor_shft2_58(node1, 19, 39);
			node1 = mult_58(node1, 0x3f1c2a814d54a41L);
			node1 ^= rshft(node1, 50);
			node1 ^= rshft(node1, 29);
			node1 ^= rshft(node1, 28);
			node1 = mult_58(node1, 0x3f20a5bf510f741L);
			node1 ^= rshft(node1, 43);
			break;
		case 24:
			node1 = xor_shft2_58(node1, 31, 27);
			node1 = xor_shft2_58(node1, 18, 40);
			node1 = mult_58(node1, 0x3f24f45c5a49c41L);
			node1 ^= rshft(node1, 39);
			node1 ^= rshft(node1, 14);
			node1 ^= rshft(node1, 32);
			node1 = mult_58(node1, 0x3f2919aea827c81L);
			node1 ^= rshft(node1, 20);
			break;
		case 25:
			node1 = xor_shft2_58(node1, 26, 32);
			node1 = xor_shft2_58(node1, 35, 23);
			node1 = mult_58(node1, 0x3f2d1798bf827a1L);
			node1 ^= rshft(node1, 18);
			node1 ^= rshft(node1, 24);
			node1 ^= rshft(node1, 50);
			node1 = mult_58(node1, 0x3f30effeb7d35a1L);
			node1 ^= rshft(node1, 25);
			break;
		case 26:
			node1 = xor_shft2_58(node1, 48, 10);
			node1 = xor_shft2_58(node1, 49, 9);
			node1 = mult_58(node1, 0x3f34a542fbc9a21L);
			node1 ^= rshft(node1, 28);
			node1 ^= rshft(node1, 33);
			node1 ^= rshft(node1, 41);
			node1 = mult_58(node1, 0x3f3838cfc8b3a01L);
			node1 ^= rshft(node1, 17);
			break;
		case 27:
			node1 = xor_shft2_58(node1, 26, 32);
			node1 = xor_shft2_58(node1, 20, 38);
			node1 = mult_58(node1, 0x3f3bad0a59f2881L);
			node1 ^= rshft(node1, 46);
			node1 ^= rshft(node1, 43);
			node1 ^= rshft(node1, 23);
			node1 = mult_58(node1, 0x3f3f02e25afd0c1L);
			node1 ^= rshft(node1, 18);
			break;
		case 28:
			node1 = xor_shft2_58(node1, 32, 26);
			node1 = xor_shft2_58(node1, 12, 46);
			node1 = mult_58(node1, 0x3f423cbf612eea1L);
			node1 ^= rshft(node1, 10);
			node1 ^= rshft(node1, 15);
			node1 ^= rshft(node1, 49);
			node1 = mult_58(node1, 0x3f455b15e806c41L);
			node1 ^= rshft(node1, 29);
			break;
		case 29:
			node1 = xor_shft2_58(node1, 30, 28);
			node1 = xor_shft2_58(node1, 49, 9);
			node1 = mult_58(node1, 0x3f485fd255036a1L);
			node1 ^= rshft(node1, 27);
			node1 ^= rshft(node1, 45);
			node1 ^= rshft(node1, 36);
			node1 = mult_58(node1, 0x3f4b4b6a79ccae1L);
			node1 ^= rshft(node1, 49);
			break;
		case 30:
			node1 = xor_shft2_58(node1, 28, 30);
			node1 = xor_shft2_58(node1, 17, 41);
			node1 = mult_58(node1, 0x3f4e204983b0bc1L);
			node1 ^= rshft(node1, 12);
			node1 ^= rshft(node1, 39);
			node1 ^= rshft(node1, 34);
			node1 = mult_58(node1, 0x3f50de694fe52a1L);
			node1 ^= rshft(node1, 43);
			break;
		case 31:
			node1 = xor_shft2_58(node1, 47, 11);
			node1 = xor_shft2_58(node1, 10, 48);
			node1 = mult_58(node1, 0x3f53873be153f21L);
			node1 ^= rshft(node1, 28);
			node1 ^= rshft(node1, 39);
			node1 ^= rshft(node1, 50);
			node1 = mult_58(node1, 0x3f561bb689cd3e1L);
			node1 ^= rshft(node1, 7);
			break;
	}
	return node1;
}

// Inverse hash functions.
inline __host__ __device__ nodetype RHASH64_INVERSE(uint8_t id, nodetype node) {
	nodetype node1 = node;
	nodetype node2;
	switch (id) {
		case 0:
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 28));
			node2 = (node1 ^ rshft(node2, 28));
			node2 = (node1 ^ rshft(node2, 28));
			node1 = node2;
			node1 = mult_58(node1, 0x3e340cf8be69b21L);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 43));
			node2 = (node1 ^ rshft(node2, 43));
			node1 = node2;
			node1 = (node2 ^ rshft(node1, 31));
			node1 = (node2 ^ rshft(node1, 31));
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 23));
			node2 = (node1 ^ rshft(node2, 23));
			node2 = (node1 ^ rshft(node2, 23));
			node1 = node2;
			node1 = mult_58(node1, 0x16e2e65fde04b41L);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 21));
			node2 = (node1 ^ rshft(node2, 21));
			node2 = (node1 ^ rshft(node2, 21));
			node1 = node2;
			node1 = (node2 ^ lshft_58(node1, 37));
			node1 = (node2 ^ lshft_58(node1, 37));
			node1 &= MASK(58);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 46));
			node2 = (node1 ^ rshft(node2, 46));
			node1 = node2;
			node1 = (node2 ^ lshft_58(node1, 12));
			node1 = (node2 ^ lshft_58(node1, 12));
			node1 = (node2 ^ lshft_58(node1, 12));
			node1 = (node2 ^ lshft_58(node1, 12));
			node1 = (node2 ^ lshft_58(node1, 12));
			node1 &= MASK(58);
			break;
		case 1:
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 26));
			node2 = (node1 ^ rshft(node2, 26));
			node2 = (node1 ^ rshft(node2, 26));
			node1 = node2;
			node1 = mult_58(node1, 0x27e8bdf6b3595a1L);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 40));
			node2 = (node1 ^ rshft(node2, 40));
			node1 = node2;
			node1 = (node2 ^ rshft(node1, 34));
			node1 = (node2 ^ rshft(node1, 34));
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 19));
			node2 = (node1 ^ rshft(node2, 19));
			node2 = (node1 ^ rshft(node2, 19));
			node2 = (node1 ^ rshft(node2, 19));
			node1 = node2;
			node1 = mult_58(node1, 0x3234705f3029fe1L);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 23));
			node2 = (node1 ^ rshft(node2, 23));
			node2 = (node1 ^ rshft(node2, 23));
			node1 = node2;
			node1 = (node2 ^ lshft_58(node1, 35));
			node1 = (node2 ^ lshft_58(node1, 35));
			node1 &= MASK(58);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 48));
			node2 = (node1 ^ rshft(node2, 48));
			node1 = node2;
			node1 = (node2 ^ lshft_58(node1, 10));
			node1 = (node2 ^ lshft_58(node1, 10));
			node1 = (node2 ^ lshft_58(node1, 10));
			node1 = (node2 ^ lshft_58(node1, 10));
			node1 = (node2 ^ lshft_58(node1, 10));
			node1 = (node2 ^ lshft_58(node1, 10));
			node1 &= MASK(58);
			break;
		case 2:
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 30));
			node2 = (node1 ^ rshft(node2, 30));
			node1 = node2;
			node1 = mult_58(node1, 0x38516503a7df981L);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 44));
			node2 = (node1 ^ rshft(node2, 44));
			node1 = node2;
			node1 = (node2 ^ rshft(node1, 30));
			node1 = (node2 ^ rshft(node1, 30));
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 15));
			node2 = (node1 ^ rshft(node2, 15));
			node2 = (node1 ^ rshft(node2, 15));
			node2 = (node1 ^ rshft(node2, 15));
			node1 = node2;
			node1 = mult_58(node1, 0x3880f7d420ed801L);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 19));
			node2 = (node1 ^ rshft(node2, 19));
			node2 = (node1 ^ rshft(node2, 19));
			node2 = (node1 ^ rshft(node2, 19));
			node1 = node2;
			node1 = (node2 ^ lshft_58(node1, 39));
			node1 = (node2 ^ lshft_58(node1, 39));
			node1 &= MASK(58);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 44));
			node2 = (node1 ^ rshft(node2, 44));
			node1 = node2;
			node1 = (node2 ^ lshft_58(node1, 14));
			node1 = (node2 ^ lshft_58(node1, 14));
			node1 = (node2 ^ lshft_58(node1, 14));
			node1 = (node2 ^ lshft_58(node1, 14));
			node1 = (node2 ^ lshft_58(node1, 14));
			node1 &= MASK(58);
			break;
		case 3:
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 28));
			node2 = (node1 ^ rshft(node2, 28));
			node2 = (node1 ^ rshft(node2, 28));
			node1 = node2;
			node1 = mult_58(node1, 0x3a638f15ba85841L);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 39));
			node2 = (node1 ^ rshft(node2, 39));
			node1 = node2;
			node1 = (node2 ^ rshft(node1, 33));
			node1 = (node2 ^ rshft(node1, 33));
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 25));
			node2 = (node1 ^ rshft(node2, 25));
			node2 = (node1 ^ rshft(node2, 25));
			node1 = node2;
			node1 = mult_58(node1, 0x20fabc04158ce41L);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 24));
			node2 = (node1 ^ rshft(node2, 24));
			node2 = (node1 ^ rshft(node2, 24));
			node1 = node2;
			node1 = (node2 ^ lshft_58(node1, 34));
			node1 = (node2 ^ lshft_58(node1, 34));
			node1 &= MASK(58);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 45));
			node2 = (node1 ^ rshft(node2, 45));
			node1 = node2;
			node1 = (node2 ^ lshft_58(node1, 13));
			node1 = (node2 ^ lshft_58(node1, 13));
			node1 = (node2 ^ lshft_58(node1, 13));
			node1 = (node2 ^ lshft_58(node1, 13));
			node1 = (node2 ^ lshft_58(node1, 13));
			node1 &= MASK(58);
			break;
		case 4:
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 20));
			node2 = (node1 ^ rshft(node2, 20));
			node2 = (node1 ^ rshft(node2, 20));
			node1 = node2;
			node1 = mult_58(node1, 0x3592d3c27c27041L);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 23));
			node2 = (node1 ^ rshft(node2, 23));
			node2 = (node1 ^ rshft(node2, 23));
			node1 = node2;
			node1 = (node2 ^ rshft(node1, 30));
			node1 = (node2 ^ rshft(node1, 30));
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 26));
			node2 = (node1 ^ rshft(node2, 26));
			node2 = (node1 ^ rshft(node2, 26));
			node1 = node2;
			node1 = mult_58(node1, 0x4f6952eaf8fdc1L);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 23));
			node2 = (node1 ^ rshft(node2, 23));
			node2 = (node1 ^ rshft(node2, 23));
			node1 = node2;
			node1 = (node2 ^ lshft_58(node1, 35));
			node1 = (node2 ^ lshft_58(node1, 35));
			node1 &= MASK(58);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 47));
			node2 = (node1 ^ rshft(node2, 47));
			node1 = node2;
			node1 = (node2 ^ lshft_58(node1, 11));
			node1 = (node2 ^ lshft_58(node1, 11));
			node1 = (node2 ^ lshft_58(node1, 11));
			node1 = (node2 ^ lshft_58(node1, 11));
			node1 = (node2 ^ lshft_58(node1, 11));
			node1 = (node2 ^ lshft_58(node1, 11));
			node1 &= MASK(58);
			break;
		case 5:
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 23));
			node2 = (node1 ^ rshft(node2, 23));
			node2 = (node1 ^ rshft(node2, 23));
			node1 = node2;
			node1 = mult_58(node1, 0x1a0c447ad94c6a1L);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 41));
			node2 = (node1 ^ rshft(node2, 41));
			node1 = node2;
			node1 = (node2 ^ rshft(node1, 36));
			node1 = (node2 ^ rshft(node1, 36));
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 20));
			node2 = (node1 ^ rshft(node2, 20));
			node2 = (node1 ^ rshft(node2, 20));
			node1 = node2;
			node1 = mult_58(node1, 0x2a87df258789081L);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 25));
			node2 = (node1 ^ rshft(node2, 25));
			node2 = (node1 ^ rshft(node2, 25));
			node1 = node2;
			node1 = (node2 ^ lshft_58(node1, 33));
			node1 = (node2 ^ lshft_58(node1, 33));
			node1 &= MASK(58);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 43));
			node2 = (node1 ^ rshft(node2, 43));
			node1 = node2;
			node1 = (node2 ^ lshft_58(node1, 15));
			node1 = (node2 ^ lshft_58(node1, 15));
			node1 = (node2 ^ lshft_58(node1, 15));
			node1 = (node2 ^ lshft_58(node1, 15));
			node1 &= MASK(58);
			break;
		case 6:
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 29));
			node2 = (node1 ^ rshft(node2, 29));
			node1 = node2;
			node1 = mult_58(node1, 0xa6775beb906d01L);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 38));
			node2 = (node1 ^ rshft(node2, 38));
			node1 = node2;
			node1 = (node2 ^ rshft(node1, 42));
			node1 = (node2 ^ rshft(node1, 42));
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 24));
			node2 = (node1 ^ rshft(node2, 24));
			node2 = (node1 ^ rshft(node2, 24));
			node1 = node2;
			node1 = mult_58(node1, 0x37e24eee615e541L);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 46));
			node2 = (node1 ^ rshft(node2, 46));
			node1 = node2;
			node1 = (node2 ^ lshft_58(node1, 12));
			node1 = (node2 ^ lshft_58(node1, 12));
			node1 = (node2 ^ lshft_58(node1, 12));
			node1 = (node2 ^ lshft_58(node1, 12));
			node1 = (node2 ^ lshft_58(node1, 12));
			node1 &= MASK(58);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 24));
			node2 = (node1 ^ rshft(node2, 24));
			node2 = (node1 ^ rshft(node2, 24));
			node1 = node2;
			node1 = (node2 ^ lshft_58(node1, 34));
			node1 = (node2 ^ lshft_58(node1, 34));
			node1 &= MASK(58);
			break;
		case 7:
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 26));
			node2 = (node1 ^ rshft(node2, 26));
			node2 = (node1 ^ rshft(node2, 26));
			node1 = node2;
			node1 = mult_58(node1, 0x33b48646b8f9de1L);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 26));
			node2 = (node1 ^ rshft(node2, 26));
			node2 = (node1 ^ rshft(node2, 26));
			node1 = node2;
			node1 = (node2 ^ rshft(node1, 46));
			node1 = (node2 ^ rshft(node1, 46));
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 23));
			node2 = (node1 ^ rshft(node2, 23));
			node2 = (node1 ^ rshft(node2, 23));
			node1 = node2;
			node1 = mult_58(node1, 0x14eaae5968790e1L);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 23));
			node2 = (node1 ^ rshft(node2, 23));
			node2 = (node1 ^ rshft(node2, 23));
			node1 = node2;
			node1 = (node2 ^ lshft_58(node1, 35));
			node1 = (node2 ^ lshft_58(node1, 35));
			node1 &= MASK(58);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 35));
			node2 = (node1 ^ rshft(node2, 35));
			node1 = node2;
			node1 = (node2 ^ lshft_58(node1, 23));
			node1 = (node2 ^ lshft_58(node1, 23));
			node1 = (node2 ^ lshft_58(node1, 23));
			node1 &= MASK(58);
			break;
		case 8:
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 27));
			node2 = (node1 ^ rshft(node2, 27));
			node2 = (node1 ^ rshft(node2, 27));
			node1 = node2;
			node1 = mult_58(node1, 0x1fdf88f19a49f61L);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 29));
			node2 = (node1 ^ rshft(node2, 29));
			node1 = node2;
			node1 = (node2 ^ rshft(node1, 40));
			node1 = (node2 ^ rshft(node1, 40));
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 20));
			node2 = (node1 ^ rshft(node2, 20));
			node2 = (node1 ^ rshft(node2, 20));
			node1 = node2;
			node1 = mult_58(node1, 0xdbbcfbf69154c1L);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 24));
			node2 = (node1 ^ rshft(node2, 24));
			node2 = (node1 ^ rshft(node2, 24));
			node1 = node2;
			node1 = (node2 ^ lshft_58(node1, 34));
			node1 = (node2 ^ lshft_58(node1, 34));
			node1 &= MASK(58);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 27));
			node2 = (node1 ^ rshft(node2, 27));
			node2 = (node1 ^ rshft(node2, 27));
			node1 = node2;
			node1 = (node2 ^ lshft_58(node1, 31));
			node1 = (node2 ^ lshft_58(node1, 31));
			node1 &= MASK(58);
			break;
		case 9:
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 30));
			node2 = (node1 ^ rshft(node2, 30));
			node1 = node2;
			node1 = mult_58(node1, 0x2565bb394a9f561L);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 40));
			node2 = (node1 ^ rshft(node2, 40));
			node1 = node2;
			node1 = (node2 ^ rshft(node1, 33));
			node1 = (node2 ^ rshft(node1, 33));
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 25));
			node2 = (node1 ^ rshft(node2, 25));
			node2 = (node1 ^ rshft(node2, 25));
			node1 = node2;
			node1 = mult_58(node1, 0x209a299946a201L);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 38));
			node2 = (node1 ^ rshft(node2, 38));
			node1 = node2;
			node1 = (node2 ^ lshft_58(node1, 20));
			node1 = (node2 ^ lshft_58(node1, 20));
			node1 = (node2 ^ lshft_58(node1, 20));
			node1 &= MASK(58);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 34));
			node2 = (node1 ^ rshft(node2, 34));
			node1 = node2;
			node1 = (node2 ^ lshft_58(node1, 24));
			node1 = (node2 ^ lshft_58(node1, 24));
			node1 = (node2 ^ lshft_58(node1, 24));
			node1 &= MASK(58);
			break;
		case 10:
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 28));
			node2 = (node1 ^ rshft(node2, 28));
			node2 = (node1 ^ rshft(node2, 28));
			node1 = node2;
			node1 = mult_58(node1, 0x2749093cc470e01L);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 26));
			node2 = (node1 ^ rshft(node2, 26));
			node2 = (node1 ^ rshft(node2, 26));
			node1 = node2;
			node1 = (node2 ^ rshft(node1, 46));
			node1 = (node2 ^ rshft(node1, 46));
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 23));
			node2 = (node1 ^ rshft(node2, 23));
			node2 = (node1 ^ rshft(node2, 23));
			node1 = node2;
			node1 = mult_58(node1, 0x397388d192dcc81L);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 39));
			node2 = (node1 ^ rshft(node2, 39));
			node1 = node2;
			node1 = (node2 ^ lshft_58(node1, 19));
			node1 = (node2 ^ lshft_58(node1, 19));
			node1 = (node2 ^ lshft_58(node1, 19));
			node1 = (node2 ^ lshft_58(node1, 19));
			node1 &= MASK(58);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 48));
			node2 = (node1 ^ rshft(node2, 48));
			node1 = node2;
			node1 = (node2 ^ lshft_58(node1, 10));
			node1 = (node2 ^ lshft_58(node1, 10));
			node1 = (node2 ^ lshft_58(node1, 10));
			node1 = (node2 ^ lshft_58(node1, 10));
			node1 = (node2 ^ lshft_58(node1, 10));
			node1 = (node2 ^ lshft_58(node1, 10));
			node1 &= MASK(58);
			break;
		case 11:
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 31));
			node2 = (node1 ^ rshft(node2, 31));
			node1 = node2;
			node1 = mult_58(node1, 0x31b72238ae7fba1L);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 43));
			node2 = (node1 ^ rshft(node2, 43));
			node1 = node2;
			node1 = (node2 ^ rshft(node1, 12));
			node1 = (node2 ^ rshft(node1, 12));
			node1 = (node2 ^ rshft(node1, 12));
			node1 = (node2 ^ rshft(node1, 12));
			node1 = (node2 ^ rshft(node1, 12));
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 26));
			node2 = (node1 ^ rshft(node2, 26));
			node2 = (node1 ^ rshft(node2, 26));
			node1 = node2;
			node1 = mult_58(node1, 0x17db804c1d6e261L);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 28));
			node2 = (node1 ^ rshft(node2, 28));
			node2 = (node1 ^ rshft(node2, 28));
			node1 = node2;
			node1 = (node2 ^ lshft_58(node1, 30));
			node1 = (node2 ^ lshft_58(node1, 30));
			node1 &= MASK(58);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 44));
			node2 = (node1 ^ rshft(node2, 44));
			node1 = node2;
			node1 = (node2 ^ lshft_58(node1, 14));
			node1 = (node2 ^ lshft_58(node1, 14));
			node1 = (node2 ^ lshft_58(node1, 14));
			node1 = (node2 ^ lshft_58(node1, 14));
			node1 = (node2 ^ lshft_58(node1, 14));
			node1 &= MASK(58);
			break;
		case 12:
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 25));
			node2 = (node1 ^ rshft(node2, 25));
			node2 = (node1 ^ rshft(node2, 25));
			node1 = node2;
			node1 = mult_58(node1, 0x17cd12a8d2eeb41L);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 24));
			node2 = (node1 ^ rshft(node2, 24));
			node2 = (node1 ^ rshft(node2, 24));
			node1 = node2;
			node1 = (node2 ^ rshft(node1, 39));
			node1 = (node2 ^ rshft(node1, 39));
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 21));
			node2 = (node1 ^ rshft(node2, 21));
			node2 = (node1 ^ rshft(node2, 21));
			node1 = node2;
			node1 = mult_58(node1, 0xdda8affbefdb61L);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 17));
			node2 = (node1 ^ rshft(node2, 17));
			node2 = (node1 ^ rshft(node2, 17));
			node2 = (node1 ^ rshft(node2, 17));
			node1 = node2;
			node1 = (node2 ^ lshft_58(node1, 41));
			node1 = (node2 ^ lshft_58(node1, 41));
			node1 &= MASK(58);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 39));
			node2 = (node1 ^ rshft(node2, 39));
			node1 = node2;
			node1 = (node2 ^ lshft_58(node1, 19));
			node1 = (node2 ^ lshft_58(node1, 19));
			node1 = (node2 ^ lshft_58(node1, 19));
			node1 = (node2 ^ lshft_58(node1, 19));
			node1 &= MASK(58);
			break;
		case 13:
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 27));
			node2 = (node1 ^ rshft(node2, 27));
			node2 = (node1 ^ rshft(node2, 27));
			node1 = node2;
			node1 = mult_58(node1, 0x13d6fbb801b6301L);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 32));
			node2 = (node1 ^ rshft(node2, 32));
			node1 = node2;
			node1 = (node2 ^ rshft(node1, 40));
			node1 = (node2 ^ rshft(node1, 40));
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 24));
			node2 = (node1 ^ rshft(node2, 24));
			node2 = (node1 ^ rshft(node2, 24));
			node1 = node2;
			node1 = mult_58(node1, 0x34aade611b82a21L);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 43));
			node2 = (node1 ^ rshft(node2, 43));
			node1 = node2;
			node1 = (node2 ^ lshft_58(node1, 15));
			node1 = (node2 ^ lshft_58(node1, 15));
			node1 = (node2 ^ lshft_58(node1, 15));
			node1 = (node2 ^ lshft_58(node1, 15));
			node1 &= MASK(58);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 30));
			node2 = (node1 ^ rshft(node2, 30));
			node1 = node2;
			node1 = (node2 ^ lshft_58(node1, 28));
			node1 = (node2 ^ lshft_58(node1, 28));
			node1 = (node2 ^ lshft_58(node1, 28));
			node1 &= MASK(58);
			break;
		case 14:
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 26));
			node2 = (node1 ^ rshft(node2, 26));
			node2 = (node1 ^ rshft(node2, 26));
			node1 = node2;
			node1 = mult_58(node1, 0x303124e6af65701L);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 31));
			node2 = (node1 ^ rshft(node2, 31));
			node1 = node2;
			node1 = (node2 ^ rshft(node1, 46));
			node1 = (node2 ^ rshft(node1, 46));
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 28));
			node2 = (node1 ^ rshft(node2, 28));
			node2 = (node1 ^ rshft(node2, 28));
			node1 = node2;
			node1 = mult_58(node1, 0x2b47151bd0a7c61L);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 26));
			node2 = (node1 ^ rshft(node2, 26));
			node2 = (node1 ^ rshft(node2, 26));
			node1 = node2;
			node1 = (node2 ^ lshft_58(node1, 32));
			node1 = (node2 ^ lshft_58(node1, 32));
			node1 &= MASK(58);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 15));
			node2 = (node1 ^ rshft(node2, 15));
			node2 = (node1 ^ rshft(node2, 15));
			node2 = (node1 ^ rshft(node2, 15));
			node1 = node2;
			node1 = (node2 ^ lshft_58(node1, 43));
			node1 = (node2 ^ lshft_58(node1, 43));
			node1 &= MASK(58);
			break;
		case 15:
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 28));
			node2 = (node1 ^ rshft(node2, 28));
			node2 = (node1 ^ rshft(node2, 28));
			node1 = node2;
			node1 = mult_58(node1, 0x1941bdcc12c0021L);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 25));
			node2 = (node1 ^ rshft(node2, 25));
			node2 = (node1 ^ rshft(node2, 25));
			node1 = node2;
			node1 = (node2 ^ rshft(node1, 44));
			node1 = (node2 ^ rshft(node1, 44));
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 29));
			node2 = (node1 ^ rshft(node2, 29));
			node1 = node2;
			node1 = mult_58(node1, 0x998456ffaa62a1L);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 16));
			node2 = (node1 ^ rshft(node2, 16));
			node2 = (node1 ^ rshft(node2, 16));
			node2 = (node1 ^ rshft(node2, 16));
			node1 = node2;
			node1 = (node2 ^ lshft_58(node1, 42));
			node1 = (node2 ^ lshft_58(node1, 42));
			node1 &= MASK(58);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 23));
			node2 = (node1 ^ rshft(node2, 23));
			node2 = (node1 ^ rshft(node2, 23));
			node1 = node2;
			node1 = (node2 ^ lshft_58(node1, 35));
			node1 = (node2 ^ lshft_58(node1, 35));
			node1 &= MASK(58);
			break;
		case 16:
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 35));
			node2 = (node1 ^ rshft(node2, 35));
			node1 = node2;
			node1 = mult_58(node1, 0x2efb706fdede9e1L);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 20));
			node2 = (node1 ^ rshft(node2, 20));
			node2 = (node1 ^ rshft(node2, 20));
			node1 = node2;
			node1 = (node2 ^ rshft(node1, 29));
			node1 = (node2 ^ rshft(node1, 29));
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 44));
			node2 = (node1 ^ rshft(node2, 44));
			node1 = node2;
			node1 = mult_58(node1, 0x3933d59b50dfb81L);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 9));
			node2 = (node1 ^ rshft(node2, 9));
			node2 = (node1 ^ rshft(node2, 9));
			node2 = (node1 ^ rshft(node2, 9));
			node2 = (node1 ^ rshft(node2, 9));
			node2 = (node1 ^ rshft(node2, 9));
			node2 = (node1 ^ rshft(node2, 9));
			node1 = node2;
			node1 = (node2 ^ lshft_58(node1, 49));
			node1 = (node2 ^ lshft_58(node1, 49));
			node1 &= MASK(58);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 23));
			node2 = (node1 ^ rshft(node2, 23));
			node2 = (node1 ^ rshft(node2, 23));
			node1 = node2;
			node1 = (node2 ^ lshft_58(node1, 35));
			node1 = (node2 ^ lshft_58(node1, 35));
			node1 &= MASK(58);
			break;
		case 17:
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 41));
			node2 = (node1 ^ rshft(node2, 41));
			node1 = node2;
			node1 = mult_58(node1, 0x21a8aeb5ab11cc1L);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 15));
			node2 = (node1 ^ rshft(node2, 15));
			node2 = (node1 ^ rshft(node2, 15));
			node2 = (node1 ^ rshft(node2, 15));
			node1 = node2;
			node1 = (node2 ^ rshft(node1, 44));
			node1 = (node2 ^ rshft(node1, 44));
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 33));
			node2 = (node1 ^ rshft(node2, 33));
			node1 = node2;
			node1 = mult_58(node1, 0x26923bf4120c7c1L);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 29));
			node2 = (node1 ^ rshft(node2, 29));
			node1 = node2;
			node1 = (node2 ^ lshft_58(node1, 29));
			node1 = (node2 ^ lshft_58(node1, 29));
			node1 &= MASK(58);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 13));
			node2 = (node1 ^ rshft(node2, 13));
			node2 = (node1 ^ rshft(node2, 13));
			node2 = (node1 ^ rshft(node2, 13));
			node2 = (node1 ^ rshft(node2, 13));
			node1 = node2;
			node1 = (node2 ^ lshft_58(node1, 45));
			node1 = (node2 ^ lshft_58(node1, 45));
			node1 &= MASK(58);
			break;
		case 18:
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 34));
			node2 = (node1 ^ rshft(node2, 34));
			node1 = node2;
			node1 = mult_58(node1, 0x399c741b25ccbc1L);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 21));
			node2 = (node1 ^ rshft(node2, 21));
			node2 = (node1 ^ rshft(node2, 21));
			node1 = node2;
			node1 = (node2 ^ rshft(node1, 41));
			node1 = (node2 ^ rshft(node1, 41));
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 13));
			node2 = (node1 ^ rshft(node2, 13));
			node2 = (node1 ^ rshft(node2, 13));
			node2 = (node1 ^ rshft(node2, 13));
			node2 = (node1 ^ rshft(node2, 13));
			node1 = node2;
			node1 = mult_58(node1, 0x31b1f4e059ed7e1L);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 22));
			node2 = (node1 ^ rshft(node2, 22));
			node2 = (node1 ^ rshft(node2, 22));
			node1 = node2;
			node1 = (node2 ^ lshft_58(node1, 36));
			node1 = (node2 ^ lshft_58(node1, 36));
			node1 &= MASK(58);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 38));
			node2 = (node1 ^ rshft(node2, 38));
			node1 = node2;
			node1 = (node2 ^ lshft_58(node1, 20));
			node1 = (node2 ^ lshft_58(node1, 20));
			node1 = (node2 ^ lshft_58(node1, 20));
			node1 &= MASK(58);
			break;
		case 19:
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 15));
			node2 = (node1 ^ rshft(node2, 15));
			node2 = (node1 ^ rshft(node2, 15));
			node2 = (node1 ^ rshft(node2, 15));
			node1 = node2;
			node1 = mult_58(node1, 0x1880d14f55dbb01L);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 49));
			node2 = (node1 ^ rshft(node2, 49));
			node1 = node2;
			node1 = (node2 ^ rshft(node1, 11));
			node1 = (node2 ^ rshft(node1, 11));
			node1 = (node2 ^ rshft(node1, 11));
			node1 = (node2 ^ rshft(node1, 11));
			node1 = (node2 ^ rshft(node1, 11));
			node1 = (node2 ^ rshft(node1, 11));
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 34));
			node2 = (node1 ^ rshft(node2, 34));
			node1 = node2;
			node1 = mult_58(node1, 0x201dedfc54d45e1L);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 50));
			node2 = (node1 ^ rshft(node2, 50));
			node1 = node2;
			node1 = (node2 ^ lshft_58(node1, 8));
			node1 = (node2 ^ lshft_58(node1, 8));
			node1 = (node2 ^ lshft_58(node1, 8));
			node1 = (node2 ^ lshft_58(node1, 8));
			node1 = (node2 ^ lshft_58(node1, 8));
			node1 = (node2 ^ lshft_58(node1, 8));
			node1 = (node2 ^ lshft_58(node1, 8));
			node1 = (node2 ^ lshft_58(node1, 8));
			node1 &= MASK(58);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 48));
			node2 = (node1 ^ rshft(node2, 48));
			node1 = node2;
			node1 = (node2 ^ lshft_58(node1, 10));
			node1 = (node2 ^ lshft_58(node1, 10));
			node1 = (node2 ^ lshft_58(node1, 10));
			node1 = (node2 ^ lshft_58(node1, 10));
			node1 = (node2 ^ lshft_58(node1, 10));
			node1 = (node2 ^ lshft_58(node1, 10));
			node1 &= MASK(58);
			break;
		case 20:
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 24));
			node2 = (node1 ^ rshft(node2, 24));
			node2 = (node1 ^ rshft(node2, 24));
			node1 = node2;
			node1 = mult_58(node1, 0x2afe38ab861ce41L);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 43));
			node2 = (node1 ^ rshft(node2, 43));
			node1 = node2;
			node1 = (node2 ^ rshft(node1, 39));
			node1 = (node2 ^ rshft(node1, 39));
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 49));
			node2 = (node1 ^ rshft(node2, 49));
			node1 = node2;
			node1 = mult_58(node1, 0xdf792e0ca5e01L);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 8));
			node2 = (node1 ^ rshft(node2, 8));
			node2 = (node1 ^ rshft(node2, 8));
			node2 = (node1 ^ rshft(node2, 8));
			node2 = (node1 ^ rshft(node2, 8));
			node2 = (node1 ^ rshft(node2, 8));
			node2 = (node1 ^ rshft(node2, 8));
			node2 = (node1 ^ rshft(node2, 8));
			node1 = node2;
			node1 = (node2 ^ lshft_58(node1, 50));
			node1 = (node2 ^ lshft_58(node1, 50));
			node1 &= MASK(58);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 29));
			node2 = (node1 ^ rshft(node2, 29));
			node1 = node2;
			node1 = (node2 ^ lshft_58(node1, 29));
			node1 = (node2 ^ lshft_58(node1, 29));
			node1 &= MASK(58);
			break;
		case 21:
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 44));
			node2 = (node1 ^ rshft(node2, 44));
			node1 = node2;
			node1 = mult_58(node1, 0x11e22dcd774701L);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 50));
			node2 = (node1 ^ rshft(node2, 50));
			node1 = node2;
			node1 = (node2 ^ rshft(node1, 34));
			node1 = (node2 ^ rshft(node1, 34));
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 48));
			node2 = (node1 ^ rshft(node2, 48));
			node1 = node2;
			node1 = mult_58(node1, 0x36a0d8d37e9e601L);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 27));
			node2 = (node1 ^ rshft(node2, 27));
			node2 = (node1 ^ rshft(node2, 27));
			node1 = node2;
			node1 = (node2 ^ lshft_58(node1, 31));
			node1 = (node2 ^ lshft_58(node1, 31));
			node1 &= MASK(58);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 20));
			node2 = (node1 ^ rshft(node2, 20));
			node2 = (node1 ^ rshft(node2, 20));
			node1 = node2;
			node1 = (node2 ^ lshft_58(node1, 38));
			node1 = (node2 ^ lshft_58(node1, 38));
			node1 &= MASK(58);
			break;
		case 22:
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 8));
			node2 = (node1 ^ rshft(node2, 8));
			node2 = (node1 ^ rshft(node2, 8));
			node2 = (node1 ^ rshft(node2, 8));
			node2 = (node1 ^ rshft(node2, 8));
			node2 = (node1 ^ rshft(node2, 8));
			node2 = (node1 ^ rshft(node2, 8));
			node2 = (node1 ^ rshft(node2, 8));
			node1 = node2;
			node1 = mult_58(node1, 0x358ac41663d0921L);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 11));
			node2 = (node1 ^ rshft(node2, 11));
			node2 = (node1 ^ rshft(node2, 11));
			node2 = (node1 ^ rshft(node2, 11));
			node2 = (node1 ^ rshft(node2, 11));
			node2 = (node1 ^ rshft(node2, 11));
			node1 = node2;
			node1 = (node2 ^ rshft(node1, 23));
			node1 = (node2 ^ rshft(node1, 23));
			node1 = (node2 ^ rshft(node1, 23));
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 11));
			node2 = (node1 ^ rshft(node2, 11));
			node2 = (node1 ^ rshft(node2, 11));
			node2 = (node1 ^ rshft(node2, 11));
			node2 = (node1 ^ rshft(node2, 11));
			node2 = (node1 ^ rshft(node2, 11));
			node1 = node2;
			node1 = mult_58(node1, 0xa7320f9e9cfd01L);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 9));
			node2 = (node1 ^ rshft(node2, 9));
			node2 = (node1 ^ rshft(node2, 9));
			node2 = (node1 ^ rshft(node2, 9));
			node2 = (node1 ^ rshft(node2, 9));
			node2 = (node1 ^ rshft(node2, 9));
			node2 = (node1 ^ rshft(node2, 9));
			node1 = node2;
			node1 = (node2 ^ lshft_58(node1, 49));
			node1 = (node2 ^ lshft_58(node1, 49));
			node1 &= MASK(58);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 44));
			node2 = (node1 ^ rshft(node2, 44));
			node1 = node2;
			node1 = (node2 ^ lshft_58(node1, 14));
			node1 = (node2 ^ lshft_58(node1, 14));
			node1 = (node2 ^ lshft_58(node1, 14));
			node1 = (node2 ^ lshft_58(node1, 14));
			node1 = (node2 ^ lshft_58(node1, 14));
			node1 &= MASK(58);
			break;
		case 23:
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 43));
			node2 = (node1 ^ rshft(node2, 43));
			node1 = node2;
			node1 = mult_58(node1, 0x18e70c0e0a798c1L);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 50));
			node2 = (node1 ^ rshft(node2, 50));
			node1 = node2;
			node1 = (node2 ^ rshft(node1, 29));
			node1 = (node2 ^ rshft(node1, 29));
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 28));
			node2 = (node1 ^ rshft(node2, 28));
			node2 = (node1 ^ rshft(node2, 28));
			node1 = node2;
			node1 = mult_58(node1, 0x1a5d3987f4fc5c1L);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 39));
			node2 = (node1 ^ rshft(node2, 39));
			node1 = node2;
			node1 = (node2 ^ lshft_58(node1, 19));
			node1 = (node2 ^ lshft_58(node1, 19));
			node1 = (node2 ^ lshft_58(node1, 19));
			node1 = (node2 ^ lshft_58(node1, 19));
			node1 &= MASK(58);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 38));
			node2 = (node1 ^ rshft(node2, 38));
			node1 = node2;
			node1 = (node2 ^ lshft_58(node1, 20));
			node1 = (node2 ^ lshft_58(node1, 20));
			node1 = (node2 ^ lshft_58(node1, 20));
			node1 &= MASK(58);
			break;
		case 24:
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 20));
			node2 = (node1 ^ rshft(node2, 20));
			node2 = (node1 ^ rshft(node2, 20));
			node1 = node2;
			node1 = mult_58(node1, 0x114d3af41ee9c381L);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 39));
			node2 = (node1 ^ rshft(node2, 39));
			node1 = node2;
			node1 = (node2 ^ rshft(node1, 14));
			node1 = (node2 ^ rshft(node1, 14));
			node1 = (node2 ^ rshft(node1, 14));
			node1 = (node2 ^ rshft(node1, 14));
			node1 = (node2 ^ rshft(node1, 14));
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 32));
			node2 = (node1 ^ rshft(node2, 32));
			node1 = node2;
			node1 = mult_58(node1, 0x2c334d4e37573c1L);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 40));
			node2 = (node1 ^ rshft(node2, 40));
			node1 = node2;
			node1 = (node2 ^ lshft_58(node1, 18));
			node1 = (node2 ^ lshft_58(node1, 18));
			node1 = (node2 ^ lshft_58(node1, 18));
			node1 = (node2 ^ lshft_58(node1, 18));
			node1 &= MASK(58);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 27));
			node2 = (node1 ^ rshft(node2, 27));
			node2 = (node1 ^ rshft(node2, 27));
			node1 = node2;
			node1 = (node2 ^ lshft_58(node1, 31));
			node1 = (node2 ^ lshft_58(node1, 31));
			node1 &= MASK(58);
			break;
		case 25:
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 25));
			node2 = (node1 ^ rshft(node2, 25));
			node2 = (node1 ^ rshft(node2, 25));
			node1 = node2;
			node1 = mult_58(node1, 0xb5b41ead3ee61L);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 18));
			node2 = (node1 ^ rshft(node2, 18));
			node2 = (node1 ^ rshft(node2, 18));
			node2 = (node1 ^ rshft(node2, 18));
			node1 = node2;
			node1 = (node2 ^ rshft(node1, 24));
			node1 = (node2 ^ rshft(node1, 24));
			node1 = (node2 ^ rshft(node1, 24));
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 50));
			node2 = (node1 ^ rshft(node2, 50));
			node1 = node2;
			node1 = mult_58(node1, 0x343bd3492677c61L);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 23));
			node2 = (node1 ^ rshft(node2, 23));
			node2 = (node1 ^ rshft(node2, 23));
			node1 = node2;
			node1 = (node2 ^ lshft_58(node1, 35));
			node1 = (node2 ^ lshft_58(node1, 35));
			node1 &= MASK(58);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 32));
			node2 = (node1 ^ rshft(node2, 32));
			node1 = node2;
			node1 = (node2 ^ lshft_58(node1, 26));
			node1 = (node2 ^ lshft_58(node1, 26));
			node1 = (node2 ^ lshft_58(node1, 26));
			node1 &= MASK(58);
			break;
		case 26:
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 17));
			node2 = (node1 ^ rshft(node2, 17));
			node2 = (node1 ^ rshft(node2, 17));
			node2 = (node1 ^ rshft(node2, 17));
			node1 = node2;
			node1 = mult_58(node1, 0xdd46cce498c601L);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 28));
			node2 = (node1 ^ rshft(node2, 28));
			node2 = (node1 ^ rshft(node2, 28));
			node1 = node2;
			node1 = (node2 ^ rshft(node1, 33));
			node1 = (node2 ^ rshft(node1, 33));
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 41));
			node2 = (node1 ^ rshft(node2, 41));
			node1 = node2;
			node1 = mult_58(node1, 0xb43892c16569e1L);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 9));
			node2 = (node1 ^ rshft(node2, 9));
			node2 = (node1 ^ rshft(node2, 9));
			node2 = (node1 ^ rshft(node2, 9));
			node2 = (node1 ^ rshft(node2, 9));
			node2 = (node1 ^ rshft(node2, 9));
			node2 = (node1 ^ rshft(node2, 9));
			node1 = node2;
			node1 = (node2 ^ lshft_58(node1, 49));
			node1 = (node2 ^ lshft_58(node1, 49));
			node1 &= MASK(58);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 10));
			node2 = (node1 ^ rshft(node2, 10));
			node2 = (node1 ^ rshft(node2, 10));
			node2 = (node1 ^ rshft(node2, 10));
			node2 = (node1 ^ rshft(node2, 10));
			node2 = (node1 ^ rshft(node2, 10));
			node1 = node2;
			node1 = (node2 ^ lshft_58(node1, 48));
			node1 = (node2 ^ lshft_58(node1, 48));
			node1 &= MASK(58);
			break;
		case 27:
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 18));
			node2 = (node1 ^ rshft(node2, 18));
			node2 = (node1 ^ rshft(node2, 18));
			node2 = (node1 ^ rshft(node2, 18));
			node1 = node2;
			node1 = mult_58(node1, 0x3e7f2be0c9cbf41L);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 46));
			node2 = (node1 ^ rshft(node2, 46));
			node1 = node2;
			node1 = (node2 ^ rshft(node1, 43));
			node1 = (node2 ^ rshft(node1, 43));
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 23));
			node2 = (node1 ^ rshft(node2, 23));
			node2 = (node1 ^ rshft(node2, 23));
			node1 = node2;
			node1 = mult_58(node1, 0x2a9e04101a91781L);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 38));
			node2 = (node1 ^ rshft(node2, 38));
			node1 = node2;
			node1 = (node2 ^ lshft_58(node1, 20));
			node1 = (node2 ^ lshft_58(node1, 20));
			node1 = (node2 ^ lshft_58(node1, 20));
			node1 &= MASK(58);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 32));
			node2 = (node1 ^ rshft(node2, 32));
			node1 = node2;
			node1 = (node2 ^ lshft_58(node1, 26));
			node1 = (node2 ^ lshft_58(node1, 26));
			node1 = (node2 ^ lshft_58(node1, 26));
			node1 &= MASK(58);
			break;
		case 28:
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 29));
			node2 = (node1 ^ rshft(node2, 29));
			node1 = node2;
			node1 = mult_58(node1, 0x1bf68f79001a3c1L);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 10));
			node2 = (node1 ^ rshft(node2, 10));
			node2 = (node1 ^ rshft(node2, 10));
			node2 = (node1 ^ rshft(node2, 10));
			node2 = (node1 ^ rshft(node2, 10));
			node2 = (node1 ^ rshft(node2, 10));
			node1 = node2;
			node1 = (node2 ^ rshft(node1, 15));
			node1 = (node2 ^ rshft(node1, 15));
			node1 = (node2 ^ rshft(node1, 15));
			node1 = (node2 ^ rshft(node1, 15));
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 49));
			node2 = (node1 ^ rshft(node2, 49));
			node1 = node2;
			node1 = mult_58(node1, 0x5e966c19447561L);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 46));
			node2 = (node1 ^ rshft(node2, 46));
			node1 = node2;
			node1 = (node2 ^ lshft_58(node1, 12));
			node1 = (node2 ^ lshft_58(node1, 12));
			node1 = (node2 ^ lshft_58(node1, 12));
			node1 = (node2 ^ lshft_58(node1, 12));
			node1 = (node2 ^ lshft_58(node1, 12));
			node1 &= MASK(58);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 26));
			node2 = (node1 ^ rshft(node2, 26));
			node2 = (node1 ^ rshft(node2, 26));
			node1 = node2;
			node1 = (node2 ^ lshft_58(node1, 32));
			node1 = (node2 ^ lshft_58(node1, 32));
			node1 &= MASK(58);
			break;
		case 29:
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 49));
			node2 = (node1 ^ rshft(node2, 49));
			node1 = node2;
			node1 = mult_58(node1, 0x11235df1f15f921L);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 27));
			node2 = (node1 ^ rshft(node2, 27));
			node2 = (node1 ^ rshft(node2, 27));
			node1 = node2;
			node1 = (node2 ^ rshft(node1, 45));
			node1 = (node2 ^ rshft(node1, 45));
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 36));
			node2 = (node1 ^ rshft(node2, 36));
			node1 = node2;
			node1 = mult_58(node1, 0x5e845710612d61L);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 9));
			node2 = (node1 ^ rshft(node2, 9));
			node2 = (node1 ^ rshft(node2, 9));
			node2 = (node1 ^ rshft(node2, 9));
			node2 = (node1 ^ rshft(node2, 9));
			node2 = (node1 ^ rshft(node2, 9));
			node2 = (node1 ^ rshft(node2, 9));
			node1 = node2;
			node1 = (node2 ^ lshft_58(node1, 49));
			node1 = (node2 ^ lshft_58(node1, 49));
			node1 &= MASK(58);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 28));
			node2 = (node1 ^ rshft(node2, 28));
			node2 = (node1 ^ rshft(node2, 28));
			node1 = node2;
			node1 = (node2 ^ lshft_58(node1, 30));
			node1 = (node2 ^ lshft_58(node1, 30));
			node1 &= MASK(58);
			break;
		case 30:
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 43));
			node2 = (node1 ^ rshft(node2, 43));
			node1 = node2;
			node1 = mult_58(node1, 0x27940ca3c661161L);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 12));
			node2 = (node1 ^ rshft(node2, 12));
			node2 = (node1 ^ rshft(node2, 12));
			node2 = (node1 ^ rshft(node2, 12));
			node2 = (node1 ^ rshft(node2, 12));
			node1 = node2;
			node1 = (node2 ^ rshft(node1, 39));
			node1 = (node2 ^ rshft(node1, 39));
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 34));
			node2 = (node1 ^ rshft(node2, 34));
			node1 = node2;
			node1 = mult_58(node1, 0xe1cd6bed930441L);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 41));
			node2 = (node1 ^ rshft(node2, 41));
			node1 = node2;
			node1 = (node2 ^ lshft_58(node1, 17));
			node1 = (node2 ^ lshft_58(node1, 17));
			node1 = (node2 ^ lshft_58(node1, 17));
			node1 = (node2 ^ lshft_58(node1, 17));
			node1 &= MASK(58);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 30));
			node2 = (node1 ^ rshft(node2, 30));
			node1 = node2;
			node1 = (node2 ^ lshft_58(node1, 28));
			node1 = (node2 ^ lshft_58(node1, 28));
			node1 = (node2 ^ lshft_58(node1, 28));
			node1 &= MASK(58);
			break;
		case 31:
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 7));
			node2 = (node1 ^ rshft(node2, 7));
			node2 = (node1 ^ rshft(node2, 7));
			node2 = (node1 ^ rshft(node2, 7));
			node2 = (node1 ^ rshft(node2, 7));
			node2 = (node1 ^ rshft(node2, 7));
			node2 = (node1 ^ rshft(node2, 7));
			node2 = (node1 ^ rshft(node2, 7));
			node2 = (node1 ^ rshft(node2, 7));
			node1 = node2;
			node1 = mult_58(node1, 0x2bd62da95deb021L);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 28));
			node2 = (node1 ^ rshft(node2, 28));
			node2 = (node1 ^ rshft(node2, 28));
			node1 = node2;
			node1 = (node2 ^ rshft(node1, 39));
			node1 = (node2 ^ rshft(node1, 39));
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 50));
			node2 = (node1 ^ rshft(node2, 50));
			node1 = node2;
			node1 = mult_58(node1, 0xe61a0f027704e1L);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 48));
			node2 = (node1 ^ rshft(node2, 48));
			node1 = node2;
			node1 = (node2 ^ lshft_58(node1, 10));
			node1 = (node2 ^ lshft_58(node1, 10));
			node1 = (node2 ^ lshft_58(node1, 10));
			node1 = (node2 ^ lshft_58(node1, 10));
			node1 = (node2 ^ lshft_58(node1, 10));
			node1 = (node2 ^ lshft_58(node1, 10));
			node1 &= MASK(58);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 11));
			node2 = (node1 ^ rshft(node2, 11));
			node2 = (node1 ^ rshft(node2, 11));
			node2 = (node1 ^ rshft(node2, 11));
			node2 = (node1 ^ rshft(node2, 11));
			node2 = (node1 ^ rshft(node2, 11));
			node1 = node2;
			node1 = (node2 ^ lshft_58(node1, 47));
			node1 = (node2 ^ lshft_58(node1, 47));
			node1 &= MASK(58);
			break;
	}
	return node1;
}

/* 50 bits */

inline __host__ __device__ nodetype RHASH50(uint8_t id, nodetype node) {
	nodetype node1 = node;
	switch (id) {
		case 0:
			node1 = xor_shft2_50(node1, 14, 36);
			node1 = xor_shft2_50(node1, 30, 20);
			node1 = mult_50(node1, 0x346d5269d6a45L);
			node1 ^= rshft(node1, 39);
			node1 ^= rshft(node1, 31);
			node1 ^= rshft(node1, 23);
			node1 = mult_50(node1, 0x36d3c2b4804a9L);
			node1 ^= rshft(node1, 28);
			break;
		case 1:
			node1 = xor_shft2_50(node1, 10, 40);
			node1 = xor_shft2_50(node1, 35, 15);
			node1 = mult_50(node1, 0x3866c0692e5e5L);
			node1 ^= rshft(node1, 40);
			node1 ^= rshft(node1, 34);
			node1 ^= rshft(node1, 19);
			node1 = mult_50(node1, 0x39838add4d38fL);
			node1 ^= rshft(node1, 26);
			break;
		case 2:
			node1 = xor_shft2_50(node1, 21, 29);
			node1 = xor_shft2_50(node1, 33, 17);
			node1 = mult_50(node1, 0x3a57879143129L);
			node1 ^= rshft(node1, 44);
			node1 ^= rshft(node1, 30);
			node1 ^= rshft(node1, 15);
			node1 = mult_50(node1, 0x3afb7bb024c47L);
			node1 ^= rshft(node1, 30);
			break;
		case 3:
			node1 = xor_shft2_50(node1, 13, 37);
			node1 = xor_shft2_50(node1, 14, 36);
			node1 = mult_50(node1, 0x3b7e13a202e41L);
			node1 ^= rshft(node1, 39);
			node1 ^= rshft(node1, 33);
			node1 ^= rshft(node1, 25);
			node1 = mult_50(node1, 0x3be88e9173fb7L);
			node1 ^= rshft(node1, 28);
			break;
	}
	return node1;
}

// Inverse hash functions.
inline __host__ __device__ nodetype RHASH50_INVERSE(uint8_t id, nodetype node) {
	nodetype node1 = node;
	nodetype node2;
	switch (id) {
		case 0:
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 28));
			node2 = (node1 ^ rshft(node2, 28));
			node1 = node2;
			node1 = mult_50(node1, 0xf36a4076df99L);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 39));
			node2 = (node1 ^ rshft(node2, 39));
			node1 = node2;
			node1 = (node2 ^ rshft(node1, 31));
			node1 = (node2 ^ rshft(node1, 31));
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 23));
			node2 = (node1 ^ rshft(node2, 23));
			node2 = (node1 ^ rshft(node2, 23));
			node1 = node2;
			node1 = mult_50(node1, 0x1372f645e188dL);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 20));
			node2 = (node1 ^ rshft(node2, 20));
			node2 = (node1 ^ rshft(node2, 20));
			node1 = node2;
			node1 = (node2 ^ lshft_50(node1, 30));
			node1 = (node2 ^ lshft_50(node1, 30));
			node1 &= MASK(50);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 36));
			node2 = (node1 ^ rshft(node2, 36));
			node1 = node2;
			node1 = (node2 ^ lshft_50(node1, 14));
			node1 = (node2 ^ lshft_50(node1, 14));
			node1 = (node2 ^ lshft_50(node1, 14));
			node1 = (node2 ^ lshft_50(node1, 14));
			node1 &= MASK(50);
			break;
		case 1:
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 26));
			node2 = (node1 ^ rshft(node2, 26));
			node1 = node2;
			node1 = mult_50(node1, 0x3f5a2033ceb6fL);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 40));
			node2 = (node1 ^ rshft(node2, 40));
			node1 = node2;
			node1 = (node2 ^ rshft(node1, 34));
			node1 = (node2 ^ rshft(node1, 34));
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 19));
			node2 = (node1 ^ rshft(node2, 19));
			node2 = (node1 ^ rshft(node2, 19));
			node2 = (node1 ^ rshft(node2, 19));
			node1 = node2;
			node1 = mult_50(node1, 0x3787307d9cfedL);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 15));
			node2 = (node1 ^ rshft(node2, 15));
			node2 = (node1 ^ rshft(node2, 15));
			node2 = (node1 ^ rshft(node2, 15));
			node1 = node2;
			node1 = (node2 ^ lshft_50(node1, 35));
			node1 = (node2 ^ lshft_50(node1, 35));
			node1 &= MASK(50);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 40));
			node2 = (node1 ^ rshft(node2, 40));
			node1 = node2;
			node1 = (node2 ^ lshft_50(node1, 10));
			node1 = (node2 ^ lshft_50(node1, 10));
			node1 = (node2 ^ lshft_50(node1, 10));
			node1 = (node2 ^ lshft_50(node1, 10));
			node1 = (node2 ^ lshft_50(node1, 10));
			node1 &= MASK(50);
			break;
		case 2:
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 30));
			node2 = (node1 ^ rshft(node2, 30));
			node1 = node2;
			node1 = mult_50(node1, 0x365738c219d77L);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 44));
			node2 = (node1 ^ rshft(node2, 44));
			node1 = node2;
			node1 = (node2 ^ rshft(node1, 30));
			node1 = (node2 ^ rshft(node1, 30));
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 15));
			node2 = (node1 ^ rshft(node2, 15));
			node2 = (node1 ^ rshft(node2, 15));
			node2 = (node1 ^ rshft(node2, 15));
			node1 = node2;
			node1 = mult_50(node1, 0x2200650b4fb19L);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 17));
			node2 = (node1 ^ rshft(node2, 17));
			node2 = (node1 ^ rshft(node2, 17));
			node2 = (node1 ^ rshft(node2, 17));
			node1 = node2;
			node1 = (node2 ^ lshft_50(node1, 33));
			node1 = (node2 ^ lshft_50(node1, 33));
			node1 &= MASK(50);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 29));
			node2 = (node1 ^ rshft(node2, 29));
			node1 = node2;
			node1 = (node2 ^ lshft_50(node1, 21));
			node1 = (node2 ^ lshft_50(node1, 21));
			node1 = (node2 ^ lshft_50(node1, 21));
			node1 &= MASK(50);
			break;
		case 3:
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 28));
			node2 = (node1 ^ rshft(node2, 28));
			node1 = node2;
			node1 = mult_50(node1, 0x02b3c3bda8ce07L);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 39));
			node2 = (node1 ^ rshft(node2, 39));
			node1 = node2;
			node1 = (node2 ^ rshft(node1, 33));
			node1 = (node2 ^ rshft(node1, 33));
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 25));
			node2 = (node1 ^ rshft(node2, 25));
			node1 = node2;
			node1 = mult_50(node1, 0x253050b96e1c1L);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 36));
			node2 = (node1 ^ rshft(node2, 36));
			node1 = node2;
			node1 = (node2 ^ lshft_50(node1, 14));
			node1 = (node2 ^ lshft_50(node1, 14));
			node1 = (node2 ^ lshft_50(node1, 14));
			node1 = (node2 ^ lshft_50(node1, 14));
			node1 &= MASK(50);
			node2 = node1;
			node2 = (node1 ^ rshft(node2, 37));
			node2 = (node1 ^ rshft(node2, 37));
			node1 = node2;
			node1 = (node2 ^ lshft_50(node1, 13));
			node1 = (node2 ^ lshft_50(node1, 13));
			node1 = (node2 ^ lshft_50(node1, 13));
			node1 = (node2 ^ lshft_50(node1, 13));
			node1 &= MASK(50);
			break;
	}
	return node1;
}


/**************************************************************************************************************************************************************************************************************************************
* 
* 
* 
* 
*  32 Bit
* 
* 
* 
* 
* ************************************************************************************************************************************************************************************************************************************/


// Bit left shift function for 58 bits.
inline __host__ __device__ uint64_cu lshft_32(const uint64_cu x, uint8_t i) {
	uint64_cu y = (x << i);
	return y & MASK(32);
}

// Multiplication modulo 2^58.
inline __host__ __device__ uint64_cu mult_32(const uint64_cu x, uint64_cu a) {
	return ((x * a) & MASK(32));
}

// XOR two times bit shift function for 58 bits.
inline __host__ __device__ uint64_cu xor_shft2_32(const uint64_cu x, uint8_t a, uint8_t b) {
	uint64_cu y = (x ^ lshft_32(x, a));
	y = (y ^ rshft(y, b));
	return y;
}





inline __host__ __device__ nodetype RHASH32(uint8_t id, nodetype node) {
	nodetype node1 = node;
	switch (id) {
	case 0:
		node1 = xor_shft2_32(node1, 24, 8);
		node1 = xor_shft2_32(node1, 10, 22);
		node1 = mult_32(node1, 236110392309990593L);
		node1 ^= rshft(node1, 8);
		node1 ^= rshft(node1, 7);
		node1 ^= rshft(node1, 6);
		node1 = mult_32(node1, 246919711164770529L);
		node1 ^= rshft(node1, 19);
		break;

	case 1:
		node1 = xor_shft2_32(node1, 24, 8);
		node1 = xor_shft2_32(node1, 10, 22);
		node1 = mult_32(node1, 246919711164770529L);
		node1 ^= rshft(node1, 8);
		node1 ^= rshft(node1, 7);
		node1 ^= rshft(node1, 6);
		node1 = mult_32(node1, 254009204483154977L);
		node1 ^= rshft(node1, 19);
		break;
	case 2:
		node1 = xor_shft2_32(node1, 24, 8);
		node1 = xor_shft2_32(node1, 10, 22);
		node1 = mult_32(node1, 254009204483154977L);
		node1 ^= rshft(node1, 8);
		node1 ^= rshft(node1, 7);
		node1 ^= rshft(node1, 6);
		node1 = mult_32(node1, 259019297824935521L);
		node1 ^= rshft(node1, 19);

		break;
	case 3:
		node1 = xor_shft2_32(node1, 24, 8);
		node1 = xor_shft2_32(node1, 10, 22);
		node1 = mult_32(node1, 259019297824935521L);
		node1 ^= rshft(node1, 8);
		node1 ^= rshft(node1, 7);
		node1 ^= rshft(node1, 6);
		node1 = mult_32(node1, 262748614696183809L);
		node1 ^= rshft(node1, 19);
		break;
	case 4:
		node1 = xor_shft2_32(node1, 24, 8);
		node1 = xor_shft2_32(node1, 10, 22);
		node1 = mult_32(node1, 262748614696183809L);
		node1 ^= rshft(node1, 8);
		node1 ^= rshft(node1, 7);
		node1 ^= rshft(node1, 6);
		node1 = mult_32(node1, 265632916863469185L);
		node1 ^= rshft(node1, 19);
		break;
	case 5:
		node1 = xor_shft2_32(node1, 24, 8);
		node1 = xor_shft2_32(node1, 10, 22);
		node1 = mult_32(node1, 236110392309990593L);
		node1 ^= rshft(node1, 8);
		node1 ^= rshft(node1, 7);
		node1 ^= rshft(node1, 6);
		node1 = mult_32(node1, 246919711164770529L);
		node1 ^= rshft(node1, 19);
		break;
	case 6:
		node1 = xor_shft2_32(node1, 24, 8);
		node1 = xor_shft2_32(node1, 10, 22);
		node1 = mult_32(node1, 246919711164770529L);
		node1 ^= rshft(node1, 8);
		node1 ^= rshft(node1, 7);
		node1 ^= rshft(node1, 6);
		node1 = mult_32(node1, 254009204483154977L);
		node1 ^= rshft(node1, 19);
		break;
	case 7:
		node1 = xor_shft2_32(node1, 24, 8);
		node1 = xor_shft2_32(node1, 10, 22);
		node1 = mult_32(node1, 254009204483154977L);
		node1 ^= rshft(node1, 8);
		node1 ^= rshft(node1, 7);
		node1 ^= rshft(node1, 6);
		node1 = mult_32(node1, 259019297824935521L);
		node1 ^= rshft(node1, 19);
		break;
	case 8:
		node1 = xor_shft2_32(node1, 24, 8);
		node1 = xor_shft2_32(node1, 10, 22);
		node1 = mult_32(node1, 259019297824935521L);
		node1 ^= rshft(node1, 8);
		node1 ^= rshft(node1, 7);
		node1 ^= rshft(node1, 6);
		node1 = mult_32(node1, 262748614696183809L);
		node1 ^= rshft(node1, 19);
		break;
	case 9:
		node1 = xor_shft2_32(node1, 24, 8);
		node1 = xor_shft2_32(node1, 10, 22);
		node1 = mult_32(node1, 262748614696183809L);
		node1 ^= rshft(node1, 8);
		node1 ^= rshft(node1, 7);
		node1 ^= rshft(node1, 6);
		node1 = mult_32(node1, 265632916863469185L);
		node1 ^= rshft(node1, 19);
		break;
	default:
		return 0;
	}
	return node1;
}

// Inverse hash functions.
inline __host__ __device__ nodetype RHASH32_INVERSE(uint8_t id, nodetype node) {
	nodetype node1 = node;
	nodetype node2;
	switch (id) {
	case 0:
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 19));
		node1 = node2; node2 = (node1 ^ rshft(node2, 19));

		node1 = mult_32(node1, 280138861976656673L);
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node1 = node2;
		node1 = (node2 ^ rshft(node1, 7));
		node1 = (node2 ^ rshft(node1, 7));
		node1 = (node2 ^ rshft(node1, 7));
		node1 = (node2 ^ rshft(node1, 7));
		node1 = (node2 ^ rshft(node1, 7));
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 6));
		node2 = (node1 ^ rshft(node2, 6));
		node2 = (node1 ^ rshft(node2, 6));
		node2 = (node1 ^ rshft(node2, 6));
		node2 = (node1 ^ rshft(node2, 6));
		node2 = (node1 ^ rshft(node2, 6));
		node1 = node2;
		node1 = mult_32(node1, 103070857062009665L);
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 22));
		node2 = (node1 ^ rshft(node2, 22));
		node1 = node2;
		node1 = (node2 ^ lshft_32(node1, 10));
		node1 = (node2 ^ lshft_32(node1, 10));
		node1 = (node2 ^ lshft_32(node1, 10));
		node1 = (node2 ^ lshft_32(node1, 10));
		node1 &= 0xffffffff;
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node1 = node2;
		node1 = (node2 ^ lshft_32(node1, 24));
		node1 = (node2 ^ lshft_32(node1, 24));
		node1 &= 0xffffffff;
		break;
	case 1:
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 19));
		node1 = node2; node2 = (node1 ^ rshft(node2, 19));

		node1 = mult_32(node1, 226102497176100833L);
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node1 = node2;
		node1 = (node2 ^ rshft(node1, 7));
		node1 = (node2 ^ rshft(node1, 7));
		node1 = (node2 ^ rshft(node1, 7));
		node1 = (node2 ^ rshft(node1, 7));
		node1 = (node2 ^ rshft(node1, 7));
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 6));
		node2 = (node1 ^ rshft(node2, 6));
		node2 = (node1 ^ rshft(node2, 6));
		node2 = (node1 ^ rshft(node2, 6));
		node2 = (node1 ^ rshft(node2, 6));
		node2 = (node1 ^ rshft(node2, 6));
		node1 = node2;
		node1 = mult_32(node1, 280138861976656673L);
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 22));
		node2 = (node1 ^ rshft(node2, 22));
		node1 = node2;
		node1 = (node2 ^ lshft_32(node1, 10));
		node1 = (node2 ^ lshft_32(node1, 10));
		node1 = (node2 ^ lshft_32(node1, 10));
		node1 = (node2 ^ lshft_32(node1, 10));
		node1 &= 0xffffffff;
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node1 = node2;
		node1 = (node2 ^ lshft_32(node1, 24));
		node1 = (node2 ^ lshft_32(node1, 24));
		node1 &= 0xffffffff;
		break;
	case 2:
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 19));
		node1 = node2; node2 = (node1 ^ rshft(node2, 19));

		node1 = mult_32(node1, 179734826834040225L);
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node1 = node2;
		node1 = (node2 ^ rshft(node1, 7));
		node1 = (node2 ^ rshft(node1, 7));
		node1 = (node2 ^ rshft(node1, 7));
		node1 = (node2 ^ rshft(node1, 7));
		node1 = (node2 ^ rshft(node1, 7));
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 6));
		node2 = (node1 ^ rshft(node2, 6));
		node2 = (node1 ^ rshft(node2, 6));
		node2 = (node1 ^ rshft(node2, 6));
		node2 = (node1 ^ rshft(node2, 6));
		node2 = (node1 ^ rshft(node2, 6));
		node1 = node2;
		node1 = mult_32(node1, 226102497176100833L);
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 22));
		node2 = (node1 ^ rshft(node2, 22));
		node1 = node2;
		node1 = (node2 ^ lshft_32(node1, 10));
		node1 = (node2 ^ lshft_32(node1, 10));
		node1 = (node2 ^ lshft_32(node1, 10));
		node1 = (node2 ^ lshft_32(node1, 10));
		node1 &= 0xffffffff;
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node1 = node2;
		node1 = (node2 ^ lshft_32(node1, 24));
		node1 = (node2 ^ lshft_32(node1, 24));
		node1 &= 0xffffffff;

		break;
	case 3:
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 19));
		node1 = node2; node2 = (node1 ^ rshft(node2, 19));

		node1 = mult_32(node1, 254470409600030721L);
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node1 = node2;
		node1 = (node2 ^ rshft(node1, 7));
		node1 = (node2 ^ rshft(node1, 7));
		node1 = (node2 ^ rshft(node1, 7));
		node1 = (node2 ^ rshft(node1, 7));
		node1 = (node2 ^ rshft(node1, 7));
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 6));
		node2 = (node1 ^ rshft(node2, 6));
		node2 = (node1 ^ rshft(node2, 6));
		node2 = (node1 ^ rshft(node2, 6));
		node2 = (node1 ^ rshft(node2, 6));
		node2 = (node1 ^ rshft(node2, 6));
		node1 = node2;
		node1 = mult_32(node1, 179734826834040225L);
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 22));
		node2 = (node1 ^ rshft(node2, 22));
		node1 = node2;
		node1 = (node2 ^ lshft_32(node1, 10));
		node1 = (node2 ^ lshft_32(node1, 10));
		node1 = (node2 ^ lshft_32(node1, 10));
		node1 = (node2 ^ lshft_32(node1, 10));
		node1 &= 0xffffffff;
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node1 = node2;
		node1 = (node2 ^ lshft_32(node1, 24));
		node1 = (node2 ^ lshft_32(node1, 24));
		node1 &= 0xffffffff;
		break;
	case 4:
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 19));
		node1 = node2; node2 = (node1 ^ rshft(node2, 19));

		node1 = mult_32(node1, 253633487850830209L);
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node1 = node2;
		node1 = (node2 ^ rshft(node1, 7));
		node1 = (node2 ^ rshft(node1, 7));
		node1 = (node2 ^ rshft(node1, 7));
		node1 = (node2 ^ rshft(node1, 7));
		node1 = (node2 ^ rshft(node1, 7));
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 6));
		node2 = (node1 ^ rshft(node2, 6));
		node2 = (node1 ^ rshft(node2, 6));
		node2 = (node1 ^ rshft(node2, 6));
		node2 = (node1 ^ rshft(node2, 6));
		node2 = (node1 ^ rshft(node2, 6));
		node1 = node2;
		node1 = mult_32(node1, 254470409600030721L);
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 22));
		node2 = (node1 ^ rshft(node2, 22));
		node1 = node2;
		node1 = (node2 ^ lshft_32(node1, 10));
		node1 = (node2 ^ lshft_32(node1, 10));
		node1 = (node2 ^ lshft_32(node1, 10));
		node1 = (node2 ^ lshft_32(node1, 10));
		node1 &= 0xffffffff;
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node1 = node2;
		node1 = (node2 ^ lshft_32(node1, 24));
		node1 = (node2 ^ lshft_32(node1, 24));
		node1 &= 0xffffffff;
		break;
	case 5:
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 19));
		node1 = node2; node2 = (node1 ^ rshft(node2, 19));

		node1 = mult_32(node1, 280138861976656673L);
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node1 = node2;
		node1 = (node2 ^ rshft(node1, 7));
		node1 = (node2 ^ rshft(node1, 7));
		node1 = (node2 ^ rshft(node1, 7));
		node1 = (node2 ^ rshft(node1, 7));
		node1 = (node2 ^ rshft(node1, 7));
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 6));
		node2 = (node1 ^ rshft(node2, 6));
		node2 = (node1 ^ rshft(node2, 6));
		node2 = (node1 ^ rshft(node2, 6));
		node2 = (node1 ^ rshft(node2, 6));
		node2 = (node1 ^ rshft(node2, 6));
		node1 = node2;
		node1 = mult_32(node1, 103070857062009665L);
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 22));
		node2 = (node1 ^ rshft(node2, 22));
		node1 = node2;
		node1 = (node2 ^ lshft_32(node1, 10));
		node1 = (node2 ^ lshft_32(node1, 10));
		node1 = (node2 ^ lshft_32(node1, 10));
		node1 = (node2 ^ lshft_32(node1, 10));
		node1 &= 0xffffffff;
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node1 = node2;
		node1 = (node2 ^ lshft_32(node1, 24));
		node1 = (node2 ^ lshft_32(node1, 24));
		node1 &= 0xffffffff;
		break;
	case 6:
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 19));
		node1 = node2; node2 = (node1 ^ rshft(node2, 19));

		node1 = mult_32(node1, 226102497176100833L);
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node1 = node2;
		node1 = (node2 ^ rshft(node1, 7));
		node1 = (node2 ^ rshft(node1, 7));
		node1 = (node2 ^ rshft(node1, 7));
		node1 = (node2 ^ rshft(node1, 7));
		node1 = (node2 ^ rshft(node1, 7));
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 6));
		node2 = (node1 ^ rshft(node2, 6));
		node2 = (node1 ^ rshft(node2, 6));
		node2 = (node1 ^ rshft(node2, 6));
		node2 = (node1 ^ rshft(node2, 6));
		node2 = (node1 ^ rshft(node2, 6));
		node1 = node2;
		node1 = mult_32(node1, 280138861976656673L);
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 22));
		node2 = (node1 ^ rshft(node2, 22));
		node1 = node2;
		node1 = (node2 ^ lshft_32(node1, 10));
		node1 = (node2 ^ lshft_32(node1, 10));
		node1 = (node2 ^ lshft_32(node1, 10));
		node1 = (node2 ^ lshft_32(node1, 10));
		node1 &= 0xffffffff;
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node1 = node2;
		node1 = (node2 ^ lshft_32(node1, 24));
		node1 = (node2 ^ lshft_32(node1, 24));
		node1 &= 0xffffffff;
		break;
	case 7:
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 19));
		node1 = node2; node2 = (node1 ^ rshft(node2, 19));

		node1 = mult_32(node1, 179734826834040225L);
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node1 = node2;
		node1 = (node2 ^ rshft(node1, 7));
		node1 = (node2 ^ rshft(node1, 7));
		node1 = (node2 ^ rshft(node1, 7));
		node1 = (node2 ^ rshft(node1, 7));
		node1 = (node2 ^ rshft(node1, 7));
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 6));
		node2 = (node1 ^ rshft(node2, 6));
		node2 = (node1 ^ rshft(node2, 6));
		node2 = (node1 ^ rshft(node2, 6));
		node2 = (node1 ^ rshft(node2, 6));
		node2 = (node1 ^ rshft(node2, 6));
		node1 = node2;
		node1 = mult_32(node1, 226102497176100833L);
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 22));
		node2 = (node1 ^ rshft(node2, 22));
		node1 = node2;
		node1 = (node2 ^ lshft_32(node1, 10));
		node1 = (node2 ^ lshft_32(node1, 10));
		node1 = (node2 ^ lshft_32(node1, 10));
		node1 = (node2 ^ lshft_32(node1, 10));
		node1 &= 0xffffffff;
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node1 = node2;
		node1 = (node2 ^ lshft_32(node1, 24));
		node1 = (node2 ^ lshft_32(node1, 24));
		node1 &= 0xffffffff;
		break;
	case 8:
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 19));
		node1 = node2; node2 = (node1 ^ rshft(node2, 19));

		node1 = mult_32(node1, 254470409600030721L);
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node1 = node2;
		node1 = (node2 ^ rshft(node1, 7));
		node1 = (node2 ^ rshft(node1, 7));
		node1 = (node2 ^ rshft(node1, 7));
		node1 = (node2 ^ rshft(node1, 7));
		node1 = (node2 ^ rshft(node1, 7));
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 6));
		node2 = (node1 ^ rshft(node2, 6));
		node2 = (node1 ^ rshft(node2, 6));
		node2 = (node1 ^ rshft(node2, 6));
		node2 = (node1 ^ rshft(node2, 6));
		node2 = (node1 ^ rshft(node2, 6));
		node1 = node2;
		node1 = mult_32(node1, 179734826834040225L);
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 22));
		node2 = (node1 ^ rshft(node2, 22));
		node1 = node2;
		node1 = (node2 ^ lshft_32(node1, 10));
		node1 = (node2 ^ lshft_32(node1, 10));
		node1 = (node2 ^ lshft_32(node1, 10));
		node1 = (node2 ^ lshft_32(node1, 10));
		node1 &= 0xffffffff;
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node1 = node2;
		node1 = (node2 ^ lshft_32(node1, 24));
		node1 = (node2 ^ lshft_32(node1, 24));
		node1 &= 0xffffffff;
		break;
	case 9:
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 19));
		node1 = node2; node2 = (node1 ^ rshft(node2, 19));

		node1 = mult_32(node1, 253633487850830209L);
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node1 = node2;
		node1 = (node2 ^ rshft(node1, 7));
		node1 = (node2 ^ rshft(node1, 7));
		node1 = (node2 ^ rshft(node1, 7));
		node1 = (node2 ^ rshft(node1, 7));
		node1 = (node2 ^ rshft(node1, 7));
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 6));
		node2 = (node1 ^ rshft(node2, 6));
		node2 = (node1 ^ rshft(node2, 6));
		node2 = (node1 ^ rshft(node2, 6));
		node2 = (node1 ^ rshft(node2, 6));
		node2 = (node1 ^ rshft(node2, 6));
		node1 = node2;
		node1 = mult_32(node1, 254470409600030721L);
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 22));
		node2 = (node1 ^ rshft(node2, 22));
		node1 = node2;
		node1 = (node2 ^ lshft_32(node1, 10));
		node1 = (node2 ^ lshft_32(node1, 10));
		node1 = (node2 ^ lshft_32(node1, 10));
		node1 = (node2 ^ lshft_32(node1, 10));
		node1 &= 0xffffffff;
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node1 = node2;
		node1 = (node2 ^ lshft_32(node1, 24));
		node1 = (node2 ^ lshft_32(node1, 24));
		node1 &= 0xffffffff;
		break;
	default:
		node1 = 0;
	}
	return node1;
}



/**************************************************************************************************************************************************************************************************************************************
*
*
*
*
*  28 Bit
*
*
*
*
* ************************************************************************************************************************************************************************************************************************************/





// Bit left shift function for 58 bits.
inline __host__ __device__ uint64_cu lshft_28(const uint64_cu x, uint8_t i) {
	uint64_cu y = (x << i);
	return y & MASK(28);
}

// Multiplication modulo 2^58.
inline __host__ __device__ uint64_cu mult_28(const uint64_cu x, uint64_cu a) {
	return ((x * a) & MASK(28));
}

// XOR two times bit shift function for 58 bits.
inline __host__ __device__ uint64_cu xor_shft2_28(const uint64_cu x, uint8_t a, uint8_t b) {
	uint64_cu y = (x ^ lshft_28(x, a));
	y = (y ^ rshft(y, b));
	return y;
}




inline __host__ __device__ nodetype RHASH28(uint8_t id, nodetype node) {
	nodetype node1 = node;
	switch (id) {
	case 0:
		node1 = xor_shft2_28(node1, 24, 4);
		node1 = xor_shft2_28(node1, 10, 18);
		node1 = mult_28(node1, 236110392309990593L);
		node1 ^= rshft(node1, 8);
		node1 ^= rshft(node1, 7);
		node1 ^= rshft(node1, 6);
		node1 = mult_28(node1, 246919711164770529L);
		node1 ^= rshft(node1, 19);
		break;
	case 1:
		node1 = xor_shft2_28(node1, 24, 4);
		node1 = xor_shft2_28(node1, 10, 18);
		node1 = mult_28(node1, 246919711164770529L);
		node1 ^= rshft(node1, 8);
		node1 ^= rshft(node1, 7);
		node1 ^= rshft(node1, 6);
		node1 = mult_28(node1, 254009204483154977L);
		node1 ^= rshft(node1, 19);
		break;
	case 2:
		node1 = xor_shft2_28(node1, 24, 4);
		node1 = xor_shft2_28(node1, 10, 18);
		node1 = mult_28(node1, 254009204483154977L);
		node1 ^= rshft(node1, 8);
		node1 ^= rshft(node1, 7);
		node1 ^= rshft(node1, 6);
		node1 = mult_28(node1, 259019297824935521L);
		node1 ^= rshft(node1, 19);
		break;
	case 3:
		node1 = xor_shft2_28(node1, 24, 4);
		node1 = xor_shft2_28(node1, 10, 18);
		node1 = mult_28(node1, 259019297824935521L);
		node1 ^= rshft(node1, 8);
		node1 ^= rshft(node1, 7);
		node1 ^= rshft(node1, 6);
		node1 = mult_28(node1, 262748614696183809L);
		node1 ^= rshft(node1, 19);
		break;
	case 4:
		node1 = xor_shft2_28(node1, 24, 4);
		node1 = xor_shft2_28(node1, 10, 18);
		node1 = mult_28(node1, 262748614696183809L);
		node1 ^= rshft(node1, 8);
		node1 ^= rshft(node1, 7);
		node1 ^= rshft(node1, 6);
		node1 = mult_28(node1, 265632916863469185L);
		node1 ^= rshft(node1, 19);
		break;
	default:
		node1 = 0;

	};
	return node1;
}



inline __host__ __device__ nodetype RHASH28_INVERSE(uint8_t id, nodetype node) {
	nodetype node1 = node;
	nodetype node2;
	switch (id) {
	case 0:
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 19));
		node1 = node2; node2 = (node1 ^ rshft(node2, 19));

		node1 = mult_28(node1, 280138861976656673L);
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node1 = node2;
		node1 = (node2 ^ rshft(node1, 7));
		node1 = (node2 ^ rshft(node1, 7));
		node1 = (node2 ^ rshft(node1, 7));
		node1 = (node2 ^ rshft(node1, 7));
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 6));
		node2 = (node1 ^ rshft(node2, 6));
		node2 = (node1 ^ rshft(node2, 6));
		node2 = (node1 ^ rshft(node2, 6));
		node2 = (node1 ^ rshft(node2, 6));
		node1 = node2;
		node1 = mult_28(node1, 103070857062009665L);
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 18));
		node2 = (node1 ^ rshft(node2, 18));
		node1 = node2;
		node1 = (node2 ^ lshft_28(node1, 10));
		node1 = (node2 ^ lshft_28(node1, 10));
		node1 = (node2 ^ lshft_28(node1, 10));
		node1 &= 0xfffffff;
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 4));
		node2 = (node1 ^ rshft(node2, 4));
		node2 = (node1 ^ rshft(node2, 4));
		node2 = (node1 ^ rshft(node2, 4));
		node2 = (node1 ^ rshft(node2, 4));
		node2 = (node1 ^ rshft(node2, 4));
		node2 = (node1 ^ rshft(node2, 4));
		node1 = node2;
		node1 = (node2 ^ lshft_28(node1, 24));
		node1 = (node2 ^ lshft_28(node1, 24));
		node1 &= 0xfffffff;

		break;
	case 1:
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 19));
		node1 = node2; node2 = (node1 ^ rshft(node2, 19));

		node1 = mult_28(node1, 226102497176100833L);
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node1 = node2;
		node1 = (node2 ^ rshft(node1, 7));
		node1 = (node2 ^ rshft(node1, 7));
		node1 = (node2 ^ rshft(node1, 7));
		node1 = (node2 ^ rshft(node1, 7));
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 6));
		node2 = (node1 ^ rshft(node2, 6));
		node2 = (node1 ^ rshft(node2, 6));
		node2 = (node1 ^ rshft(node2, 6));
		node2 = (node1 ^ rshft(node2, 6));
		node1 = node2;
		node1 = mult_28(node1, 280138861976656673L);
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 18));
		node2 = (node1 ^ rshft(node2, 18));
		node1 = node2;
		node1 = (node2 ^ lshft_28(node1, 10));
		node1 = (node2 ^ lshft_28(node1, 10));
		node1 = (node2 ^ lshft_28(node1, 10));
		node1 &= 0xfffffff;
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 4));
		node2 = (node1 ^ rshft(node2, 4));
		node2 = (node1 ^ rshft(node2, 4));
		node2 = (node1 ^ rshft(node2, 4));
		node2 = (node1 ^ rshft(node2, 4));
		node2 = (node1 ^ rshft(node2, 4));
		node2 = (node1 ^ rshft(node2, 4));
		node1 = node2;
		node1 = (node2 ^ lshft_28(node1, 24));
		node1 = (node2 ^ lshft_28(node1, 24));
		node1 &= 0xfffffff;

		break;
	case 2:
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 19));
		node1 = node2; node2 = (node1 ^ rshft(node2, 19));

		node1 = mult_28(node1, 179734826834040225L);
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node1 = node2;
		node1 = (node2 ^ rshft(node1, 7));
		node1 = (node2 ^ rshft(node1, 7));
		node1 = (node2 ^ rshft(node1, 7));
		node1 = (node2 ^ rshft(node1, 7));
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 6));
		node2 = (node1 ^ rshft(node2, 6));
		node2 = (node1 ^ rshft(node2, 6));
		node2 = (node1 ^ rshft(node2, 6));
		node2 = (node1 ^ rshft(node2, 6));
		node1 = node2;
		node1 = mult_28(node1, 226102497176100833L);
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 18));
		node2 = (node1 ^ rshft(node2, 18));
		node1 = node2;
		node1 = (node2 ^ lshft_28(node1, 10));
		node1 = (node2 ^ lshft_28(node1, 10));
		node1 = (node2 ^ lshft_28(node1, 10));
		node1 &= 0xfffffff;
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 4));
		node2 = (node1 ^ rshft(node2, 4));
		node2 = (node1 ^ rshft(node2, 4));
		node2 = (node1 ^ rshft(node2, 4));
		node2 = (node1 ^ rshft(node2, 4));
		node2 = (node1 ^ rshft(node2, 4));
		node2 = (node1 ^ rshft(node2, 4));
		node1 = node2;
		node1 = (node2 ^ lshft_28(node1, 24));
		node1 = (node2 ^ lshft_28(node1, 24));
		node1 &= 0xfffffff;

		break;
	case 3:
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 19));
		node1 = node2; node2 = (node1 ^ rshft(node2, 19));

		node1 = mult_28(node1, 254470409600030721L);
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node1 = node2;
		node1 = (node2 ^ rshft(node1, 7));
		node1 = (node2 ^ rshft(node1, 7));
		node1 = (node2 ^ rshft(node1, 7));
		node1 = (node2 ^ rshft(node1, 7));
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 6));
		node2 = (node1 ^ rshft(node2, 6));
		node2 = (node1 ^ rshft(node2, 6));
		node2 = (node1 ^ rshft(node2, 6));
		node2 = (node1 ^ rshft(node2, 6));
		node1 = node2;
		node1 = mult_28(node1, 179734826834040225L);
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 18));
		node2 = (node1 ^ rshft(node2, 18));
		node1 = node2;
		node1 = (node2 ^ lshft_28(node1, 10));
		node1 = (node2 ^ lshft_28(node1, 10));
		node1 = (node2 ^ lshft_28(node1, 10));
		node1 &= 0xfffffff;
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 4));
		node2 = (node1 ^ rshft(node2, 4));
		node2 = (node1 ^ rshft(node2, 4));
		node2 = (node1 ^ rshft(node2, 4));
		node2 = (node1 ^ rshft(node2, 4));
		node2 = (node1 ^ rshft(node2, 4));
		node2 = (node1 ^ rshft(node2, 4));
		node1 = node2;
		node1 = (node2 ^ lshft_28(node1, 24));
		node1 = (node2 ^ lshft_28(node1, 24));
		node1 &= 0xfffffff;

		break;
	case 4:
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 19));
		node1 = node2; node2 = (node1 ^ rshft(node2, 19));

		node1 = mult_28(node1, 253633487850830209L);
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node2 = (node1 ^ rshft(node2, 8));
		node1 = node2;
		node1 = (node2 ^ rshft(node1, 7));
		node1 = (node2 ^ rshft(node1, 7));
		node1 = (node2 ^ rshft(node1, 7));
		node1 = (node2 ^ rshft(node1, 7));
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 6));
		node2 = (node1 ^ rshft(node2, 6));
		node2 = (node1 ^ rshft(node2, 6));
		node2 = (node1 ^ rshft(node2, 6));
		node2 = (node1 ^ rshft(node2, 6));
		node1 = node2;
		node1 = mult_28(node1, 254470409600030721L);
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 18));
		node2 = (node1 ^ rshft(node2, 18));
		node1 = node2;
		node1 = (node2 ^ lshft_28(node1, 10));
		node1 = (node2 ^ lshft_28(node1, 10));
		node1 = (node2 ^ lshft_28(node1, 10));
		node1 &= 0xfffffff;
		node2 = node1;
		node2 = (node1 ^ rshft(node2, 4));
		node2 = (node1 ^ rshft(node2, 4));
		node2 = (node1 ^ rshft(node2, 4));
		node2 = (node1 ^ rshft(node2, 4));
		node2 = (node1 ^ rshft(node2, 4));
		node2 = (node1 ^ rshft(node2, 4));
		node2 = (node1 ^ rshft(node2, 4));
		node1 = node2;
		node1 = (node2 ^ lshft_28(node1, 24));
		node1 = (node2 ^ lshft_28(node1, 24));
		node1 &= 0xfffffff;

		break;
	default:
		node1 = 0;

	};
	return node1;
}





inline __host__ __device__ nodetype RHASH(int SIZE, uint8_t id, nodetype node) {
	switch (SIZE) {
	case 64:
		return RHASH64(id, node);
	case 32:
		return RHASH32(id, node);
	case 28:
		return RHASH28(id, node);
	default:
		return RHASH50(id, node);
	}
}


inline __host__ __device__ nodetype RHASH_INVERSE(int SIZE, uint8_t id, nodetype node) {
	switch (SIZE) {
	case 64:
		return RHASH64_INVERSE(id, node);
	case 32:
		return RHASH32_INVERSE(id, node);
	case 28:
		return RHASH28_INVERSE(id, node);
	default:
		return RHASH50_INVERSE(id, node);
	}
}