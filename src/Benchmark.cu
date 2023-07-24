#include <atomic>

#include "bcht.hpp"
#include "HashTableGeneric.cuh"

#ifndef NUMGEN
#define NUMGEN
#include "numbergenerators.cu"
#endif


void readList(uint64_cu* xs, int N, int numLoops, int T = 1, int id = 0) {
    //printf("Reading List\n");
    int begin = 0;
    int end = N;

    if (T > 1) {
        int spread = N / T;
        begin = spread * id;
        end = begin + spread - 1;
        //printf("Begin: %i End:%i", begin, end);
    }

    for (int i = 0; i < numLoops; i++) {
        //printf("Reading List i:%i\n",i);
        uint64_cu val = 0;
        for (int j = begin; j < end; j++) {
            //printf("Reading List j:%i\n", j);
             val += xs[j];
        }
    }
}

void warmupThreads(int T, uint64_cu* xs, int N, int numLoops) {
    std::vector<std::thread> vecThread(T);
    for (int i = 0; i < T; i++) {
        vecThread.at(i) = std::thread(readList, xs, N, numLoops, T, i);
    }

    //Join Threads
    for (int i = 0; i < T; i++) {
        vecThread.at(i).join();
    }
}

void BenchmarkGeneralFilling(int NUM_TABLES_start, int NUM_TABLES, int INTERVAL, int NUM_SAMPLES, int NUM_THREADS, int NUM_LOOPS, int LOOP_STEP, int NUM_HASHES, int HASH_STEP, int NUM_REHASHES,
    int PERCENTAGE, int P_STEPSIZE, int DEPTH, std::vector<std::string>* params = nullptr) {

    const int WARMUP = 0;

    printf("=====================================================================\n");
    printf("                   Starting INSERTION  GENERAL BENCHMARK             \n");
    printf("=====================================================================\n");

    std::ofstream myfile;
    std::string specifier = "";
#ifdef GPUCODE
    specifier += "-GPU";
#else
    specifier += "-CPU";
#endif
#ifdef REHASH
    specifier += "-REHASH";
#endif
    std::string filename = "results/benchfill" + specifier + ".csv";

    if (params) {
        printf("Opening\n");
        myfile.open(filename, std::ios_base::app);
        printf("Maybe\n");
    }
    else {
        myfile.open(filename);
    }

    if (!myfile.is_open()) {
        printf("File Failed to Open\n");

        return;
    }
    printf("File Opened\n");

    if (!params) {
        myfile << "tablesize,numthreads,loops,hashes,rehashes,collision_percentage,collision_depth,samples,type,interval,time,test\n";
    }

    printf("=====================================================================\n");
    printf("                     Starting Cleary-Cuckoo                \n\n");

    //Tablesizes
    bool setup = true;
    for (int N = NUM_TABLES_start; N < NUM_TABLES_start + NUM_TABLES; N++) {
        if (params && setup) {
            N = std::stoi(params->at(0));
        }
        printf("Table Size:%i\n", N);

        int size = std::pow(2, N);
        int setsize = (int)(size / INTERVAL);
        int lookupSize = size / 4;

        if (setsize == 0) {
            printf("Error: Number of Intervals is greater than number of elements\n");
        }

        //Number of Threads
        //TODO change start to 0
        for (int T = 1; T < NUM_THREADS; T++) {
            if (params && setup) {
                T = std::stoi(params->at(1));
            }
            printf("\tNumber of Threads:%i\n", T);
            //Number of Loops
            for (int L = 0; L < NUM_LOOPS; L+= LOOP_STEP) {
#ifdef GPUCODE
                int numThreads = std::pow(2, T);
#else
                int numThreads = T + 1;
#endif

                if (params && setup) {
                    L = std::stoi(params->at(2));
                }
                printf("\t\tNumber of Loops:%i\n", L);
                //Number of Hashes
                for (int H = 1; H <= NUM_HASHES; H+=HASH_STEP) {
                    printf("\t\t\tNumber of Hashes:%i\n", H);
                    if (params && setup) {
                        H = std::stoi(params->at(3));
                    }

                    for (int R = 0; R <= NUM_REHASHES; R++) {
                        printf("\t\t\t\tRehashes:%i\n", R);
                        for (int P = 0; P <= PERCENTAGE; P += P_STEPSIZE) {
                            printf("\t\t\t\t\tPercentage:%i\n", P);
                            for (int D = 1; D <= DEPTH; D += 1) {
                                printf("\t\t\t\t\t\tDepth:%i\n", D);
                                //Number of samples
                                for (int S = 0; S < NUM_SAMPLES; S++) {
                                    printf("\t\t\t\t\t\t\tSample:%i\n", S);
                                    if (params && setup) {
                                        S = std::stoi(params->at(4));
                                    }
                                    setup = false;
                                    //Init Cleary Cuckoo

    #ifdef GPUCODE
                                    //printf("InitTable\n");
                                    ClearyCuckoo* cc;
                                    //printf("\tAllocTable\n");
                                    gpuErrchk(cudaMallocManaged((void**)&cc, sizeof(ClearyCuckoo)));
                                    //printf("\tStartTable\n");
                                    new (cc) ClearyCuckoo(N, H);
                                    //printf("InitFailFlag\n");
                                    int* failFlag;
                                    gpuErrchk(cudaMallocManaged((void**)&failFlag, sizeof(int)));
                                    (*failFlag) = false;
    #else
                                    ClearyCuckoo* cc = new ClearyCuckoo(N, H);
                                    int* failFlag = new int;
                                    (*failFlag) = false;
    #endif
                                    //printf("SetVals\n");
                                    cc->setMaxLoops(L);
                                    cc->setMaxRehashes(R);
                                    //printf("getHashlistCopy\n");
                                    int* hs = cc->getHashlistCopy();
                                    //printf("Generate CollisionSet\n");
                                    uint64_cu* vals = generateCollisionSet(size, N, H, hs, P, D);
                                    delete[] hs;
                                    //printf("Numsgenned\n");

                                    //printf("vals:\n");


                                    //Warmup
                                    //printf("Warmup\n");
                                    //readList(vals, size, 20);
                                    // cc->readEverything(size * 50);
                                    // warmupThreads(numThreads, vals, size, 20);



                                    //printf("Starting\n");
                                    //Loop over intervals
                                    for (int j = 0; j < INTERVAL + WARMUP; j++) {
                                        //Fill the table
                                        std::chrono::steady_clock::time_point begin;
                                        std::chrono::steady_clock::time_point end;

                                        if (j < WARMUP) {
                                            //cc->readEverything(20);
                                        }

                                        if (j >= WARMUP && !(*failFlag)) {
                                            //printf("Insertion %i\n", j);
                                            begin = std::chrono::steady_clock::now();
                                            fillClearyCuckoo << <1, std::pow(2, T) >> > (setsize, vals, cc, failFlag, setsize * (j - WARMUP));
                                            gpuErrchk(cudaPeekAtLastError());
                                            gpuErrchk(cudaDeviceSynchronize());

                                            //End the timer
                                            end = std::chrono::steady_clock::now();

                                            myfile << N << "," << numThreads << "," << L << "," << H << "," << R << "," << P << "," << D << "," << S << ",cuc," << (j - WARMUP) << "," << (std::chrono::duration_cast<std::chrono::nanoseconds> (end - begin).count()) / setsize << ", INS, \n";
                                        }

                                        if (failFlag) {
                                            myfile << N << "," << numThreads << "," << L << "," << H << "," << R << "," << P << "," << D << "," << S << ",cuc," << (j - WARMUP) << "," << -1 << ", INS,\n";
                                        }

                                        //Lookup Time Test
                                        if (j >= WARMUP && !(*failFlag)) {
                                            begin = std::chrono::steady_clock::now();
                                            lookupClearyCuckoo << <1, std::pow(2, T) >> > (lookupSize, 0, setsize * (j - WARMUP + 1), vals, cc);
                                            gpuErrchk(cudaPeekAtLastError());
                                            gpuErrchk(cudaDeviceSynchronize());

                                            //End the timer
                                            end = std::chrono::steady_clock::now();

                                            myfile << N << "," << numThreads << "," << L << "," << H << "," << R << "," << P << "," << D << "," << S << ",cuc," << (j - WARMUP) << "," << (std::chrono::duration_cast<std::chrono::nanoseconds> (end - begin).count()) / lookupSize << ", LOOK, \n";
                                        }

                                    }
                                    gpuErrchk(cudaFree(cc));
                                    gpuErrchk(cudaFree(failFlag));
                                    gpuErrchk(cudaFree(vals));
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    myfile.close();
    printf("\nBenchmark Done\n");
}


void BenchmarkSpeed(int NUM_TABLES_start, int NUM_TABLES, int INTERVAL, int NUM_SAMPLES, int NUM_THREADS, int PERCENTAGE, int P_STEPSIZE, int DEPTH, bool clearyBool=true, std::string source="") {

    const int WARMUP = 0;

    printf("=====================================================================\n");
    printf("                     Starting INSERTION  BENCHMARK                    \n");
    printf("=====================================================================\n");

    std::ofstream myfile;
    std::string specifier = "";
#ifdef GPUCODE
    specifier += "-GPU";
#else
    specifier += "-CPU";
#endif
#ifdef REHASH
    specifier += "-REHASH";
#endif
    if (clearyBool) {
        specifier += "-CLEARY";
    }

    if (source != "") {
        specifier += "-REALDATA";
    }

    std::string filename = "results/benchspeed" + specifier + ".csv";

    myfile.open(filename);

    if (!myfile.is_open()) {
        printf("File Failed to Open\n");

        return;
    }
    printf("File Opened\n");

    //Use file data
    uint64_cu* loadedvals = nullptr;
    uint64_cu* loadedvals32 = nullptr;
    int loadedsize = 0;
    if (source != "") {
        //printf("Reading Data\n");
        loadedvals = readCSV(source, &loadedsize);
        loadedvals32 = moduloList(loadedvals, loadedsize, std::pow(2,28));
    }

    myfile << "tablesize,numthreads,collision_percentage,collision_depth,samples,type,interval,time,test\n";

    printf("=====================================================================\n");
    //printf("                     Starting Cleary-Cuckoo                \n\n");

    //Tablesizes
    for (int N = NUM_TABLES_start; N < NUM_TABLES_start + NUM_TABLES; N++) {
        // Set GPU constants
        cudaMemcpyToSymbol(AS, &N, sizeof(int));

        int size = std::pow(2, N);
        int setsize = (int)(size / INTERVAL);
        int lookupSize = size / 4;

        printf("Table Size:%i (%i)\n", N, size);

        if (setsize == 0) {
            printf("Error: Number of Intervals is greater than number of elements\n");
        }

        // Generate / read input data
        uint64_cu* vals;
        uint64_cu* vals32;
        if (loadedvals == nullptr) {
            //vals = generateCollisionSet(size, N, NHASHFUNCTIONS, hs, P, D);
            vals32 = generateRandomSet(size, std::pow(2, DATASIZENEW));
            vals = vals32;
        }
        else {
            vals = loadedvals;
            vals32 = loadedvals32;
        }

        //Number of Thread blocks
        //int minThreads = (int)std::log2(std::max(TILESIZE, TILESIZE_CBUC));

        int MAX_BLOCK_SIZE = 9;
        int numThreadsBlock = std::pow(2, MAX_BLOCK_SIZE);
        int maxBlocks = (size + numThreadsBlock - 1) / numThreadsBlock;
        for (int numBlocks = maxBlocks / 10; numBlocks <= maxBlocks; numBlocks += (maxBlocks / 10)) { //T < std::min(N, minThreads+ NUM_THREADS); T++) {
            //int numThreads = 1;
            //int numBlocks = 1;

            // if (T > MAX_BLOCK_SIZE) {
            //     numThreads = std::pow(2, MAX_BLOCK_SIZE);
            //     numBlocks = std::pow(2, T - MAX_BLOCK_SIZE);
            // }
            // else {
            //     numThreads = std::pow(2, T);
            // }
            //int T = N;
            //numBlocks = (size + numThreadsBlock - 1) / numThreadsBlock;
            int numThreads = numBlocks * numThreadsBlock;

            printf("\tNumber of Threads: %i (%i blocks, %i threads)\n", numThreads, numBlocks, numThreadsBlock);

            bool compact;
            int N_new;
            for (int P = 0; P <= PERCENTAGE; P += P_STEPSIZE) {
                printf("\t\tPercentage:%i\n", P);
                for (int D = 1; D <= DEPTH; D += 1) {
                    printf("\t\t\tDepth:%i\n", D);
                    //Number of samples
                    for (int S = 0; S < NUM_SAMPLES; S++) {
                        printf("\t\t\t\tSample:%i\n", S);

                        /***********************************************************************************************
                        *
                        * ClearyCuckoo Speed Test
                        *
                        ***********************************************************************************************/
                        printf("\t\t\t\t\tClearyCuckoo\n");
                        // Set GPU constants
                        cudaMemcpyToSymbol(AS, &N, sizeof(int));
                        compact = true;
                        cudaMemcpyToSymbol(is_compact, &compact, sizeof(bool));

                        HashTableGeneric<uint32_t,1>* cc;
                        gpuErrchk(cudaMallocManaged((void**)&cc, sizeof(HashTableGeneric<uint32_t,1>)));
                        new (cc) HashTableGeneric<uint32_t,1>(size);
                        int* failFlag;
                        gpuErrchk(cudaMallocManaged((void**)&failFlag, sizeof(int)));
                        (*failFlag) = false;

                        int* tableCount;
                        gpuErrchk(cudaMallocManaged((void**)&tableCount, sizeof(int)));

                        (*tableCount) = 0;

                        int* hs = new int[3];
                        for (int hsi = 0; hsi < NHASHFUNCTIONS; hsi++) {
                            hs[hsi] = hsi;
                        }

                        //delete[] hs;

                        //printf("Numsgenned\n");

                        //printf("vals:\n");


                        //Warmup
                        //printf("Warmup\n");
                        //readList(vals, size, 20);
                        // cc->readEverything(size * 50);
                        // warmupThreads(numThreadsBlock, vals, size, 20);


                        //printf("Reading\n");
                        //Loop over intervals
                        int intervalMAX = INTERVAL + WARMUP;
                        if (loadedvals != nullptr) {
                            intervalMAX = loadedsize/setsize;
                            //printf("SetSize %i\n", setsize);
                        }
                        //printf("intervalMAX %i", intervalMAX);
                        for (int j = 0; j < intervalMAX; j++) {
                            //printf("\t\t\t\t\t\tInterval %i\n", j);
                            //Fill the table
                            std::chrono::steady_clock::time_point begin;
                            std::chrono::steady_clock::time_point end;

                            if (j < WARMUP) {
                                //cc->readEverything(20);
                            }

                            //Measurement Interval
                            if (j >= WARMUP && !(*failFlag)) {
                                begin = std::chrono::steady_clock::now();

                                //Do insertion iteration
                                //int insertionSize = numThreads;
                                //insertionSize = std::min((int)(size / INTERVAL), insertionSize);
                                int insertionSize = size;

                                for (int k = 0; k < setsize; k+= insertionSize) {
                                    //printf("\t\t\t\t\t\tStartpoint: %i\n", setsize * (j - WARMUP) + k);
                                    fill<uint32_t,1> << <numBlocks, numThreadsBlock >> > (insertionSize, vals, cc, failFlag, setsize * (j - WARMUP) + k, tableCount);
                                    gpuErrchk(cudaPeekAtLastError());
                                    gpuErrchk(cudaDeviceSynchronize());

                                    // dupCheckClearyCuckoo << <numBlocks, numThreadsBlock >> > (insertionSize, vals, cc, setsize * (j - WARMUP) + k);
                                    // gpuErrchk(cudaPeekAtLastError());
                                    // gpuErrchk(cudaDeviceSynchronize());
                                }

                                //End the timer
                                end = std::chrono::steady_clock::now();

                                myfile << N << "," << numThreads << "," << P << "," << D << "," << S << ",ccuc," << (int) (INTERVAL*(*tableCount)/ size) << "," << (std::chrono::duration_cast<std::chrono::nanoseconds> (end - begin).count()) << ", INS,\n";
                            }
                            if (*failFlag) {
                                //printf("\t\t\t\t\t\tFailed\n");
                                myfile << N << "," << numThreads << "," << P << "," << D << "," << S << ",ccuc," << (int) (INTERVAL*(*tableCount)/ size) << "," << -1 << ",INS,\n";
                                break;
                            }

                            // // Lookup Time Test
                            // if(j >= WARMUP && !(*failFlag)) {
                            //     begin = std::chrono::steady_clock::now();
                            //     lookupClearyCuckoo << <numBlocks, numThreadsBlock>> > (lookupSize, 0, setsize*(j- WARMUP + 1), vals, cc);
                            //     gpuErrchk(cudaPeekAtLastError());
                            //     gpuErrchk(cudaDeviceSynchronize());

                            //     //End the timer
                            //     end = std::chrono::steady_clock::now();

                            //     myfile << N << "," << numThreads << "," << P << "," << D << "," << S << ",ccuc," << (int) (INTERVAL*(*tableCount)/ size) << "," << (std::chrono::duration_cast<std::chrono::nanoseconds> (end - begin).count()) / lookupSize << ",LOOK,\n";
                            // }

                            // cc->print();

                        }
                        printf("Count ClearyCuckoo: %d\n", cc->count());

                        //printf("Delete CC Vars\n");
                        cc->deleteT();
                        gpuErrchk(cudaFree(cc));
                        gpuErrchk(cudaFree(failFlag));

                        if (clearyBool) {
                            /***********************************************************************************************
                            *
                            * Cleary Speed Test
                            *
                            ***********************************************************************************************/
                            printf("\t\t\t\t\tCleary\n");
                            Cleary* c;
                            gpuErrchk(cudaMallocManaged((void**)&c, sizeof(Cleary)));
                            new (c) Cleary(N, numThreads);

                            (*tableCount) = 0;


                            //Loop over intervals
                            for (int j = 0; j < intervalMAX; j++) {
                                std::chrono::steady_clock::time_point begin;
                                std::chrono::steady_clock::time_point end;

                                //Fill the table
                                if (j >= WARMUP) {
                                    begin = std::chrono::steady_clock::now();

                                    fillCleary << <numBlocks, numThreadsBlock >> > (setsize, vals, c, setsize * (j - WARMUP), tableCount);
                                    gpuErrchk(cudaPeekAtLastError());
                                    gpuErrchk(cudaDeviceSynchronize());

                                    //End the timer
                                    end = std::chrono::steady_clock::now();
                                    myfile << N << "," << numThreads << "," << P << "," << D << "," << S << ",cle," << (int) (INTERVAL*(*tableCount)/ size) << "," << (std::chrono::duration_cast<std::chrono::nanoseconds> (end - begin).count()) / setsize << ",INS,\n";
                                }

                                //Lookup
                                if (j >= WARMUP) {
                                    begin = std::chrono::steady_clock::now();
                                    lookupCleary << <numBlocks, numThreadsBlock >> > (lookupSize, 0, setsize * (j - WARMUP + 1), vals, c);
                                    gpuErrchk(cudaPeekAtLastError());
                                    gpuErrchk(cudaDeviceSynchronize());

                                    //End the timer
                                    end = std::chrono::steady_clock::now();

                                    myfile << N << "," << numThreads << "," << P << "," << D << "," << S << ",cle," << (int) (INTERVAL*(*tableCount)/ size) << "," << (std::chrono::duration_cast<std::chrono::nanoseconds> (end - begin).count()) / lookupSize << ",LOOK,\n";
                                }

                            }

                            delete (c);
                            gpuErrchk(cudaFree(c));
                        }

                        /***********************************************************************************************
                        *
                        * Cuckoo Speed Test
                        *
                        ***********************************************************************************************/
                        printf("\t\t\t\t\tCuckoo\n");
                        // Set GPU constants
                        cudaMemcpyToSymbol(AS, &N, sizeof(int));
                        compact = false;
                        cudaMemcpyToSymbol(is_compact, &compact, sizeof(bool));
                        HashTableGeneric<uint64_cu,1>* cuc;
                        gpuErrchk(cudaMallocManaged((void**)&cuc, sizeof(HashTableGeneric<uint64_cu,1>)));
                        new (cuc) HashTableGeneric<uint64_cu,1>(size);
                        int* failFlag2;
                        gpuErrchk(cudaMallocManaged((void**)&failFlag2, sizeof(int)));
                        (*failFlag2) = false;

                        (*tableCount) = 0;

                        //Warmup
                        //printf("Warmup\n");
                        //readList(vals, size, 20);
                        // cuc->readEverything(size * 50);
                        // warmupThreads(numThreadsBlock, vals, size, 20);


                        //printf("Reading\n");
                        //Loop over intervals
                        for (int j = 0; j < intervalMAX; j++) {
                            //Fill the table
                            std::chrono::steady_clock::time_point begin;
                            std::chrono::steady_clock::time_point end;

                            if (j < WARMUP) {
                                //cc->readEverything(20);
                            }

                            if (j >= WARMUP && !(*failFlag2)) {
                                begin = std::chrono::steady_clock::now();


                                //Do insertion iteration
                                //int insertionSize = numThreads;
                                //insertionSize = std::min((int)(size / INTERVAL), insertionSize);
                                int insertionSize = size;
                                printf("Cuckoo insertion size: %u\n", insertionSize);

                                for (int k = 0; k < setsize; k += insertionSize) {
                                    //printf("\t\t\t\t\t\tStartpoint: %i\n", setsize * (j - WARMUP) + k);
                                    fill<uint64_cu,1> << <numBlocks, numThreadsBlock >> > (insertionSize, vals, cuc, failFlag2, setsize* (j - WARMUP) + k, tableCount);
                                    gpuErrchk(cudaPeekAtLastError());
                                    gpuErrchk(cudaDeviceSynchronize());

                                    // dupCheckCuckoo << <numBlocks, numThreadsBlock >> > (insertionSize, vals, cuc, setsize * (j - WARMUP) + k);
                                    // gpuErrchk(cudaPeekAtLastError());
                                    // gpuErrchk(cudaDeviceSynchronize());
                                }

                                //End the timer
                                end = std::chrono::steady_clock::now();

                                myfile << N << "," << numThreads << "," << P << "," << D << "," << S << ",cuc," << (int)(INTERVAL * (*tableCount) / size) << "," << (std::chrono::duration_cast<std::chrono::nanoseconds> (end - begin).count()) << ", INS,\n";
                            }
                            if (*failFlag2) {
                                //cuc->print();
                                myfile << N << "," << numThreads << "," << P << "," << D << "," << S << ",cuc," << (int) (INTERVAL*(*tableCount)/ size) << "," << -1 << ",INS,\n";
                                break;
                            }

                            //Lookup Time Test
                            // if (j >= WARMUP && !(*failFlag2)) {
                            //     begin = std::chrono::steady_clock::now();
                            //     lookupCuckoo << <numBlocks, numThreadsBlock >> > (lookupSize, 0, setsize * (j - WARMUP + 1), vals, cuc);
                            //     gpuErrchk(cudaPeekAtLastError());
                            //     gpuErrchk(cudaDeviceSynchronize());

                            //     //End the timer
                            //     end = std::chrono::steady_clock::now();

                            //     myfile << N << "," << numThreads * numBlocks << "," << P << "," << D << "," << S << ",cuc," << (int) (INTERVAL*(*tableCount)/ size) << "," << (std::chrono::duration_cast<std::chrono::nanoseconds> (end - begin).count()) / lookupSize << ",LOOK,\n";
                            // }

                        }
                        printf("Count Cuckoo: %d\n", cuc->count());
                        //printf("Delete CC Vars\n");
                        cuc->deleteT();
                        gpuErrchk(cudaFree(cuc));
                        gpuErrchk(cudaFree(failFlag2));

                        /***********************************************************************************************
                        *
                        * ClearyCuckooBucketed Speed Test
                        *
                        ***********************************************************************************************/
                        printf("\t\t\t\t\tClearyCuckooBucketed\n");
                        // Set GPU constants
                        N_new = N - (int)std::log2(COMPACT_BUCKETSIZE);
                        cudaMemcpyToSymbol(AS, &N_new, sizeof(int));
                        compact = true;
                        cudaMemcpyToSymbol(is_compact, &compact, sizeof(bool));
                        HashTableGeneric<uint32_t,COMPACT_BUCKETSIZE>* ccb;
                        gpuErrchk(cudaMallocManaged((void**)&ccb, sizeof(HashTableGeneric<uint32_t,COMPACT_BUCKETSIZE>)));
                        new (ccb) HashTableGeneric<uint32_t,COMPACT_BUCKETSIZE>(size);
                        int* failFlag3;
                        gpuErrchk(cudaMallocManaged((void**)&failFlag3, sizeof(int)));
                        (*failFlag3) = false;
                        //printf("\t\t\t\t\t\tInitDone\n");

                        (*tableCount) = 0;

                        //Warmup
                        //printf("Warmup\n");
                        //readList(vals, size, 20);
                        //ccb->readEverything(size * 50);
                        //warmupThreads(numThreadsBlock, vals, size, 20);


                        //printf("Reading\n");
                        //Loop over intervals
                        //printf("\t\t\t\t\t\tStartingLoops\n");
                        for (int j = 0; j < intervalMAX; j++) {
                            //Fill the table
                            std::chrono::steady_clock::time_point begin;
                            std::chrono::steady_clock::time_point end;

                            if (j < WARMUP) {
                                //cc->readEverything(20);
                            }

                            if (j >= WARMUP && !(*failFlag3)) {
                                begin = std::chrono::steady_clock::now();

                                //Do insertion iteration
                                //int insertionSize = numThreads;
                                //insertionSize = std::min((int)(size / INTERVAL), insertionSize);
                                //printf("\t\t\t\t\t\tInsertionSize: %i\n", insertionSize);
                                int insertionSize = size;

                                for (int k = 0; k < setsize; k += insertionSize) {
                                    //printf("\t\t\t\t\t\tStartpoint: %i\n", setsize * (j - WARMUP) + k);
                                    fill<uint32_t,COMPACT_BUCKETSIZE> << <numBlocks, numThreadsBlock >> > (insertionSize, vals32, ccb, failFlag3, setsize * (j - WARMUP) + k, tableCount);
                                    gpuErrchk(cudaPeekAtLastError());
                                    gpuErrchk(cudaDeviceSynchronize());

                                    // dupCheckClearyCuckooBucketed<TILESIZE> << <numBlocks, numThreadsBlock >> > (insertionSize, vals32, ccb, setsize * (j - WARMUP) + k);
                                    // gpuErrchk(cudaPeekAtLastError());
                                    // gpuErrchk(cudaDeviceSynchronize());
                                }

                                //End the timer
                                end = std::chrono::steady_clock::now();

                                myfile << N << "," << numThreads << "," << P << "," << D << "," << S << ",ccbuc," << (int) (INTERVAL*(*tableCount)/ size) << "," << (std::chrono::duration_cast<std::chrono::nanoseconds> (end - begin).count()) << ", INS,\n";
                            }
                            if (*failFlag3) {
                                myfile << N << "," << numThreads << "," << P << "," << D << "," << S << ",ccbuc," << (int) (INTERVAL*(*tableCount)/ size) << "," << -1 << ",INS,\n";
                                break;
                            }
                            //printf("\t\t\t\t\t\tLookup\n");
                            //Lookup Time Test
                            // if (j >= WARMUP && !(*failFlag3)) {
                            //     begin = std::chrono::steady_clock::now();
                            //     lookupClearyCuckooBucketed<TILESIZE> << <numBlocks, numThreadsBlock >> > (lookupSize, 0, setsize * (j - WARMUP + 1), vals32, ccb);
                            //     gpuErrchk(cudaPeekAtLastError());
                            //     gpuErrchk(cudaDeviceSynchronize());

                            //     //End the timer
                            //     end = std::chrono::steady_clock::now();

                            //     myfile << N << "," << numThreads * numBlocks << "," << P << "," << D << "," << S << ",ccbuc," << (int) (INTERVAL*(*tableCount)/ size) << "," << (std::chrono::duration_cast<std::chrono::nanoseconds> (end - begin).count()) / lookupSize << ",LOOK,\n";
                            // }

                        }
                        printf("Count ClearyCuckoo bucketed: %d\n", ccb->count());
                        ccb->deleteT();
                        gpuErrchk(cudaFree(ccb));
                        gpuErrchk(cudaFree(failFlag3));

                        /***********************************************************************************************
                        *
                        * CuckooBucketed Speed Test
                        *
                        ***********************************************************************************************/
                        printf("\t\t\t\t\tCuckooBucketed\n");
                        // Set GPU constants
                        N_new = N - (int)std::log2(BUCKETSIZE);
                        cudaMemcpyToSymbol(AS, &N_new, sizeof(int));
                        compact = false;
                        cudaMemcpyToSymbol(is_compact, &compact, sizeof(bool));
                        HashTableGeneric<uint64_cu,BUCKETSIZE>* b;
                        gpuErrchk(cudaMallocManaged((void**)&b, sizeof(HashTableGeneric<uint64_cu,BUCKETSIZE>)));
                        new (b) HashTableGeneric<uint64_cu,BUCKETSIZE>(size);
                        int* failFlag4;
                        gpuErrchk(cudaMallocManaged((void**)&failFlag4, sizeof(int)));
                        (*failFlag4) = false;
                        //printf("\t\t\t\t\t\tInitDone\n");

                        (*tableCount) = 0;

                        //Warmup
                        //printf("Warmup\n");
                        //readList(vals, size, 20);
                        //ccb->readEverything(size * 50);
                        //warmupThreads(numThreadsBlock, vals, size, 20);


                        //printf("Reading\n");
                        //Loop over intervals
                        //printf("\t\t\t\t\t\tStartingLoops\n");
                        for (int j = 0; j < intervalMAX; j++) {
                            //Fill the table
                            std::chrono::steady_clock::time_point begin;
                            std::chrono::steady_clock::time_point end;

                            if (j < WARMUP) {
                                //cc->readEverything(20);
                            }

                            if (j >= WARMUP && !(*failFlag4)) {
                                begin = std::chrono::steady_clock::now();

                                //Do insertion iteration
                                //int insertionSize = numThreads;
                                //insertionSize = std::min((int)(size / INTERVAL), insertionSize);
                                //printf("\t\t\t\t\t\tInsertionSize: %i\n", insertionSize);
                                int insertionSize = size;

                                for (int k = 0; k < setsize; k += insertionSize) {
                                    //printf("\t\t\t\t\t\tStartpoint: %i\n", setsize * (j - WARMUP) + k);
                                    fill<uint64_cu,BUCKETSIZE> << <numBlocks, numThreadsBlock >> > (insertionSize, vals32, b, failFlag4, setsize * (j - WARMUP) + k, tableCount);
                                    gpuErrchk(cudaPeekAtLastError());
                                    gpuErrchk(cudaDeviceSynchronize());

                                    // dupCheckCuckooBucketed<TILESIZE_CBUC> << <numBlocks, numThreadsBlock >> > (insertionSize, vals32, b, setsize * (j - WARMUP) + k);
                                    // gpuErrchk(cudaPeekAtLastError());
                                    // gpuErrchk(cudaDeviceSynchronize());
                                }

                                //End the timer
                                end = std::chrono::steady_clock::now();

                                myfile << N << "," << numThreads << "," << P << "," << D << "," << S << ",buc," << (int)(INTERVAL * (*tableCount) / size) << "," << (std::chrono::duration_cast<std::chrono::nanoseconds> (end - begin).count()) << ", INS,\n";
                            }
                            if (*failFlag4) {
                                myfile << N << "," << numThreads << "," << P << "," << D << "," << S << ",buc," << (int)(INTERVAL * (*tableCount) / size) << "," << -1 << ",INS,\n";
                                break;
                            }
                            //printf("\t\t\t\t\t\tLookup\n");
                            //Lookup Time Test
                            // if (j >= WARMUP && !(*failFlag4)) {
                            //     begin = std::chrono::steady_clock::now();
                            //     lookupCuckooBucketed<TILESIZE_CBUC> << <numBlocks, numThreadsBlock >> > (lookupSize, 0, setsize * (j - WARMUP + 1), vals32, b);
                            //     gpuErrchk(cudaPeekAtLastError());
                            //     gpuErrchk(cudaDeviceSynchronize());

                            //     //End the timer
                            //     end = std::chrono::steady_clock::now();

                            //     myfile << N << "," << numThreads * numBlocks << "," << P << "," << D << "," << S << ",buc," << (int) (INTERVAL*(*tableCount)/ size) << "," << (std::chrono::duration_cast<std::chrono::nanoseconds> (end - begin).count()) / lookupSize << ",LOOK,\n";
                            // }

                        }

                        //ccb->print();

                        //printf("Delete CC Vars\n");
                        printf("Count Cuckoo bucketed: %d\n", b->count());
                        b->deleteT();
                        gpuErrchk(cudaFree(b));
                        gpuErrchk(cudaFree(failFlag4));
                        gpuErrchk(cudaFree(tableCount));

                        /***********************************************************************************************
                        *
                        * bcht
                        *
                        ***********************************************************************************************/
                        // printf("\t\t\t\t\tBCHT\n");
                        // bght::bcht<int, int> bchtTable(((int) pow(2, N)), 0, 0);


                        // //Free any randomly generated datasets
                        // if (loadedvals == nullptr) {
                        //     gpuErrchk(cudaFree(vals));
                        //     gpuErrchk(cudaFree(vals32));
                        // }

                        // //Warmup
                        // //printf("Warmup\n");
                        // readList(vals, size, 20);
                        // //ccb->readEverything(size * 50);
                        // warmupThreads(numThreads, vals, size, 20);

                        // for (int j = 0; j < intervalMAX; j++) {
                        //     //Fill the table
                        //     std::chrono::steady_clock::time_point begin;
                        //     std::chrono::steady_clock::time_point end;

                        //     if (j < WARMUP) {
                        //         //cc->readEverything(20);
                        //     }

                        //     if (j >= WARMUP && !(*failFlag4)) {
                        //         begin = std::chrono::steady_clock::now();

                        //         //Do insertion iteration
                        //         int insertionSize = numThreads;
                        //         insertionSize = std::min((int)(size / INTERVAL), insertionSize);
                        //         //printf("\t\t\t\t\t\tInsertionSize: %i\n", insertionSize);

                        //         for (int k = 0; k < setsize; k += insertionSize) {
                        //             //printf("\t\t\t\t\t\tStartpoint: %i\n", setsize * (j - WARMUP) + k);
                        //             fillBCHT << <numBlocks, numThreads >> > (insertionSize, vals32, bchtTable, failFlag4, setsize * (j - WARMUP) + k, tableCount);
                        //             gpuErrchk(cudaPeekAtLastError());
                        //             gpuErrchk(cudaDeviceSynchronize());
                        //         }

                        //         //End the timer
                        //         end = std::chrono::steady_clock::now();

                        //         myfile << N << "," << numThreads * numBlocks << "," << P << "," << D << "," << S << ",bcht," << (int)(INTERVAL * (*tableCount) / size) << "," << (std::chrono::duration_cast<std::chrono::nanoseconds> (end - begin).count()) / setsize << ", INS,\n";
                        //     }
                        //     if (*failFlag4) {
                        //         myfile << N << "," << numThreads * numBlocks << "," << P << "," << D << "," << S << ",bcht," << (int)(INTERVAL * (*tableCount) / size) << "," << -1 << ",INS,\n";
                        //         break;
                        //     }
                        //     //printf("\t\t\t\t\t\tLookup\n");
                        //     //Lookup Time Test
                        //     if (j >= WARMUP && !(*failFlag4)) {
                        //         begin = std::chrono::steady_clock::now();
                        //         lookupBCHT << <numBlocks, numThreads >> > (lookupSize, 0, setsize * (j - WARMUP + 1), vals32, bchtTable);
                        //         gpuErrchk(cudaPeekAtLastError());
                        //         gpuErrchk(cudaDeviceSynchronize());

                        //         //End the timer
                        //         end = std::chrono::steady_clock::now();

                        //         myfile << N << "," << numThreads * numBlocks << "," << P << "," << D << "," << S << ",bcht," << (int)(INTERVAL * (*tableCount) / size) << "," << (std::chrono::duration_cast<std::chrono::nanoseconds> (end - begin).count()) / lookupSize << ",LOOK,\n";
                        //     }

                        // }
                    }
                }
            }
        }
        gpuErrchk(cudaFree(vals32));
    }

    //Free the loaded data set if exists
    if (loadedvals != nullptr) {
        gpuErrchk(cudaFree(loadedvals));
        gpuErrchk(cudaFree(loadedvals32));
    }

    myfile.close();
    printf("\nBenchmark Done\n");
}



void BenchmarkMaxOccupancy(int TABLE_START, int NUM_TABLES, int HASH_START, int NUM_HASHES, int HASH_STEP, int NUM_LOOPS, int LOOP_STEP, int NUM_REHASHES, int REHASH_STEP, int NUM_SAMPLES) {

    printf("=====================================================================\n");
    printf("                   Starting MAX Occupancy Benchmark                  \n");
    printf("=====================================================================\n");

    std::ofstream myfile;
    std::string specifier = "";
#ifdef GPUCODE
    specifier += "-GPU";
#else
    specifier += "-CPU";
#endif
#ifdef REHASH
    specifier += "-REHASH";
#endif

    std::string filename = "results/benchmax";
    if (HASH_START == 4 && NUM_HASHES == 1) {
        filename = "results/benchmax_4";
    }

    filename = filename + specifier + ".csv";


    myfile.open(filename);
    if (!myfile.is_open()) {
        printf("File Failed to Open\n");
        return;
    }
    printf("File Opened");

    myfile << "tablesize,hashes,loops,rehashes,samples,max\n";

    //MAX_LOOPS
    for (int N = TABLE_START; N < TABLE_START + NUM_TABLES; N++) {
        printf("Table Size:%i\n", N);
        int size = std::pow(2, N);
        for (int H = HASH_START; H < HASH_START + NUM_HASHES; H+=HASH_STEP) {
            printf("\tNum of Hashes:%i\n", H);
            for (int L = 0; L < NUM_LOOPS; L+=LOOP_STEP) {
                printf("\t\tNum of Loops:%i\n", L);
                for (int R = 0; R <= NUM_REHASHES; R+=REHASH_STEP) {
                    printf("\t\t\tNum of Rehashes:%i\n", R);
                    for (int S = 0; S < NUM_SAMPLES; S++) {
                        //printf("\t\t'tSample Number:%i\n", S);
                        uint64_cu* vals = generateRandomSet(size);

                        //Init Cleary Cuckoo
                        //printf("INit Table\n");
#ifdef GPUCODE
                        ClearyCuckoo* cc;
                        gpuErrchk(cudaMallocManaged((void**)&cc, sizeof(ClearyCuckoo)));
                        new (cc) ClearyCuckoo(N, H);
#else
                        ClearyCuckoo* cc = new ClearyCuckoo(N, H);
#endif
                        cc->setMaxLoops(L);
                        cc->setMaxRehashes(R);

                        //printf("INit Complete\n");
#ifdef GPUCODE
                        int* failFlag;
                        gpuErrchk(cudaMallocManaged(&failFlag, sizeof(int)));
                        failFlag[0] = false;

                        //Var to store num of inserted values
                        addtype* occ;
                        gpuErrchk(cudaMallocManaged(&occ, sizeof(addtype)));
                        occ[0] = 0;

                        fillClearyCuckoo << <1, 1 >> > (size, vals, cc, occ, failFlag);
                        gpuErrchk(cudaPeekAtLastError());
                        gpuErrchk(cudaDeviceSynchronize());

                        myfile << N << "," << H << "," << L << "," << R << "," << S << "," << occ[0] << ",\n";
#else
                        std::atomic<bool> failFlag(false);
                        std::atomic<addtype> occ(0);
                        //printf("Filling Table\n");
                        SpinBarrier barrier(1);

                        fillClearyCuckoo(size, vals, cc, &barrier, &occ, &failFlag);
                        //printf("Writing\n");
                        myfile << N << "," << H << "," << L << "," << R << "," << S << "," << occ.load() << ",\n";
#endif


#ifdef GPUCODE

                        gpuErrchk(cudaFree(failFlag));
                        gpuErrchk(cudaFree(cc));
                        gpuErrchk(cudaFree(occ));
                        gpuErrchk(cudaFree(vals));
#else
                        //printf("Deleting\n");
                        delete cc;
                        delete[] vals;
#endif
                        //printf("Done\n");
                    }
                }
            }
        }
    }

    myfile.close();

    printf("\n\nBenchmark Done\n");
}


void BenchmarkMaxOccupancyBucket(int TABLE_START, int NUM_TABLES, int HASH_START, int NUM_HASHES, int HASH_STEP, int NUM_LOOPS, int LOOP_STEP, int NUM_SAMPLES) {

    printf("=====================================================================\n");
    printf("                   Starting MAX Occupancy Benchmark Bucket               \n");
    printf("=====================================================================\n");

    std::ofstream myfile;
    std::string specifier = "";
#ifdef GPUCODE
    specifier += "-GPU";
#else
    specifier += "-CPU";
#endif
#ifdef REHASH
    specifier += "-REHASH";
#endif

    std::string filename = "results/benchmaxbucket";

    filename = filename + specifier + ".csv";


    myfile.open(filename);
    if (!myfile.is_open()) {
        printf("File Failed to Open\n");
        return;
    }
    printf("File Opened\n");

    myfile << "tablesize,hashes,loops,samples,max\n";

    //MAX_LOOPS
    for (int N = TABLE_START; N < TABLE_START + NUM_TABLES; N++) {
        printf("Table Size:%i\n", N);
        int size = std::pow(2, N);
        for (int H = HASH_START; H < HASH_START + NUM_HASHES; H += HASH_STEP) {
            printf("\tNum of Hashes:%i\n", H);
            for (int L = 0; L < NUM_LOOPS; L += LOOP_STEP) {
                printf("\t\tNum of Loops:%i\n", L);

                for (int S = 0; S < NUM_SAMPLES; S++) {
                    //printf("\t\t'tSample Number:%i\n", S);
                    uint64_cu* vals = generateRandomSet(size, std::pow(2, DATASIZE_BUCKET));

                    //Init Cleary Cuckoo
                    //printf("INit Table\n");
#ifdef GPUCODE
                    ClearyCuckooBucketed<TILESIZE>* cc;
                    gpuErrchk(cudaMallocManaged((void**)&cc, sizeof(ClearyCuckooBucketed<TILESIZE>)));
                    new (cc) ClearyCuckooBucketed<TILESIZE>(N, H);
#else
                    ClearyCuckooBucketed* cc = new ClearyCuckooBucketed<TILESIZE>(N, H);
#endif
                    cc->setMaxLoops(L);

                    //printf("INit Complete\n");
#ifdef GPUCODE
                    int* failFlag;
                    gpuErrchk(cudaMallocManaged(&failFlag, sizeof(int)));
                    failFlag[0] = false;

                    //Var to store num of inserted values
                    addtype* occ;
                    gpuErrchk(cudaMallocManaged(&occ, sizeof(addtype)));
                    occ[0] = 0;

                    fillClearyCuckooBucketed<TILESIZE> << <1, 16 >> > (size, vals, cc, occ, failFlag);
                    gpuErrchk(cudaPeekAtLastError());
                    gpuErrchk(cudaDeviceSynchronize());

                    myfile << N << "," << H << "," << L << "," << S << "," << occ[0] << ",\n";
#else
                    std::atomic<bool> failFlag(false);
                    std::atomic<addtype> occ(0);
                    //printf("Filling Table\n");
                    SpinBarrier barrier(1);

                    fillClearyCuckooBucketed<TILESIZE>(size * BS, vals, cc, &barrier, &occ, &failFlag);
                    //printf("Writing\n");
                    myfile << N << "," << H << "," << L << "," << S << "," << occ.load() << ",\n";
#endif


#ifdef GPUCODE

                    gpuErrchk(cudaFree(failFlag));
                    gpuErrchk(cudaFree(cc));
                    gpuErrchk(cudaFree(occ));
                    gpuErrchk(cudaFree(vals));
#else
                    //printf("Deleting\n");
                    delete cc;
                    delete[] vals;
#endif
                    //printf("Done\n");
                }
            }
        }
    }

    myfile.close();

    printf("\n\nBenchmark Done\n");
}


void BenchmarkBucketed(int NUM_BUCKETS, int BUCKET_SIZE, int INTERVAL, int NUM_SAMPLES, int NUM_THREADS, int NUM_LOOPS, int LOOP_STEP, int NUM_HASHES, int HASH_STEP, int NUM_REHASHES) {

    const int WARMUP = 0;

    printf("=====================================================================\n");
    printf("                   Starting INSERTION  GENERAL BENCHMARK             \n");
    printf("=====================================================================\n");

    std::ofstream myfile;
    std::string specifier = "";
#ifdef GPUCODE
    specifier += "-GPU";
#else
    specifier += "-CPU";
#endif
#ifdef REHASH
    specifier += "-REHASH";
#endif
    std::string filename = "results/BucketBenchfill" + specifier + ".csv";


    myfile.open(filename);

    if (!myfile.is_open()) {
        printf("File Failed to Open\n");

        return;
    }
    printf("File Opened\n");

    myfile << "tablesize,numthreads,loops,hashes,buckets,bucketsize,samples,type,interval,time,test\n";


    printf("=====================================================================\n");
    printf("                     Starting Cleary-Cuckoo                \n\n");

    //Tablesizes
    for (int B = 1; B < NUM_BUCKETS; B++) {
        printf("NUM BUCKETS: %i\n", B);
        for (int Bs = 1; Bs < BUCKET_SIZE; Bs++) {
            printf("\tBUCKETSIZE: %i\n", Bs);
            int size = B * Bs;
            int lookupSize = size / 4;
            int setsize = (int)(size / INTERVAL);
            for (int H = 1; H < NUM_HASHES; H += HASH_STEP) {
                printf("\t\tNUM HASHES: %i\n", H);
                for (int L = 1; L < NUM_LOOPS; L += LOOP_STEP) {
                    printf("\t\t\tNUM LOOPS: %i\n", L);
                    //Number of Threads
                    for (int T = 0; T < NUM_THREADS; T++) {
                        printf("\t\t\t\tNumber of Threads:%i\n", T);
#ifdef GPUCODE
                        int numThreads = std::pow(2, T);
#else
                        int numThreads = T + 1;
#endif
                        for (int S = 0; S < NUM_SAMPLES; S++) {
                            uint64_cu* vals = generateRandomSet(size);

                            printf("\t\t\t\tSample:%i\n", S);
                            //Init Cleary Cuckoo Bucketed
#ifdef GPUCODE
                            ClearyCuckooBucketed<TILESIZE>* cc;
                            gpuErrchk(cudaMallocManaged((void**)&cc, sizeof(ClearyCuckooBucketed<TILESIZE>)));
                            new (cc) ClearyCuckooBucketed<TILESIZE>(B, H);

                            int* failFlag;
                            gpuErrchk(cudaMallocManaged((void**)&failFlag, sizeof(int)));
                            (*failFlag) = false;
#else
                            ClearyCuckooBucketed* cc = new ClearyCuckooBucketed<TILESIZE>(B, Bs, H);

                            int* failFlag = new int;
                            (*failFlag) = false;
#endif
                            cc->setMaxLoops(L);

                            for (int j = 0; j < INTERVAL + WARMUP; j++) {
                                //Fill the table
                                std::chrono::steady_clock::time_point begin;
                                std::chrono::steady_clock::time_point end;

                                if (j < WARMUP) {
                                    //cc->readEverything(20);
                                }

                                if (j >= WARMUP && !(*failFlag)) {
                                    //printf("Insertion %i\n", j);
                                    begin = std::chrono::steady_clock::now();
#ifdef GPUCODE
                                    fillClearyCuckooBucketed<TILESIZE> << <1, std::pow(2, T) >> > (setsize, vals, cc, failFlag, setsize * (j - WARMUP));
                                    gpuErrchk(cudaPeekAtLastError());
                                    gpuErrchk(cudaDeviceSynchronize());
#else
                                    std::vector<std::thread> vecThread(numThreads);
                                    SpinBarrier barrier(numThreads);
                                    //printf("LAUNCHING THREADS\n");
                                    for (int i = 0; i < numThreads; i++) {
                                        //printf("Starting Threads\n");
                                        vecThread.at(i) = std::thread(static_cast<void(*)(int, uint64_cu*, ClearyCuckoo*, SpinBarrier*, int*, addtype, int, int)>(fillClearyCuckooBucketed<TILESIZE>), setsize, vals, cc, &barrier, failFlag, setsize * (j - WARMUP), i, numThreads);
                                    }

                                    //Join Threads
                                    for (int i = 0; i < numThreads; i++) {
                                        vecThread.at(i).join();
                                    }
#endif
                                    //End the timer
                                    end = std::chrono::steady_clock::now();

                                    myfile << size << "," << numThreads << "," << L << "," << H << "," << B << "," << Bs << ","  << S << ",buc," << (j - WARMUP) << "," << (std::chrono::duration_cast<std::chrono::nanoseconds> (end - begin).count()) / setsize << ", INS, \n";
                                }

                                if (failFlag) {
                                    myfile << size << "," << numThreads << "," << L << "," << H << "," << B << "," << Bs << "," << S << ",buc," << (j - WARMUP) << "," << -1 << ", INS,\n";
                                }

                                //Lookup Time Test
                                if (j >= WARMUP && !(*failFlag)) {
                                    begin = std::chrono::steady_clock::now();
#ifdef GPUCODE
                                    lookupClearyCuckooBucketed<TILESIZE> << <1, std::pow(2, T) >> > (lookupSize, 0, setsize * (j - WARMUP + 1), vals, cc);
                                    gpuErrchk(cudaPeekAtLastError());
                                    gpuErrchk(cudaDeviceSynchronize());
#else
                                    std::vector<std::thread> vecThread(numThreads);
                                    for (int i = 0; i < numThreads; i++) {
                                        //printf("Starting Threads\n");
                                        vecThread.at(i) = std::thread(lookupClearyCuckooBucketed<TILESIZE>, lookupSize, 0, setsize * (j - WARMUP + 1), vals, cc, i, numThreads);
                                    }

                                    //Join Threads
                                    for (int i = 0; i < numThreads; i++) {
                                        vecThread.at(i).join();
                                    }
#endif
                                    //End the timer
                                    end = std::chrono::steady_clock::now();

                                    myfile << size << "," << numThreads << "," << L << "," << H << "," << B << "," << Bs << "," << S << ",cuc," << (j - WARMUP) << "," << (std::chrono::duration_cast<std::chrono::nanoseconds> (end - begin).count()) / lookupSize << ", LOOK, \n";
                                }

                            }


#ifdef GPUCODE

                            gpuErrchk(cudaFree(failFlag));
                            gpuErrchk(cudaFree(cc));
                            gpuErrchk(cudaFree(vals));
#else
                            //printf("Deleting\n");
                            delete cc;
                            delete[] vals;
#endif
                            //printf("Done\n");
                        }
                    }
                }
            }
        }
    }
        myfile.close();
        printf("\nBenchmark Done\n");
}
