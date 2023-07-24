#include <iostream>
#include <iomanip>
#include <stdlib.h>
#include <math.h>
#include <iterator>
#include <set>
#include <inttypes.h>
#include <atomic>
#include <random>

#include <cooperative_groups.h>
namespace cg = cooperative_groups;

//For to List
#include <vector>

#include <curand.h>
#include <curand_kernel.h>

#ifndef MAIN
#define MAIN
#include "main.h"
#endif

#ifndef HASHTABLE
#define HASHTABLE
#include "HashTable.h"
#endif

#ifndef HASHINCLUDED
#define HASHINCLUDED
#include "hashfunctions.cu"
#endif

const int MAXLOOPS = 1000;
const int NHASHFUNCTIONS = 4;

// GPU constants.
__constant__ int AS;
__constant__ bool is_compact;

// Get the number of inserted item
template <class Ttype>
GPUHEADER_G
void coopCount(Ttype *T, int tsize, int *nrelements) {
    uint64_cu index = blockIdx.x * blockDim.x + threadIdx.x;
    uint64_cu stride = blockDim.x * gridDim.x;

    int counter = 0;
    for (uint64_cu i = index; i < tsize; i += stride) {
        if (T[i] != 0) {
            counter++;
        }
    }
    atomicAdd(nrelements, counter);
}

class Managed {
public:
  void *operator new(size_t len) {
    void *ptr;
    cudaMallocManaged(&ptr, len);
    cudaDeviceSynchronize();
    return ptr;
  }

  void operator delete(void *ptr) {
    cudaDeviceSynchronize();
    cudaFree(ptr);
  }
};

// Assumption: AS (Number of bits of address space) and
// is_compact (do we use Cleary compression?) are constants
// stored in constant memory.
template <class Ttype, int tile_sz>
class HashTableGeneric {

    private:
        // Hash table array
        Ttype* T;
        int tsize;
        int nrelements = 0;

        //Flags
#ifdef GPUCODE
        int failFlag = 0;
        int occupation = 0;
        int rehashFlag = 0;
#else
        std::atomic<int> failFlag;
        std::atomic<int> occupation;
        std::atomic<int> rehashFlag;
#endif
        //Method to select next hash to use in insertion
        GPUHEADER
        int getNextHash(int curr) {
            if (curr+1 < NHASHFUNCTIONS) {
                return curr+1;
            }
            return 0;
        }

        /* Method to prepare an element for storage */
        GPUHEADER_D
        Ttype prepare_for_storage(keytype k, int hash) {
            keytype x = k;
            keytype hash_tmp = hash;
            // Set occupation bit
            x = x | 0x8000000000000000;
            // Set hash id
            x = x | (hash_tmp << 61);
            return (Ttype) x;
        }

        /* Method to retrieve an element from storage */
        GPUHEADER_D
        keytype retrieve_from_storage(Ttype p) {
            keytype x = (keytype) p;
            // Filter bookkeeping bits
            x = x & 0x1FFFFFFFFFFFFFFF;
            return x;
        }

        /* Method to retrieve a hash id from storage */
        GPUHEADER_D
        hashtype retrieve_hash_from_storage(Ttype p) {
            hashtype hash = (hashtype) p;
            hash = (hash >> 61) & 0x3;
            return hash;
        }

        /* Method to prepare an element for storage, with compression */
        GPUHEADER_D
        Ttype prepare_for_storage_compressed(hashtype hashed_k, int hash) {
            Ttype rem = (Ttype) (hashed_k >> AS);
            // Set occupation bit
            rem = rem | 0x80000000;
            // Set hash id
            rem = rem | (hash << 29);
            return rem;
        }

        /* Method to retrieve an element from storage, with compression */
        GPUHEADER_D
        keytype retrieve_from_storage_compressed(Ttype p, addtype add) {
            Ttype x = p;
            // retrieve hash id
            int hash = (x >> 29) & 0x3;
            // reform key
            keytype y = (keytype) (x & 0x1FFFFFFF);
            y = (y << AS) | add;
            // inverse hashing
            return RHASH_INVERSE(50, hash, y);
        }

        /* Method to retrieve a hash id from storage, with compression */
        GPUHEADER_D
        hashtype retrieve_hash_from_storage_compressed(Ttype p) {
            hashtype hash = (p >> 29) & 0x3;
            return hash;
        }

        /**
         * Internal Insertion Loop
         **/
        GPUHEADER_D
        result insertIntoTable(keytype k, cg::thread_block_tile<tile_sz> tile) {
            keytype x = k;
            int hash = 0;
            int thread_rank = tile.thread_rank();

            //If the key is already inserted don't do anything
            if (this->lookup(k, tile)) {
                return FOUND;
            }

            //Start the iteration
            int c = 0;
            bool success = false;
            bool prepare = true;

            hashtype hashed1;
            addtype add;
            Ttype p, old;
            while (!success) {
                //Get the add and storage element of k
                if (prepare) {
                    hashed1 = RHASH(50, hash, x);
                    add = getAdd(hashed1, AS);
                    if (is_compact) {
                        p = prepare_for_storage_compressed(hashed1, hash);
                        x = retrieve_from_storage_compressed(p, add);
                    }
                    else {
                        p = prepare_for_storage(x, hash);
                    }
                }

                // Compute load of bucket
                auto load_bitmap = tile.ballot(T[(add*tile_sz)+thread_rank] != 0);
                auto load = __popc(load_bitmap);

                //printf("%i: \t\t\tLoad at %" PRIu32 " : %i\n", getThreadID(), add, load);
                addtype bAdd;

                if (load == tile_sz) {
                    if (c == MAXLOOPS) {
                        return FAILED;
                    }
                    bAdd = (addtype) (RHASH(50, 0, x) % tile_sz); //select some location within the table
                    // Store p
                    if (thread_rank == bAdd) {
                        old = atomicExch(&(T[(add*tile_sz)+thread_rank]), p);
                    }
                    old = tile.shfl(old, bAdd);

                    if (p == old) {
                        return FOUND;
                    }
                    if (is_compact) {
                        x = retrieve_from_storage_compressed(old, add);
                        hash = retrieve_hash_from_storage_compressed(old);
                    }
                    else {
                        x = retrieve_from_storage(old);
                        hash = retrieve_hash_from_storage(old);
                    }
                    //Hash with the next hash value
                    hash = getNextHash(hash);
                    c++;
                    prepare = true;
                }
                else {
                    bAdd = load;
                    // Store p
                    if (thread_rank == bAdd) {
                        old = atomicCAS(&(T[(add*tile_sz)+thread_rank]), 0, p);
                    }
                    old = tile.shfl(old, bAdd);
                    success = (old == 0);
                    prepare = false;
                }
            }
            return INSERTED;
        };

        // //Method to check for duplicates after insertions
        // GPUHEADER_D
        // void removeDuplicates(keytype k, cg::thread_block_tile<tile_sz> tile) {
        //     //To store whether value was already encountered
        //     bool found = false;

        //     //Iterate over Hash Functions
        //     for (int i = 0; i < NRHASHFUNCTIONS; i++) {
        //         uint64_cu hashed1 = RHASH(HFSIZE_BUCKET, i, k);
        //         addtype add = getAdd(hashed1, AS);
        //         Ttype p;
        //         if (is_compressed) {
        //             p = prepare_for_storage_compressed(hashed1, i);
        //         }
        //         else {
        //             p = prepare_for_storage(x, i);
        //         }

        //         //Check if val in loc is key
        //         bool key_exists = this.find(p, add);

        //         int realAdd = -1;
        //         //If first group where val is encountered, keep the first entry
        //         int num_vals = __popc(tile_.ballot(key_exists));
        //         int first = __ffs(tile_.ballot(key_exists)) - 1;
        //         //printf("NumVals:%i First:%i\n", num_vals, first);

        //         if ( (num_vals > 0) && !(*found) ) {
        //             //Mark as found for next iteration
        //             (*found) = true;
        //             realAdd = first;
        //             //printf("%i:\tRealAdd %i\n", getThreadID(), realAdd);
        //         }

        //         //If duplicate, mark as empty
        //         if ( key_exists && (tile_.thread_rank() != realAdd) ) {
        //             //printf("%i:\t\tDeleting\n", getThreadID());
        //             ptr_[tIndex].setO(false);
        //         }
                
        //     }
        //     //printf("%i: \t\tDups Removed\n", getThreadID());
        // }

        //Lookup internal method
        GPUHEADER_D
        bool lookup(keytype k, cg::thread_block_tile<tile_sz> tile){
            int thread_rank = tile.thread_rank();
            //Iterate over hash functions
            for (int i = 0; i < NHASHFUNCTIONS; i++) {
                uint64_cu hashed1 = RHASH(50, i, k);
                addtype add = getAdd(hashed1, AS);
                Ttype p;
                if (is_compact) {
                    p = prepare_for_storage_compressed(hashed1, i);
                }
                else {
                    p = prepare_for_storage(k, i);
                }

                //printf("%i: Searching for %" PRIu64 " at %" PRIu32 "\n", getThreadID(), k, add);
                //Get Bucket and Find
                Ttype old = T[(add*tile_sz)+thread_rank];
                int found = tile.ballot(p == old);
                if (found != 0) {
                    return true;
                }
                // Compute load of bucket
                auto load_bitmap = tile.ballot(T[(add*tile_sz)+thread_rank] != 0);
                auto load = __popc(load_bitmap);
                if (load < tile_sz) {
                    return false;
                }
            }
            return false;
        }

        // GPUHEADER
        // void print(ClearyCuckooEntry<addtype, remtype>* T) {
        //     printf("----------------------------------------------------------------\n");
        //     printf("|    i     |     R[i]       | O[i] |        key         |label |\n");
        //     printf("----------------------------------------------------------------\n");
        //     printf("Tablesize %i\n", tablesize);

        //     for (int i = 0; i < B; i++) {
        //         printf("----------------------------------------------------------------\n");
        //         printf("|                   Bucket %i                                   \n", i);
        //         printf("----------------------------------------------------------------\n");
        //         for (int j = 0; j < Bs; j++) {
        //             keytype k = T[i*Bs + j].getR();
        //             int label = T[i*Bs + j].getH();

        //             printf("|%-10i|%-16" PRIl64 "|%-6i|%-20" PRIl64 "|%-6i|\n", j, T[i*Bs + j].getR(), T[i*Bs + j].getO(), k, T[i*Bs + j].getH());
        //         }
        //     }

        //     printf("------------------------------------------------------------\n");
        // }


    public:
        /**
         * Constructor
         */
        HashTableGeneric(int tableSize) {
            tsize = ((tableSize + tile_sz - 1) / tile_sz) * tile_sz;
#ifdef GPUCODE
            gpuErrchk(cudaMallocManaged(&T, tsize * sizeof(Ttype)));
#else
            T = new Ttype[tsize * tile_sz];
#endif
            for(int i = 0; i < tsize; i++){
                T[i] = 0;
            }
        }

        /**
         * Destructor
         */
        ~HashTableGeneric() {
            //printf("Destructor\n");
            #ifdef GPUCODE
            gpuErrchk(cudaFree(T));
            #else
            delete[] T;
            #endif
        }

        void deleteT() {
            #ifdef GPUCODE
            gpuErrchk(cudaFree(T));
            #endif
        }

        //Taken from Better GPU Hash Tables
        GPUHEADER_D
        result coopInsert(bool to_insert, keytype k) {
            cg::thread_block thb = cg::this_thread_block();
            auto tile = cg::tiled_partition<tile_sz>(thb);
            auto thread_rank = tile.thread_rank();
            result success = FAILED;

            //Perform the insertions
            uint32_t work_queue;
            while (work_queue = tile.ballot(to_insert)) {

                auto cur_lane = __ffs(work_queue) - 1;
                auto cur_k = tile.shfl(k, cur_lane);
                //printf("%i: \tThread Starting Insertion of %" PRIu64 "\n", getThreadID(), cur_k);
                auto cur_result = insertIntoTable(cur_k, tile);
                if (thread_rank == cur_lane) {
                    to_insert = false;
                    success = cur_result;
                }
                //printf("%i: \tInsertion Done\n", getThreadID());
            }
            //printf("%i: \tInsertion of  %" PRIu64" result:%i\n", getThreadID(), k, success);
            return success;
        }

        //Public insertion call
        GPUHEADER_D
#ifdef GPUCODE
            result insert(keytype k, bool to_check = true) {
#else
            result insert(uint64_cu k) {
#endif

            return coopInsert(to_check, k);
        };

        // //Public Lookup call
        // GPUHEADER_D
        // bool coopLookup(bool to_lookup, keytype k){
        //     //printf("%i: Coop Lookup\n", getThreadID());
        //     //Iterate over hash functions and check if found
        //     cg::thread_block thb = cg::this_thread_block();
        //     cg::thread_block_tile<tile_sz> tile = cg::tiled_partition<tile_sz>(thb);
        //     auto thread_rank = tile.thread_rank();
        //     bool success = true;
        //     //Perform the lookups

        //     uint32_t work_queue;
        //     while (work_queue = tile.ballot(to_lookup)) {
        //         auto cur_lane = __ffs(work_queue) - 1;
        //         auto cur_k = tile.shfl(k, cur_lane);
        //         auto cur_result = lookup(cur_k, tile);

        //         if (tile.thread_rank() == cur_lane) {
        //             to_lookup = false;
        //             success = cur_result;
        //         }
        //     }
        //     //printf("%i: key:%" PRIu64 " result:%i\n", getThreadID(), k, success);
        //     return success;
        //     //printf("\t\t Lookup Failed\n");
        // };

        //Clear all Table Entries
        GPUHEADER_D
        void clear(){
            int index = blockIdx.x * blockDim.x + threadIdx.x;
            int stride = blockDim.x * gridDim.x;

            for (int i = index; i < tsize; i += stride) {
                T[i] = 0;
            }
        }

        //Get the size of the Table
        GPUHEADER
        int getSize(){
            return tsize;
        }

        // Count the number of elements.
        int count() {
            nrelements = 0;
            #ifdef GPUCODE
            gpuErrchk(cudaDeviceSynchronize());
            coopCount<Ttype> <<< tsize / 512 / 5, 512 >>> (T, tsize, &nrelements);
            gpuErrchk(cudaDeviceSynchronize());
            #else
            for (int i = 0; i < tsize; i++) {
                if (T[i] != 0) {
                    nrelements++;
            }
            #endif
            return nrelements;
        }
};

//Method to fill table
template <class Ttype, int tile_sz>
GPUHEADER_G
#ifdef GPUCODE
void fill(int N, uint64_cu* vals, HashTableGeneric<Ttype, tile_sz>* table, int* failFlag=nullptr, addtype begin = 0, int* count = nullptr, int id = 0, int s = 1)
#else
void fill(int N, uint64_cu* vals, int* failFlag = nullptr, addtype begin = 0, int id = 0, int s = 1)
#endif
{
#ifdef GPUCODE
    int index = blockIdx.x * blockDim.x + threadIdx.x;
    int stride = blockDim.x * gridDim.x;
#else
    int index = id;
    int stride = s;
#endif

    int max = ((N + (tile_sz - 1)) / tile_sz) * tile_sz;
    int localCounter = 0;

    //printf("Thread %i Starting - max %i\n", getThreadID(), max);
    for (int i = index + begin; i < max; i += stride) {

        bool realVal = false;
        keytype ins = 0;
        if(i < N){
            realVal = true;
            ins = vals[i];
        }

        //printf("%i: Inserting: %" PRIu64 "\n", getThreadID(), ins);
        result res = table->insert(ins, realVal);
        if (res == INSERTED) {
            localCounter++;
        }
        if (res == FAILED) {
            if (failFlag != nullptr && realVal) {
                (*failFlag) = true;
            }
        }
        
    }

    // if (count != nullptr) {
    //     //printf("Adding Count\n");
    //     atomicAdd(count, localCounter);
    // }

    //printf("Done\n");
}


#ifdef GPUCODE
//Method to fill table with a failCheck on every insertion
template <class Ttype, int tile_sz>
GPUHEADER_G
void fill(int N, uint64_cu* vals, HashTableGeneric<Ttype, tile_sz>* table, addtype* occupancy, int* failFlag, int id = 0, int s = 1)
{
    int index = blockIdx.x * blockDim.x + threadIdx.x;
    int stride = blockDim.x * gridDim.x;


    int max = ((N + (tile_sz - 1)) / tile_sz) * tile_sz;

    for (int i = index; i < max; i += stride) {
        // if (failFlag[0]) {
        //     break;
        // }

        bool realVal = false;
        keytype ins = 0;
        if (i < N) {
            realVal = true;
            ins = vals[i];
        }

        table->insert(ins, realVal);
        // if (H->insert(ins, realVal) == FAILED) {
        //     if (realVal) {
        //         atomicCAS(&(failFlag[0]), 0, 1);
        //     }
        // }
        // atomicAdd(&occupancy[0], 1);
    }
}
#endif

// //Method to check whether a ClearyCuckooBucketed table contains a set of values
// template <int tile_sz>
// GPUHEADER_G
// void checkCuckooBucketed(int N, uint64_cu* vals, CuckooBucketed<tile_sz>* H, bool* res, int id = 0, int s = 1)
// {
// #ifdef GPUCODE
//     int index = blockIdx.x * blockDim.x + threadIdx.x;
//     int stride = blockDim.x * gridDim.x;
// #else
//     int index = id;
//     int stride = s;
// #endif

//     int max = calcBlockSize(N, H->getBucketSize());

//     for (int i = index; i < max; i += stride) {
//         bool realVal = false;
//         keytype look = 0;
//         if (i < N) {
//             realVal = true;
//             look = vals[i];
//         }

//         if (!(H->coopLookup(realVal, look))) {
//             res[0] = false;
//         }
//     }
// }

// //Method to do lookups in a ClearyCuckooBucketed table on an array of values
// template <int tile_sz>
// GPUHEADER_G
// void lookupCuckooBucketed(int N, int start, int end, uint64_cu* vals, CuckooBucketed<tile_sz>* H, int id = 0, int s = 1) {
// #ifdef GPUCODE
//     int index = blockIdx.x * blockDim.x + threadIdx.x;
//     int stride = blockDim.x * gridDim.x;
// #else
//     int index = id;
//     int stride = s;
// #endif

//     int max = calcBlockSize(N, H->getBucketSize());

//     for (int i = index; i < max; i += stride) {
//         bool realVal = false;
//         keytype look = 0;
//         if (i < N) {
//             realVal = true;
//             look = vals[(i + start) % end];
//         }
//         H->coopLookup(realVal, look);
//     }
// }

// //Method to fill ClearyCuckoo table
// template <int tile_sz>
// GPUHEADER_G
// void dupCheckCuckooBucketed(int N, uint64_cu* vals, CuckooBucketed<tile_sz>* H, addtype begin = 0)
// {
//     int index = blockIdx.x * blockDim.x + threadIdx.x;
//     int stride = blockDim.x * gridDim.x;

//     int max = calcBlockSize(N, H->getBucketSize());

//     //printf("Thread %i Starting\n", getThreadID());
//     for (int i = index + begin; i < max + begin; i += stride) {
//         //printf("Check iteration %i\n", i);
//         bool realVal = false;
//         keytype k = 0;
//         if (i < N + begin) {
//             realVal = true;
//             k = vals[i];
//         }
//         //printf("Checking %" PRIu64 "\n", k);
//         H->coopDupCheck(realVal, k);
//     }
//     //printf("Insertions %i Over\n", getThreadID());
