#include <iostream>
#include <iomanip>
#include <stdlib.h>
#include <math.h>
#include <string>
#include <math.h>
#include <assert.h>

#include <bitset>
#include <inttypes.h>

#include <curand.h>
#include <curand_kernel.h>

#include <time.h>

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

#include "ClearyEntry.cu"


//Enum for searching

enum direction{up, down, here};

__global__ void setup_kernel(curandState* state) {
    int idx = threadIdx.x + blockDim.x * blockIdx.x;
    curand_init(1234, idx, 0, &state[idx]);
}


class Cleary : public HashTable{
    //Allows for easy changing of the types

    private:
        //Constant Vars
        const static int HS = 59;           //HashSize
        const static int BUFFER = 0;        //Space assigned for overflow
        const static int MAXLOOPS = 24;
        const static int A_UNDEFINED = 0;

        bool GPU;

        //Vars assigned at construction
        int AS;                             //AdressSize 
        int RS;                             //RemainderSize
        int size;                           //Allocated Size of Table
        int tablesize;                      //Actual size of table with buffer
        int occupancy = 0;

        //Random number generator
#ifdef GPUCODE
        curandState* d_state;
#endif

        addtype MAX_ADRESS;
        addtype MIN_ADRESS = 0;

        //Tables
        ClearyEntry<addtype, remtype>* T;

        //Hash function ID
        int h1;

        //Insert Method
        GPUHEADER
        addtype findIndex(uint64_cu k){           
            hashtype h = RHASH(HFSIZE, h1, k);
            addtype j = getAdd(h, AS);
            remtype rem = getRem(h, AS);

            addtype i = j;
            int cnt = 0;

            //Find first well defined A value
            while(T[i].getA() == A_UNDEFINED && i>=MIN_ADRESS && T[i].getO()){
                cnt = cnt - (T[i].getV() ? 1 : 0);
                i=i-1;
                if (i > MAX_ADRESS) {
                    break;
                }
            };

            if (i <= MAX_ADRESS && i >= MIN_ADRESS) {
                cnt = cnt + T[i].getA();
            }

            //Look for the relevant group
            direction dir = up;
            if(cnt < 0){
                dir = up;
                while(cnt != 0 && i != MAX_ADRESS){
                    i = i+1;
                    cnt = cnt + (T[i].getC() ? 1 : 0);
                };
                if(T[i].getR() >= rem){
                    dir = here;
                }
            }else if(cnt > 0){
                dir = down;
                while(cnt != 0 && i != MIN_ADRESS){
                    cnt = cnt - (T[i].getC() ? 1 : 0);
                    i = i - 1;
                }
                if(T[i].getR() <= rem){dir = here;}
            }else{
                if (i > MAX_ADRESS) {
                    i = 0;
                    //IF val is being inserted first time, stop here
                    if (!T[j].getV()) {
                        return i;
                    }
                }

                if(T[i].getR() > rem){dir = down;}
                else if(T[i].getR() < rem){dir = up;}
                else{
                    dir = here;}
            }

            //Look inside of the group
            switch (dir){
                case here:
                    break;

                case down:
                    while (dir != here) {
                        assert(i <= MAX_ADRESS);
                        if (T[i].getC() == 1 || i == MIN_ADRESS) { dir = here; }
                        else {
                            i = i - 1;
                            if (T[i].getR() <= rem) {
                                dir = here;
                            }
                        }
                    }
                    break;

                case up:
                    while (dir != here) {
                        assert(i <= MAX_ADRESS);
                        if (i == MAX_ADRESS) {
                            dir = here;
                        }
                        else if (T[i + 1].getC() == 1) {
                            dir = here;
                        }
                        else {
                            i = i + 1;
                            if (T[i].getR() >= rem) {
                                dir = here;
                            }
                        }
                    }
                    break;

                default:
                    break;
            };
            return i;
        }

        GPUHEADER
        addtype leftLock(addtype i) {
            if (i == MIN_ADRESS) {
                return i;
            }
            while (T[i].getO() && i>MIN_ADRESS) {
                i -= 1;
            }
            return i;
        }

        GPUHEADER
        addtype rightLock(addtype i) {
            if (i == MAX_ADRESS) {
                return i;
            }
            while (T[i].getO() && i<MAX_ADRESS) {
                i += 1;
            }
            return i;
        }


        GPUHEADER_D
        result insertIntoTable(keytype k, addtype left, addtype right) {
            hashtype h = RHASH(HFSIZE, h1, k);
            addtype j = getAdd(h, AS);
            remtype rem = getRem(h, AS);

            bool newgroup = false;

            //Find insertion index
            addtype i = findIndex(k);

            //Check virgin bit and set
            if (!T[j].getV()) {
                T[j].setV(true, true);
                newgroup = true;
            }

            bool groupstart = T[i].getC() == 1 && T[i].getO() != false;
            bool groupend;
            if (i != MAX_ADRESS) { groupend = T[i + 1].getC() == 1 && T[i].getO() != false; }
            else { groupend = true; }

            //Check whether i should be 0 (Check all smaller Vs
            bool setStart = false;
            
            if (i == MIN_ADRESS && j != MIN_ADRESS && !T[MIN_ADRESS].getV()) {
                setStart = true;
                for (int x = 1; x < j; x++) {
                    if (T[x].getV() != 0) {
                        setStart = false;
                        break;
                    }
                }
            }

            //If a new group needs to be formed, look for the end of the group
            if (newgroup && T[i].getO() && !setStart) {
                direction dir = up;
                while (dir != here) {
                    if (i == MAX_ADRESS) {
                        dir = here;
                    }
                    else if (T[i + 1].getC() == 1) {
                        i++;
                        dir = here;
                    }
                    else {
                        i = i + 1;
                    }
                };
            }

            //Decide to shift mem up or down
#ifdef GPUCODE
            int idx = threadIdx.x + blockDim.x * blockIdx.x;
            int shift = round(curand_uniform(&(d_state[idx]))) == 0 ? 1 : -1;
#else
            //Slightly cheating for random direction
            int ra = clock()%2;
            int shift = ra == 0 ? 1 : -1;
#endif

            //Prevent Overflows
            if (T[left].getO()) {
                shift = 1;
            }
            else if (T[right].getO()) {
                shift = -1;
            }
            

            //Edge cases where the location must be shifted
            bool setC = false;
            if (shift == -1) {
                if (groupstart && (!newgroup) && (T[i].getR() > rem) && T[i].getO() && (i != MIN_ADRESS)) {
                    T[i].setC(false, true);
                    setC = true;
                    i--;
                }
                else if (!newgroup && T[i].getR() > rem && T[i].getO() && i != MIN_ADRESS) {
                    i--;
                }
                else if (newgroup && T[i].getO() && i != MIN_ADRESS) {
                    if (i == MAX_ADRESS && j != MAX_ADRESS) {
                        bool checkPos = true;
                        for (int m = j + 1; m <= MAX_ADRESS; m++) {
                            if (T[m].getV()) { checkPos = false; break; }
                        }
                        if (!checkPos) {
                            i--;
                        }
                    }
                    else if (i != MAX_ADRESS) {
                        i--;
                    }
                }
            }
            if (shift == 1) {
                if (groupend && (!newgroup) && (T[i].getR() < rem) && T[i].getO() && (i != MAX_ADRESS)) {
                    i++;
                    T[i].setC(false, true);
                    setC = true;
                }
                else if (!newgroup && T[i].getR() < rem && T[i].getO() && i != MAX_ADRESS) {
                    i++;
                }
                else if (j == MIN_ADRESS && newgroup) {
                    i = MIN_ADRESS;
                }
            }

            //Store where the search started for later
            addtype startloc = i;
            boundaryAssert(i, MIN_ADRESS, MAX_ADRESS);

            //Check whether location is empty
            bool wasoccupied = T[i].getO();

            //Store values at found location
            remtype R_old = T[i].getR();
            bool C_old = T[i].getC();
            bool O_old = T[i].getO();

            //Insert new values
            T[i].setR(rem, true);

            T[i].setO(true, true);
            if ((shift == 1) && !setC) {
                T[i].setC(C_old);
            }
            else if (shift == -1) {
                T[i].setC(newgroup);
            }

            if (setC && shift == -1) { T[i].setC(true, true); }
            //Update C Value
            if (shift == 1 && !newgroup) {
                C_old = setC;
            }

            //If the space was occupied shift mem
            if (wasoccupied) {
                while (O_old) {
                    i += shift;
                    boundaryAssert(i, MIN_ADRESS, MAX_ADRESS);
                    //Store the values
                    remtype R_temp = T[i].getR();
                    bool C_temp = T[i].getC();
                    bool O_temp = T[i].getO();

                    //Put the old values in the new location
                    T[i].setR(R_old, true);
                    T[i].setO(true, true);
                    T[i].setC(C_old, true);

                    //Store the old values again
                    R_old = R_temp;
                    C_old = C_temp;
                    O_old = O_temp;

                    if (i == MIN_ADRESS || i == MAX_ADRESS) {
                        break;
                    }

                }
            }

            if(A_UNDEFINED != 0){
                //Find the first well-defined A
                addtype x = startloc;
                while(T[x].getA() == A_UNDEFINED && x!=MIN_ADRESS) {
                    x--;
                }
                if (x != MAX_ADRESS && !T[x].getO()) {
                    x++;
                }

                //Update the A values
                int A_old = 0;
                while (T[x].getO() && x <= MAX_ADRESS) {
                    boundaryAssert(x, MIN_ADRESS, MAX_ADRESS);
                    //Update Based on C and V
                    if (T[x].getC()) {
                        A_old += 1;
                    }
                    if (T[x].getV()) {
                        A_old -= 1;
                    }
                    T[x].setA(A_old, true);
                    x++;
                    if (x > MAX_ADRESS) {
                        break;
                    }
                }
            }

            return INSERTED;
        }


    public:
        /**
         * Constructor
         */

        //Default constructor for mem-alloc
        Cleary() {}

        //Constructor with size
        Cleary(int adressSize, int numThreads){
            //Init Variables
            AS = adressSize;
            RS = HS-AS;
            tablesize = (int) pow(2,AS) + 2*BUFFER;
            size = (int) pow(2,AS);
            MAX_ADRESS = tablesize - 1;

            //Allocate Memory
#ifdef GPUCODE
            gpuErrchk(cudaMallocManaged(&T, tablesize * sizeof(ClearyEntry<addtype, remtype>)));
#else
            T = new ClearyEntry<addtype, remtype>[tablesize];
#endif

            //Init Entries
            for(int i=0; i<tablesize; i++){
                new (&T[i]) ClearyEntry<addtype, remtype>();
            }

#ifdef GPUCODE
            //Init random num gen
            cudaMalloc(&d_state, numThreads*sizeof(curandState));
            setup_kernel << <1, numThreads >> > (d_state);
            gpuErrchk(cudaPeekAtLastError());
            gpuErrchk(cudaDeviceSynchronize());
#endif

            //Hash function
            h1 = 0;
        }

        /**
         * Destructor
         */
        ~Cleary() {
            #ifdef GPUCODE
            gpuErrchk(cudaFree(T));
            gpuErrchk(cudaFree(d_state));
            #else
            delete[] T;
            #endif
        }

        //Parallel Insertion Method
        GPUHEADER_D
        result insert(keytype k){
            //Calculate Hash
            hashtype h = RHASH(HFSIZE, h1, k);
            addtype j = getAdd(h, AS);
            remtype rem = getRem(h, AS);

            int counter=0;

            while (true) {
                counter++;
                boundaryAssert(j, MIN_ADRESS, MAX_ADRESS);

                //Try Non-Exclusive Write
                ClearyEntry<addtype, remtype> def(0, false, false, true, 0, false, false);
                ClearyEntry<addtype, remtype> newval(rem, true, true, true, 0, false, false);

                ClearyEntry<addtype, remtype> old(T[j].compareAndSwap(&def, &newval));

                //If not locked + not occupied then success
                if ((!old.getL()) && (!old.getO())) {
                    return INSERTED;
                }

                //Else Need Exclusivity
                addtype left = leftLock(j);
                addtype right = rightLock(j);

                boundaryAssert(left, MIN_ADRESS, MAX_ADRESS);
                boundaryAssert(right, MIN_ADRESS, MAX_ADRESS);

                if (!T[left].lock(left == MIN_ADRESS)) {
                    continue;
                }
                if (!T[right].lock(right == MAX_ADRESS)) {
                    T[left].unlock();
                    continue;
                }

                //Do a read
                if (lookup(k)) {
                    //Val already exists
                    T[left].unlock();
                    T[right].unlock();
                    return FOUND;
                }

                //Write
                result res = insertIntoTable(k, left, right);
                T[left].unlock();
                T[right].unlock();
                return res;
            }
        };

        //Lookup
        GPUHEADER
        bool lookup(uint64_cu k){
            //Hash Key
            hashtype h = RHASH(HFSIZE, h1, k);
            addtype j = getAdd(h, AS);
            remtype rem = getRem(h, AS);

            //If no values with add exist, return
            if(T[j].getV() == 0){
                return false;
            };

            //Find Index of value
            addtype i = findIndex(k);
            boundaryAssert(i, MIN_ADRESS, MAX_ADRESS);

            //If remainders are the same FOUND
            if(T[i].getR() == rem){
                return true;
            }

            return false;
        };

        //Clear Entries in table
        GPUHEADER
        void clear(){
            for(int i=0; i<tablesize; i++){
                new (&T[i]) ClearyEntry<addtype, remtype>();
            }
        }

        //Return size of table
        GPUHEADER
        int getSize(){
            return size;
        }

        //Read all entries in the tables
        void readEverything(int N) {
            int j = 0;
            for (int i = 0; i < N; i++) {
                j += T[i % tablesize].getR();
            }
            if (j != 0) {
                printf("Not all Zero\n");
            }
        }

        //Print table
        GPUHEADER
        void print(){
            printf("----------------------------------------------------------------\n");
            printf("|    i     |     R[i]       | C[i] | V[i] | O[i] | A[i] | L[i] |\n");
            printf("----------------------------------------------------------------\n");
            for(int i=0; i<tablesize; i++){
                if(true){
                    printf("|%-10i|%-16" PRIl64 "|%-6i|%-6i|%-6i|%-6i|%-6i|\n", i, T[i].getR(), T[i].getC(), T[i].getV(), T[i].getO(), T[i].getA(), T[i].getL());
                }
            }
            printf("----------------------------------------------------------------\n");
        }

        //No rehash
        GPUHEADER
        bool rehash(){return true;}

};

//Insert list of vals into table
GPUHEADER_G
void fillCleary(int N, uint64_cu* vals, Cleary* H, addtype begin = 0, int* count = nullptr, int id = 0, int s = 1)
{
#ifdef GPUCODE
    int index = blockIdx.x * blockDim.x + threadIdx.x;
    int stride = blockDim.x;
#else
    int index = id;
    int stride = s;
#endif

    int localCounter = 0;

    for (int i = index + begin; i < N + begin; i += stride) {
        //printf("\t\t\t\t\t\t\t%i\n", i);
        result res = H->insert(vals[i]);
        if (res == INSERTED) {
            localCounter++;
        }
        if (res == FAILED) {
            break;
        }
    }
    if (count != nullptr) {
        atomicAdd(count, localCounter);
    }
}

//Check if list of vals are all contained in table
GPUHEADER_G
void checkCleary(int N, uint64_cu* vals, Cleary* H, bool* res, int id = 0, int s = 1)
{
#ifdef GPUCODE
    int index = blockIdx.x * blockDim.x + threadIdx.x;
    int stride = blockDim.x;
#else
    int index = id;
    int stride = s;
#endif

    for (int i = index; i < N; i += stride) {
        if (!(H->lookup(vals[i]))) {
            printf("\tVal %" PRIu64 " Missing\n", vals[i]);
            res[0] = false;
        }
    }
}

//Lookup list of values in the table
GPUHEADER_G
void lookupCleary(int N, int start, int end, uint64_cu* vals, Cleary* H, int id = 0, int s = 1) {
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