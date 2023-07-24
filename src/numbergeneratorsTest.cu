#include <cmath>
#include <inttypes.h>

# define PRIl64		"llu"

#ifndef NUMGEN
#define NUMGEN
#include "numbergenerators.cu"
#endif

void numGenCollisionTest(int N, int H, int percentage, int depth) {
    int tablesize = (int)pow(2, N);

    int* hs = new int[H];
    for (int i = 0; i < H; i++) {
        hs[i] = i;
    }

	uint64_cu* list = generateCollisionSet(tablesize, N, H, hs, percentage, depth);

    printf("----------------------------------------------------------------\n");
    printf("|    i     |         val        |");
    for (int h = 0; h < H; h++) {
        printf("        Add%i    |", h);
    }
    printf("\n");
    
    printf("----------------------------------------------------------------\n");
    for (int i = 0; i < tablesize; i++) {
        printf("|%-10i|%-20" PRIl64 "|", i, list[i]);
        for (int h = 0; h < H; h++) {
            printf("%-16" PRIu32 "|", getAdd(RHASH(HFSIZE, h, list[i]), N));
        }
        printf("\n");
    }
    printf("------------------------------------------------------------\n");

    delete[] hs;
    delete[] list;
}

void numGenNormalTest(int N) {
    int tablesize = (int)pow(2, N);

    uint64_cu* list = generateNormalSet(tablesize);

    printf("----------------------------------------------------------------\n");
    printf("|    i     |         val        |\n");

    printf("----------------------------------------------------------------\n");
    for (int i = 0; i < tablesize; i++) {
        printf("|%-10i|%-20" PRIl64 "|", i, list[i]);
    }
    printf("------------------------------------------------------------\n");

    delete[] list;
}