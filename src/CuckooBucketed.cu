#include <iostream>
#include <iomanip>
#include <stdlib.h>
#include <math.h>
#include <iterator>
#include <set>
#include <inttypes.h>
#include <atomic>
#include <random>
#include "SpinBarrier.h"

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

#ifndef SHAREDQUEUE
#define SHAREDQUEUE
#include "SharedQueue.cu"
#endif


//Taken from Better GPUs
template <int tile_sz>
struct CuckooBucket {
    // Constructor to load the key-value pair of the bucket 2
    GPUHEADER
    CuckooBucket(ClearyCuckooEntry<addtype, remtype>* ptr, cg::thread_block_tile<tile_sz> tile, int bucketIndex, int bucketSize) : ptr_(ptr), tile_(tile) {
        tIndex = bucketIndex * tile_sz + tile_.thread_rank();
        lane_pair_ = ptr[tIndex];
    }

    // Compute the load of the bucket
    GPUHEADER
    int compute_load() {
        auto load_bitmap = tile_.ballot((ptr_[tIndex].getO()));
        //printf("\t\t\t\tLoadBitmap: %i\n", load_bitmap);
        return __popc(load_bitmap);
    }

    // Find the value associated with a key
    GPUHEADER_D
    bool find(const keytype k, const int hID) {
        //TODO
        //printf("%i: i:%i O(i):%i\n", getThreadID(), tIndex, ptr_[tIndex].getO());
        bool key_exist = ( (k == ptr_[tIndex].getR()) && (ptr_[tIndex].getO()) && (ptr_[tIndex].getH() == hID) );
        //printf("%i:\tKey_exist %i\n", getThreadID(), key_exist);
        int key_lane = __ffs(tile_.ballot(key_exist));
        if (key_lane == 0) return false;
        return tile_.shfl(true, key_lane - 1);
    }

    // Find the value associated with a key
    GPUHEADER_D
    void removeDuplicates(const keytype k, const int hID, bool* found) {
        //Check if val in loc is key
        bool key_exists = ((k == ptr_[tIndex].getR()) && (ptr_[tIndex].getO()) && (ptr_[tIndex].getH() == hID));
        //printf("%i:\tKey_exist at %i %i (%" PRIu64 " == %" PRIu64 ") %i (%i == %i))\n", getThreadID(), tIndex, key_exists, ptr_[tIndex].getR(), k, ptr_[tIndex].getO(), ptr_[tIndex].getH(), hID);
        //printf("%i: i:%i O(i):%i R(i):%" PRIu64 "\n", getThreadID(), tIndex, ptr_[tIndex].getO(), ptr_[tIndex].getR());
        if (key_exists) {
            //printf("%i: Searching For %" PRIu64 " and Found at %i found:%i\n", getThreadID(), k, tIndex, (*found));
        }

        int realAdd = -1;
        //If first group where val is encountered, keep the first entry
        int num_vals = __popc(tile_.ballot(key_exists));
        int first = __ffs(tile_.ballot(key_exists)) - 1;
        //printf("NumVals:%i First:%i\n", num_vals, first);

        if ( (num_vals > 0) && !(*found) ) {
            //Mark as found for next iteration
            (*found) = true;
            realAdd = first;
            //printf("%i:\tRealAdd %i\n", getThreadID(), realAdd);
        }

        //If duplicate, mark as empty
        if ( key_exists && (tile_.thread_rank() != realAdd) ) {
            //printf("%i:\t\tDeleting\n", getThreadID());
            ptr_[tIndex].setO(false);
        }
        

        return;
    }

    // Perform an exchange operation
    GPUHEADER_D
    ClearyCuckooEntry<addtype, remtype> exch_at_location(ClearyCuckooEntry<addtype, remtype> pair, const int loc) {
        ClearyCuckooEntry<addtype, remtype> old_pair;
        //printf("%i: \t\t\t\tExch in bucket: thread_rank %i loc:%i tIndex:%i\n", getThreadID(), tile_.thread_rank(), loc, tIndex);
        if (tile_.thread_rank() == loc) {
            //printf("%i: \t\t\t\tActual Exch %" PRIu64 "\n", getThreadID(), pair.getR());
            ptr_[tIndex].exchValue(&pair);
            //printf("%i: \t\t\t\tAfter Exch %" PRIu64 "\n", getThreadID(), pair.getR());
        }
        //printf("%i: \t\t\t\t Exch Done\n", getThreadID());
        return tile_.shfl(pair, loc);
    }

    private:
        ClearyCuckooEntry<addtype, remtype>* ptr_;
        ClearyCuckooEntry<addtype, remtype> lane_pair_;
        const cg::thread_block_tile<tile_sz>  tile_;
        int tIndex = 0;
};

template <int tile_sz>
class CuckooBucketed: HashTable{

/*
*
*  Global Variables
*
*/
    private:
        //Constant Vars
        const static int HS = 59;       //HashSize
        int MAXLOOPS = 100;
        int MAXREHASHES = 30;

        //Vars at Construction
        const int RS;                         //RemainderSize
        const int AS;                         //AdressSize
        const int B;                          //NumBuckets
        const int Bs = tile_sz;               //BucketSize

        int tablesize;
        int occupancy = 0;

        //Hash tables
        ClearyCuckooEntry<addtype, remtype>* T;

        int hashcounter = 0;

        //Hash function ID
        int hn;
        int* hashlist;

        //Bucket Variables
        int* bucketIndex;

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
        SharedQueue<keytype>* rehashQueue;

        //Method to init the hashlsit
        GPUHEADER
        void createHashList(int* list) {
            for (int i = 0; i < hn; i++) {
                list[i] = i;
            }
            return;
        }

        //Method to iterate over hashes (Rehashing)
        GPUHEADER
        void iterateHashList(int* list) {
            ////printf("\tUpdating Hashlist\n");
            for (int i = 0; i < hn; i++) {
                list[i] = (list[i]+1+i)%32;
            }
            return;
        }

        //Method to select next hash to use in insertion
        GPUHEADER
        int getNextHash(int* ls, int curr) {
            for (int i = 0; i < hn; i++) {
                if (ls[i] == curr) {
                    if (i + 1 != hn) {
                        return ls[i + 1];
                    }
                    else {
                        return ls[0];
                    }
                }
            }

            //Default return 0 if hash can't be found
            return ls[0];
        }

        //Checks if hash ID is contained in hashlist
        GPUHEADER
        bool containsHash(int* ls, int query) {
            for (int i = 0; i < hn; i++) {
                if (ls[i] == query) {
                    return true;
                }
            }
            return false;
        }

#ifdef GPUCODE
        //Method to set Flags on GPU(Failure/Rehash)
        GPUHEADER_D
        bool setFlag(int* loc, int val, bool strict=true) {
            int val_i = val == 0 ? 1 : 0;

            //In devices, atomically exchange
            uint64_cu res = atomicCAS(loc, val_i, val);
            //Make sure the value hasn't changed in the meantime
            if ( (res != val_i) && strict) {
                return false;
            }
            __threadfence();
            return true;
        }

#else
        GPUHEADER
        //Method to set Flags on CPU (Failure/Rehash)
        bool setFlag(std::atomic<int>* loc, int val, bool strict=true) {
            int val_i = val == 0 ? 1 : 0;
                ////printf("%i:\t:Attempting CAS\n", getThreadID());
            if (std::atomic_compare_exchange_strong(loc, &val_i, val)) {
                ////printf("%i:\t:Flag Set\n", getThreadID());
                return true;
            }else{
              return false;
            }
        }
#endif


        /**
         * Internal Insertion Loop
         **/
        GPUHEADER_D
            result insertIntoTable(keytype k, ClearyCuckooEntry<addtype, remtype>* T, int* hs, cg::thread_block_tile<tile_sz> tile, int depth=0){
            // if (tile.thread_rank() == 0) {
            //     //printf("%i: \t\tInsert into Table %" PRIu64 "\n", getThreadID(), k);
            // }
            keytype x = k;
            int hash = hs[0];

            //If the key is already inserted don't do anything
            //printf("%i: \t\t\tLookup\n", getThreadID());
            if (lookup(k, T, tile)) {
                return FOUND;
            }

            //Start the iteration
            int c = 0;

            // if (tile.thread_rank() == 0) {
            //     //printf("%i: \t\t\tEntering Loop %i\n", getThreadID(), MAXLOOPS);
            // }
            bool is_full = false;

            while (c < MAXLOOPS) {
                //Get the add/rem of k
                hashtype hashed1 = RHASH(HFSIZE_BUCKET, hash, x);
                addtype add = getAdd(hashed1, AS);

                auto cur_bucket = CuckooBucket<tile_sz>(T, tile, add, Bs);
                //printf("size bucket: %lu\n", sizeof(cur_bucket)*tile_sz);
                auto load = cur_bucket.compute_load();

                //printf("%i: \t\t\tLoad at %" PRIu32 " : %i\n", getThreadID(), add, load);

                addtype bAdd;

                ClearyCuckooEntry<addtype, remtype> entry(x, hash, true, false);

                if (load == Bs) {
                    bAdd = (addtype) (RHASH(HFSIZE_BUCKET, 0, x) % Bs); //select some location within the table
                    //printf("%i: \t\t\tRandom Add at %" PRIu32 "\n", getThreadID(), bAdd);
                    is_full = true;
                }
                else {
                    bAdd = load;
                    is_full = false;
                }

                if (tile.thread_rank() == 0) {
                    //printf("%i: \t\t\tadd:%" PRIu32 " bAdd:%i\n", getThreadID(), add, bAdd);
                }

                entry = cur_bucket.exch_at_location(entry, bAdd);


                //Store the old value
                remtype temp = entry.getR();
                bool wasoccupied = entry.getO();
                int oldhash = entry.getH();

                //printf("%i: \t\t\told: rem:%" PRIu64 " Occ:%i hash:%i \n", getThreadID(), temp, wasoccupied, oldhash);

                //If the old val was empty return
                if (!wasoccupied) {
                    //printf("%i: \t\tInsert Success\n", getThreadID());
                    return INSERTED;
                    
                }

                //Otherwise rebuild the original key, unless the bucket was originally full. In that case, replace the evicted element in the current bucket.
                if (is_full) {
                    if (x == temp) {
                        return FOUND;
                    }
                    x = temp;

                    //printf("%i: \t\t\tRebuilt key:%" PRIu64 "\n", getThreadID(), x);


                    //Hash with the next hash value
                    hash = getNextHash(hs, oldhash);

                    c++;
                }
            }
            //printf("%i: \t\tInsert Fail\n", getThreadID());
            return FAILED;
        };


        //Method to check for duplicates after insertions
        GPUHEADER_D
        void removeDuplicates(keytype k, cg::thread_block_tile<tile_sz> tile) {
            //printf("%i: \t\tRemove Dups\n", getThreadID());
            //To store whether value was already encountered
            bool found = false;

            //Iterate over Hash Functions
            for (int i = 0; i < hn; i++) {
                uint64_cu hashed1 = RHASH(HFSIZE_BUCKET, hashlist[i], k);
                addtype add = getAdd(hashed1, AS);

                auto cur_bucket = CuckooBucket<tile_sz>(T, tile, add, Bs);
                cur_bucket.removeDuplicates(k, hashlist[i], &found);
            }
            //printf("%i: \t\tDups Removed\n", getThreadID());
        }

        //Lookup internal method
        GPUHEADER_D
        bool lookup(uint64_cu k, ClearyCuckooEntry<addtype, remtype>* T, cg::thread_block_tile<tile_sz> tile){
            //printf("%i: \t\tLookup\n", getThreadID());
            //Iterate over hash functions
            for (int i = 0; i < hn; i++) {
                uint64_cu hashed1 = RHASH(HFSIZE_BUCKET, hashlist[i], k);
                addtype add = getAdd(hashed1, AS);

                //printf("%i: Searching for %" PRIu64 " at %" PRIu32 "\n", getThreadID(), k, add);
                //Get Bucket and Find
                auto cur_bucket = CuckooBucket<tile_sz>(T, tile, add , Bs);
                auto res = cur_bucket.find(k, hashlist[i]);
                if (res) {
                    //printf("%i: \t\tLookup Success\n", getThreadID());
                    return true;
                }
            }
            //printf("%i: \t\tLookup Fail\n", getThreadID());
            return false;
        };

        GPUHEADER
        void print(ClearyCuckooEntry<addtype, remtype>* T) {
            printf("----------------------------------------------------------------\n");
            printf("|    i     |     R[i]       | O[i] |        key         |label |\n");
            printf("----------------------------------------------------------------\n");
            printf("Tablesize %i\n", tablesize);

            for (int i = 0; i < B; i++) {
                printf("----------------------------------------------------------------\n");
                printf("|                   Bucket %i                                   \n", i);
                printf("----------------------------------------------------------------\n");
                for (int j = 0; j < Bs; j++) {
                    keytype k = T[i*Bs + j].getR();
                    int label = T[i*Bs + j].getH();

                    printf("|%-10i|%-16" PRIl64 "|%-6i|%-20" PRIl64 "|%-6i|\n", j, T[i*Bs + j].getR(), T[i*Bs + j].getO(), k, T[i*Bs + j].getH());
                }
            }

            printf("------------------------------------------------------------\n");
        }


    public:
        /**
         * Constructor
         */
        CuckooBucketed() : CuckooBucketed(4,1,1){}

        CuckooBucketed(int addressSize, int hashNumber) :
            AS( addressSize - ((int)log2(tile_sz))), B((int)pow(2, AS)), RS(HS - AS){

            if (AS < 0) {
                //printf("!----------WARNING: TABLE TOO SMALL FOR TILE SIZE----------!\n");
            }
            //printf("Constructor\n");
            printf("AS:%i tile_sz:%i, log2(tile_sz):%i", AS, tile_sz, (int) log2(tile_sz));

            tablesize = B * Bs;

            int queueSize = std::max(100, (int)(tablesize / 10));

            hn = hashNumber;

            //Allocating Memory for tables
            //printf("\tAlloc Mem\n");
#ifdef GPUCODE
            gpuErrchk(cudaMallocManaged(&T, tablesize * sizeof(ClearyCuckooEntry<addtype, remtype>)));
            gpuErrchk(cudaMallocManaged(&hashlist, hn * sizeof(int)));
            gpuErrchk(cudaMallocManaged((void**)&rehashQueue, sizeof(SharedQueue<int>)));
            //gpuErrchk(cudaMallocManaged(&bucketIndex, Bs * sizeof(int)));
#else
            T = new ClearyCuckooEntry<addtype, remtype>[numBuckets*Bs + bucketSize];
            hashlist = new int[hn];
            bucketIndex = new int[Bs];
#endif
            //printf("\tInit Entries\n");
            //Init table entries
            for(int i=0; i<B; i++){
                for (int j = 0; j < Bs; j++) {
                    //printf("\t\tEntry %i %i\n",i, j);
                    new (&T[i*Bs + j]) ClearyCuckooEntry<addtype, remtype>();
                }
                // Possibly out-of-bounds:
                //bucketIndex[i] = 0;
            }

            //Default MAXLOOPS Value
            //1.82372633e+04 -2.60749645e+02  1.76799265e-02 -1.80594901e+04
            /*
            const double A = 18237.2633;
            const double x0 = -260.749645;
            const double k = .0176799265;
            const double off = -18059.4901;
            MAXLOOPS = std::max( MAXLOOPS, (int) ceil((A / (1.0 + exp(-k * (((double)AS) - x0)))) + off) );
            */
            //printf("\tCreate Hashlist\n");
            //Create HashList
            createHashList(hashlist);
            //printf("\tInit Complete\n");
        }

        /**
         * Destructor
         */
        ~CuckooBucketed(){
            //printf("Destructor\n");
            #ifdef GPUCODE
            gpuErrchk(cudaFree(T));
            gpuErrchk(cudaFree(hashlist));
            //gpuErrchk(cudaFree(bucketIndex));

            #else
            delete[] T;
            delete[] hashlist;
            //delete[] bucketIndex;
            #endif
        }

        //Taken from Better GPU Hash Tables
        GPUHEADER_D
        void coopDupCheck(bool to_check, keytype k) {
            //printf("%i: \tcoopInsert %" PRIu64"\n", getThreadID(), k);
            cg::thread_block thb = cg::this_thread_block();
            auto tile = cg::tiled_partition<tile_sz>(thb);
            //printf("%i: \tTiledPartition\n", getThreadID());
            auto thread_rank = tile.thread_rank();
            //Perform the insertions
            uint32_t work_queue;
            while (work_queue = tile.ballot(to_check)) {

                auto cur_lane = __ffs(work_queue) - 1;
                auto cur_k = tile.shfl(k, cur_lane);
                //printf("%i: \tThread Starting Insertion of %" PRIu64 "\n", getThreadID(), cur_k);
                removeDuplicates(cur_k, tile);
                if (tile.thread_rank() == cur_lane) {
                    to_check = false;
                }
                //printf("%i: \tInsertion Done\n", getThreadID());
            }
            //printf("%i: \tInsertion of  %" PRIu64" result:%i\n", getThreadID(), k, success);
            return;
        }

        //Taken from Better GPU Hash Tables
        GPUHEADER_D
        result coopInsert(bool to_insert, keytype k) {
            //printf("%i: \tcoopInsert %" PRIu64"\n", getThreadID(), k);
            cg::thread_block thb = cg::this_thread_block();
            auto tile = cg::tiled_partition<tile_sz>(thb);
            //printf("%i: \tTiledPartition\n", getThreadID());
            auto thread_rank = tile.thread_rank();
            result success = FAILED;

            //Perform the insertions
            uint32_t work_queue;
            while (work_queue = tile.ballot(to_insert)) {

                auto cur_lane = __ffs(work_queue) - 1;
                auto cur_k = tile.shfl(k, cur_lane);
                //printf("%i: \tThread Starting Insertion of %" PRIu64 "\n", getThreadID(), cur_k);
                auto cur_result = insertIntoTable(cur_k, T, hashlist, tile);
                if (tile.thread_rank() == cur_lane) {
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
            result insert(uint64_cu k, bool to_check = true) {
#else
            result insert(uint64_cu k, SpinBarrier * barrier) {
#endif

            return coopInsert(to_check, k);
        };

        //Public Lookup call
        GPUHEADER_D
        bool coopLookup(bool to_lookup, uint64_cu k){
            //printf("%i: Coop Lookup\n", getThreadID());
            //Iterate over hash functions and check if found
            cg::thread_block thb = cg::this_thread_block();
            cg::thread_block_tile<tile_sz> tile = cg::tiled_partition<tile_sz>(thb);
            auto thread_rank = tile.thread_rank();
            bool success = true;
            //Perform the insertions

            uint32_t work_queue;
            while (work_queue = tile.ballot(to_lookup)) {
                auto cur_lane = __ffs(work_queue) - 1;
                auto cur_k = tile.shfl(k, cur_lane);
                auto cur_result = lookup(cur_k, T, tile);

                if (tile.thread_rank() == cur_lane) {
                    to_lookup = false;
                    success = cur_result;
                }
            }
            //printf("%i: key:%" PRIu64 " result:%i\n", getThreadID(), k, success);
            return success;
            //printf("\t\t Lookup Failed\n");
        };

        //Clear all Table Entries
        GPUHEADER
        void clear(){
            for (int i = 0; i < B; i++) {
                for (int j = 0; j < Bs; j++) {
                    new (&T[i*Bs + j]) ClearyCuckooEntry<addtype, remtype>();
                }
            }
        }

        //Get the size of the Table
        GPUHEADER
        int getSize(){
            return tablesize;
        }

        //Return a copy of the hashlist
        GPUHEADER
        int* getHashlistCopy() {
            int* res = new int[hn];
            for (int i = 0; i < hn; i++) {
                res[i] = hashlist[i];
            }
            return res;
        }

        //Transform a vector to a list
        GPUHEADER_H
        std::vector<uint64_cu> toList() {
            std::vector<uint64_cu> list;
            for (int i = 0; i < tablesize; i++) {
                for (int j = 0; j < tablesize; j++) {
                    if (T[i * Bs + j].getO()) {
                        list.push_back(T[i * Bs + j].getR());
                    }
                }
            }
            return list;
        }

        //Iterate through all entries and do a read
        void readEverything(int N) {
            int j = 0;
            int step = 1;

            if (N < tablesize) {
                step = std::ceil(((float)tablesize) / ((float)N));
            }

            for (int i = 0; i < N; i+=step) {
                for (int k = 0; k < Bs; k++) {
                    j += T[(i * Bs + j) % tablesize].getR();
                }
            }

            if (j != 0) {
                //printf("Not all Zero\n");
            }
        }


        //Public print call
        GPUHEADER
        void print(){
            //printf("Hashlist:");
            for (int i = 0; i < hn; i++) {
                //printf("%i,", hashlist[i]);
            }
            //printf("\n");
            print(T);
        }

        //Method used for debugging
        GPUHEADER
        void debug(uint64_cu i) {

        }

        //Set the number of rehashes allowed
        void setMaxRehashes(int x){
            MAXREHASHES = x;
        }

        //Set the number of loops allowed
        void setMaxLoops(int x){
            MAXLOOPS = x;
        }

        //Get the number of hashes
        int getHashNum() {
            return hn;
        }

        GPUHEADER
        int getBucketSize() {
            return Bs;
        }

};

//Method to fill ClearyCuckooBucketedtable
template <int tile_sz>
GPUHEADER_G
#ifdef GPUCODE
void fillCuckooBucketed(int N, uint64_cu* vals, CuckooBucketed<tile_sz>* H, int* failFlag=nullptr, addtype begin = 0, int* count = nullptr, int id = 0, int s = 1)
#else
void fillCuckooBucketed(int N, uint64_cu* vals, CuckooBucketed<tile_sz>* H, SpinBarrier* barrier, int* failFlag = nullptr, addtype begin = 0, int id = 0, int s = 1)
#endif
{
#ifdef GPUCODE
    int index = blockIdx.x * blockDim.x + threadIdx.x;
    int stride = blockDim.x * gridDim.x;
#else
    int index = id;
    int stride = s;
#endif

    int max = calcBlockSize(N, H->getBucketSize());
    int localCounter = 0;

    //printf("Thread %i Starting - max %i\n", getThreadID(), max);
    for (int i = index + begin; i < max; i += stride) {

        bool realVal = false;
        keytype ins = 0;
        if(i < N + begin){
            realVal = true;
            ins = vals[i];
        }

        //printf("%i: Inserting: %" PRIu64 "\n", getThreadID(), ins);
        result res = H->insert(ins, realVal);
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
//Method to fill ClearyCuckooBucketedtable with a failCheck on every insertion
template <int tile_sz>
GPUHEADER_G
void fillCuckooBucketed(int N, uint64_cu* vals, CuckooBucketed<tile_sz> * H, addtype* occupancy, int* failFlag, int id = 0, int s = 1)
{
    int index = blockIdx.x * blockDim.x + threadIdx.x;
    int stride = blockDim.x * gridDim.x;


    int max = calcBlockSize(N, H->getBucketSize());

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

        H->insert(ins, realVal);
        // if (H->insert(ins, realVal) == FAILED) {
        //     if (realVal) {
        //         atomicCAS(&(failFlag[0]), 0, 1);
        //     }
        // }
        // atomicAdd(&occupancy[0], 1);
    }
}
#endif

//Method to check whether a ClearyCuckooBucketed table contains a set of values
template <int tile_sz>
GPUHEADER_G
void checkCuckooBucketed(int N, uint64_cu* vals, CuckooBucketed<tile_sz>* H, bool* res, int id = 0, int s = 1)
{
#ifdef GPUCODE
    int index = blockIdx.x * blockDim.x + threadIdx.x;
    int stride = blockDim.x * gridDim.x;
#else
    int index = id;
    int stride = s;
#endif

    int max = calcBlockSize(N, H->getBucketSize());

    for (int i = index; i < max; i += stride) {
        bool realVal = false;
        keytype look = 0;
        if (i < N) {
            realVal = true;
            look = vals[i];
        }

        if (!(H->coopLookup(realVal, look))) {
            res[0] = false;
        }
    }
}

//Method to do lookups in a ClearyCuckooBucketed table on an array of values
template <int tile_sz>
GPUHEADER_G
void lookupCuckooBucketed(int N, int start, int end, uint64_cu* vals, CuckooBucketed<tile_sz>* H, int id = 0, int s = 1) {
#ifdef GPUCODE
    int index = blockIdx.x * blockDim.x + threadIdx.x;
    int stride = blockDim.x * gridDim.x;
#else
    int index = id;
    int stride = s;
#endif

    int max = calcBlockSize(N, H->getBucketSize());

    for (int i = index; i < max; i += stride) {
        bool realVal = false;
        keytype look = 0;
        if (i < N) {
            realVal = true;
            look = vals[(i + start) % end];
        }
        H->coopLookup(realVal, look);
    }
}

//Method to fill ClearyCuckoo table
template <int tile_sz>
GPUHEADER_G
void dupCheckCuckooBucketed(int N, uint64_cu* vals, CuckooBucketed<tile_sz>* H, addtype begin = 0)
{
    int index = blockIdx.x * blockDim.x + threadIdx.x;
    int stride = blockDim.x * gridDim.x;

    int max = calcBlockSize(N, H->getBucketSize());

    //printf("Thread %i Starting\n", getThreadID());
    for (int i = index + begin; i < max + begin; i += stride) {
        //printf("Check iteration %i\n", i);
        bool realVal = false;
        keytype k = 0;
        if (i < N + begin) {
            realVal = true;
            k = vals[i];
        }
        //printf("Checking %" PRIu64 "\n", k);
        H->coopDupCheck(realVal, k);
    }
    //printf("Insertions %i Over\n", getThreadID());
}