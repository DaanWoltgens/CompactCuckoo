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

#ifndef CCENTRY
#define CCENTRY
#include "ClearyCuckooEntry.cu"
#include "ClearyCuckooEntryCompact.cu"
#endif




class ClearyCuckoo : HashTable {

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
    int AS;                         //AdressSize
    int RS;                         //RemainderSize
    int tablesize;
    int occupancy = 0;

    //Hash tables
    ClearyCuckooEntry<addtype, remtype>* T;

    int hashcounter = 0;

    //Hash function ID
    int hn;
    int* hashlist;

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
        //printf("\tUpdating Hashlist\n");
        for (int i = 0; i < hn; i++) {
            list[i] = (list[i] + 1 + i) % 32;
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
        bool setFlag(int* loc, int val, bool strict = true) {
        int val_i = val == 0 ? 1 : 0;

        //In devices, atomically exchange
        uint64_cu res = atomicCAS(loc, val_i, val);
        //Make sure the value hasn't changed in the meantime
        if ((res != val_i) && strict) {
            return false;
        }
        __threadfence();
        return true;
    }

#else
    GPUHEADER
        //Method to set Flags on CPU (Failure/Rehash)
        bool setFlag(std::atomic<int>* loc, int val, bool strict = true) {
        int val_i = val == 0 ? 1 : 0;
        //printf("%i:\t:Attempting CAS\n", getThreadID());
        if (std::atomic_compare_exchange_strong(loc, &val_i, val)) {
            //printf("%i:\t:Flag Set\n", getThreadID());
            return true;
        }
        else {
            return false;
        }
    }
#endif



    /**
     * Internal Insertion Loop
     **/
    GPUHEADER_D
        result insertIntoTable(keytype k, ClearyCuckooEntry<addtype, remtype>* T, int* hs, int depth = 0) {
        keytype x = k;
        int hash = hs[0];

        //If the key is already inserted don't do anything
        if (lookup(k, T)) {
            return FOUND;
        }
        //Start the iteration
        int c = 0;

        while (c < MAXLOOPS) {
            //Get the add/rem of k
            hashtype hashed1 = RHASH(HFSIZE, hash, x);
            addtype add = getAdd(hashed1, AS);
            remtype rem = getRem(hashed1, AS);

            //Exchange Values
            ClearyCuckooEntry<addtype, remtype> entry(rem, hash, true, false);
            T[add].exchValue(&entry);

            //Store the old value
            remtype temp = entry.getR();
            bool wasoccupied = entry.getO();
            int oldhash = entry.getH();

            //If the old val was empty return
            if (!wasoccupied) {
                return INSERTED;
            }

            //Otherwise rebuild the original key
            hashtype h_old = reformKey(add, temp, AS);
            keytype old_key = x;
            x = RHASH_INVERSE(HFSIZE, oldhash, h_old);
            if (old_key == x) {
                return FOUND;
            }

            //Hash with the next hash value
            hash = getNextHash(hs, oldhash);

            c++;
        }

        return FAILED;
    }

    //Lookup internal method
    GPUHEADER
        bool lookup(uint64_cu k, ClearyCuckooEntry<addtype, remtype>* T) {
        //Iterate over hash functions and check if found
        for (int i = 0; i < hn; i++) {
            uint64_cu hashed1 = RHASH(HFSIZE, hashlist[i], k);
            addtype add = getAdd(hashed1, AS);
            remtype rem = getRem(hashed1, AS);
            if ((T[add].getR() == rem) && T[add].getO() && (T[add].getH() == hashlist[i])) {
                return true;
            }
        }
        return false;
    };

    GPUHEADER
        void print(ClearyCuckooEntry<addtype, remtype>* T) {
        printf("----------------------------------------------------------------\n");
        printf("|    i     |     R[i]       | O[i] |        key         |label |\n");
        printf("----------------------------------------------------------------\n");
        printf("Tablesize %i\n", tablesize);
        for (int i = 0; i < tablesize; i++) {
            if (T[i].getO()) {
                remtype rem = T[i].getR();
                int label = T[i].getH();
                hashtype h = reformKey(i, rem, AS);
                keytype k = RHASH_INVERSE(HFSIZE, label, h);

                printf("|%-10i|%-16" PRIl64 "|%-6i|%-20" PRIl64 "|%-6i|\n", i, T[i].getR(), T[i].getO(), k, T[i].getH());
            }
        }
        printf("------------------------------------------------------------\n");
    }


public:
    /**
     * Constructor
     */
    ClearyCuckoo() {}

    ClearyCuckoo(int adressSize) : ClearyCuckoo(adressSize, 4) {}

    ClearyCuckoo(int adressSize, int hashNumber) {
        //Init variables
        AS = adressSize;
        RS = HS - AS;
        tablesize = (int)pow(2, AS);

        int queueSize = std::max(100, (int)(tablesize / 10));

        hn = hashNumber;

#ifdef REHASH
#ifdef GPUCODE
        failFlag = false;
        rehashFlag = false;
#else
        failFlag.store(false);
        rehashFlag.store(false);
#endif
#endif
        //Allocating Memory for tables
#ifdef GPUCODE
        gpuErrchk(cudaMallocManaged(&T, tablesize * sizeof(ClearyCuckooEntry<addtype, remtype>)));
        gpuErrchk(cudaMallocManaged(&hashlist, hn * sizeof(int)));
        gpuErrchk(cudaMallocManaged((void**)&rehashQueue, sizeof(SharedQueue<int>)));
#ifdef REHASH
        new (rehashQueue) SharedQueue<int>(queueSize);
#endif
#else
        T = new ClearyCuckooEntry<addtype, remtype>[tablesize];
        hashlist = new int[hn];
#ifdef REHASH
        rehashQueue = new SharedQueue<keytype>(queueSize);
#endif
#endif

        //Default MAXLOOPS Value
        //1.82372633e+04 -2.60749645e+02  1.76799265e-02 -1.80594901e+04
        const double A = 18237.2633;
        const double x0 = -260.749645;
        const double k = .0176799265;
        const double off = -18059.4901;

        MAXLOOPS = ceil((A / (1.0 + exp(-k * (((double)AS) - x0)))) + off);

        //Init table entries
        for (int i = 0; i < tablesize; i++) {
            new (&T[i]) ClearyCuckooEntry<addtype, remtype>();
        }

        //Create HashList
        createHashList(hashlist);
    }

    /**
     * Destructor
     */
    ~ClearyCuckoo() {
#ifdef GPUCODE
        gpuErrchk(cudaFree(T));
        gpuErrchk(cudaFree(hashlist));
#ifdef REHASH
        gpuErrchk(cudaFree(rehashQueue));
#endif
#else
        delete[] T;
        delete[] hashlist;
#ifdef REHASH
        delete rehashQueue;
#endif
#endif
    }

    //Public insertion call
    GPUHEADER_D
    result insert(uint64_cu k) {

        return insertIntoTable(k, T, hashlist, 0);
    };

    //Method to check for duplicates after insertions
    GPUHEADER
        void removeDuplicates(keytype k) {
        //To store whether value was already encountered
        bool found = false;

        for (int i = 0; i < hn; i++) {
            uint64_cu hashed1 = RHASH(HFSIZE, hashlist[i], k);
            addtype add = getAdd(hashed1, AS);
            remtype rem = getRem(hashed1, AS);

            if (T[add].getH() == hashlist[i] && T[add].getR() == rem && T[add].getO()) {
                //If value was already found
                if (found) {
                    //Mark as not occupied
                    T[add].setO(false);
                }
                //Mark value as found
                found = true;
            }
        }
    }


    //Public Lookup call
    GPUHEADER
        bool lookup(uint64_cu k) {
        return lookup(k, T);
    };

    //Clear all Table Entries
    GPUHEADER
        void clear() {
        for (int i = 0; i < tablesize; i++) {
            new (&T[i]) ClearyCuckooEntry<addtype, remtype>();
        }
    }

    //Get the size of the Table
    GPUHEADER
        int getSize() {
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
            if (T[i].getO()) {
                hashtype h_old = reformKey(i, T[i].getR(), AS);
                keytype x = RHASH_INVERSE(HFSIZE, T[i].getH(), h_old);
                list.push_back(x);
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

        for (int i = 0; i < N; i += step) {
            j += T[i % tablesize].getR();
        }

        if (j != 0) {
            printf("Not all Zero\n");
        }
    }


    //Public print call
    GPUHEADER
        void print() {
        printf("Hashlist:");
        for (int i = 0; i < hn; i++) {
            printf("%i,", hashlist[i]);
        }
        printf("\n");
        print(T);
    }

    //Method used for debugging
    GPUHEADER
        void debug(uint64_cu i) {

    }

    //Set the number of rehashes allowed
    void setMaxRehashes(int x) {
        MAXREHASHES = x;
    }

    //Set the number of loops allowed
    void setMaxLoops(int x) {
        MAXLOOPS = x;
    }

    //Get the number of hashes
    int getHashNum() {
        return hn;
    }

};

//Method to fill ClearyCuckoo table
GPUHEADER_G
#ifdef GPUCODE
void fillClearyCuckoo(int N, uint64_cu* vals, ClearyCuckoo* H, int* failFlag = nullptr, addtype begin = 0, int* count = nullptr, int id = 0, int s = 1)
#else
void fillClearyCuckoo(int N, uint64_cu* vals, ClearyCuckoo* H, SpinBarrier* barrier, int* failFlag = nullptr, addtype begin = 0, int id = 0, int s = 1)
#endif
{
#ifdef GPUCODE
    int index = blockIdx.x * blockDim.x + threadIdx.x;
    int stride = blockDim.x * gridDim.x;
#else
    int index = id;
    int stride = s;
#endif

    int localCounter = 0;

    //printf("Thread %i Starting\n", getThreadID());
    for (int i = index + begin; i < N + begin; i += stride) {
        //printf("\t\t\t\t\t\t\t%i\n", i);

        result res = H->insert(vals[i]);
        if (res == INSERTED) {
            localCounter++;
        }
        if (res == FAILED) {
            if (failFlag != nullptr) {
                (*failFlag) = true;
            }
            if (count != nullptr) {
                atomicAdd(count, localCounter);
            }
            break;
        }

        //printf("Insertions %i Over\n", getThreadID());

    }

    if (count != nullptr) {
        atomicAdd(count, localCounter);
    }
}


#ifdef GPUCODE
//Method to fill ClearyCuckoo table with a failCheck on every insertion
GPUHEADER_G
void fillClearyCuckoo(int N, uint64_cu * vals, ClearyCuckoo * H, addtype * occupancy, int* failFlag, int id = 0, int s = 1)
{
#ifdef GPUCODE
    int index = blockIdx.x * blockDim.x + threadIdx.x;
    int stride = blockDim.x * gridDim.x;
#else
    int index = id;
    int stride = s;
#endif

    for (int i = index; i < N; i += stride) {
        if (failFlag[0]) {
            break;
        }
#ifdef GPUCODE
        if (H->insert(vals[i]) == FAILED) {
#else
        if (H->insert(vals[i]) == FAILED) {
#endif
            atomicCAS(&(failFlag[0]), 0, 1);
            break;
        }
        atomicAdd(&occupancy[0], 1);
        }
    }
#endif

#ifndef GPUCODE
//Method to fill ClearyCuckoo table with a failCheck on every insertion
GPUHEADER_G
void fillClearyCuckoo(int N, uint64_cu * vals, ClearyCuckoo * H, SpinBarrier * barrier, std::atomic<addtype>*occupancy, std::atomic<bool>*failFlag, int id = 0, int s = 1)
{
#ifdef GPUCODE
    int index = blockIdx.x * blockDim.x + threadIdx.x;
    int stride = blockDim.x * gridDim.x;
#else
    int index = id;
    int stride = s;
#endif

    for (int i = index; i < N; i += stride) {
        if ((*failFlag).load()) {
            break;
        }
#ifdef GPUCODE
        if (H->insert(vals[i], stride) == FAILED) {
#else
        if (H->insert(vals[i], stride, barrier) == FAILED) {
#endif
            (*failFlag).store(true);
            break;
        }
        (*occupancy).fetch_add(1);
        }
#ifdef DUPCHECK
#ifndef GPUCODE
    barrier->signalThreadStop();
#endif
#endif
    }
#endif

//Method to check whether a ClearyCuckoo table contains a set of values
GPUHEADER_G
void checkClearyCuckoo(int N, uint64_cu * vals, ClearyCuckoo * H, bool* res, int id = 0, int s = 1)
{
#ifdef GPUCODE
    int index = blockIdx.x * blockDim.x + threadIdx.x;
    int stride = blockDim.x * gridDim.x;
#else
    int index = id;
    int stride = s;
#endif

    for (int i = index; i < N; i += stride) {
        if (!(H->lookup(vals[i]))) {
            res[0] = false;
        }
    }
}

//Method to do lookups in a ClearyCuckoo table on an array of values
GPUHEADER_G
void lookupClearyCuckoo(int N, int start, int end, uint64_cu * vals, ClearyCuckoo * H, int id = 0, int s = 1) {
#ifdef GPUCODE
    int index = blockIdx.x * blockDim.x + threadIdx.x;
    int stride = blockDim.x * gridDim.x;
#else
    int index = id;
    int stride = s;
#endif

    for (int i = index; i < N; i += stride) {
        H->lookup(vals[(i + start) % end]);
    }
}

//Method to fill ClearyCuckoo table
GPUHEADER_G
void dupCheckClearyCuckoo(int N, uint64_cu * vals, ClearyCuckoo * H, addtype begin = 0)

{
    int index = blockIdx.x * blockDim.x + threadIdx.x;
    int stride = blockDim.x * gridDim.x;

    //printf("Thread %i Starting\n", getThreadID());
    for (int i = index + begin; i < N + begin; i += stride) {
        H->removeDuplicates(vals[i]);
    }
    //printf("Insertions %i Over\n", getThreadID());
}