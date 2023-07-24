#include <stdio.h>
#include <thread>
#include <sstream>
#include <assert.h>

/***
*
* TYPES
*
*/

typedef long long int int64_cu;
typedef unsigned long long int uint64_cu;

using addtype = uint32_t;
using remtype = uint64_cu;
using hashtype = uint64_cu;
using keytype = uint64_cu;
const int ENTRYSIZE = 64;

const int DATASIZENEW = 50;
const int DATASIZE = 58;
const int DATASIZE_BUCKET = 28;
const int COMPACT_HASH_POSITION_SIZE = 32;
const int HASH_POSITION_SIZE = 64;
const int COMPACT_BUCKETSIZE = 1024/COMPACT_HASH_POSITION_SIZE;
const int BUCKETSIZE = 1024/HASH_POSITION_SIZE;


//HASH FUNCTION SIZE
const int HFSIZE = 64;
const int HFSIZE_BUCKET = 28;

/**
*
* Define this var to switch between GPU and CPU execution
*
**/

#define GPUCODE
//#define REHASH
#define DUPCHECK

/**
* 
* 
*  DEFINE variables
* 
* */

const int TILESIZE_CBUC = 4;
const int TILESIZE = 4;

enum result {
    INSERTED,
    FAILED,
    FOUND
};

/**
*
* GPU Headers
*
*/


#ifdef GPUCODE
#define GPUHEADER __host__ __device__
#define GPUHEADER_G __global__
#define GPUHEADER_D __device__
#define GPUHEADER_H __host__
#else
#define GPUHEADER
#define GPUHEADER_G
#define GPUHEADER_D
#define GPUHEADER_H
#endif

/**
*
* GPU Debug Methods
*
*/

#ifndef GPUASSERT
#define GPUASSERT
#define gpuErrchk(ans) { gpuAssert((ans), __FILE__, __LINE__); }
GPUHEADER
inline void gpuAssert(cudaError_t code, const char *file, int line, bool abort=true)
{
   if (code != cudaSuccess)
   {
      printf("GPUassert: %s %s %d\n", cudaGetErrorString(code), file, line);
      //if (abort) exit(code);
   }
}
#endif

#ifndef GETID
#define GETID
GPUHEADER_D
inline int getThreadID()
{
#ifdef GPUCODE
    return threadIdx.x;
#else
    std::stringstream ss;
    ss << std::this_thread::get_id();
    uint64_t id = std::stoull(ss.str());
    return id;
#endif
}
#endif


/**
*
* OTHER HELPER METHODS
*
*/

GPUHEADER
addtype getAdd(keytype key, int AS) {
    hashtype mask = ((hashtype)1 << AS) - 1;
    addtype add = key & mask;
    return add;
}

GPUHEADER
remtype getRem(keytype key, int AS) {
    remtype rem = key >> AS;
    return rem;
}

GPUHEADER
uint64_cu reformKey(addtype add, remtype rem, int AS) {
    rem = rem << AS;
    rem += add;
    return rem;
}

GPUHEADER
void boundaryAssert(int i, addtype min, addtype max) {
    assert(min <= i && i <= max);
}

GPUHEADER_D
int calcBlockSize(int N, int Bs) {
    return max(Bs, Bs * ((int)ceilf(N / Bs)));
}