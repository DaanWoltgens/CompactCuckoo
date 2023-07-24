#include "numbergeneratorsTest.cu"
#include "ClearyCuckooTest.cu"
#include "SharedQueueTest.cu"
#include <cuda.h>

#ifndef TABLES
#define TABLES
#include "ClearyCuckoo.cu"
#include "Cleary.cu"
#include "ClearyCuckooBucketed.cu"
#include "CuckooBucketed.cu"
#include "Cuckoo.cu"
#endif

bool TestFill(int N, int T, int tablesize, uint64_cu* vals, bool c_bool, bool cc_bool, bool b_bool, bool cb_bool, bool cuc_bool) {
    bool testres = true;
    printf("TestRes\n");
    //Init Var
#ifdef GPUCODE
    bool* res;
    gpuErrchk(cudaMallocManaged((void**)&res, sizeof(bool)));
#else
    bool* res = new bool;
#endif
    int numThreads = std::pow(2, T);
    int numBlocks = 1;

    //Create Table 1
    printf("Testcc\n");
    if (cc_bool) {
#ifdef GPUCODE
        ClearyCuckoo* cc;
        gpuErrchk(cudaMallocManaged((void**)&cc, sizeof(ClearyCuckoo)));
        new (cc) ClearyCuckoo(tablesize, 16);
#else
        ClearyCuckoo* cc = new ClearyCuckoo(tablesize, 16);
#endif

        printf("Filling ClearyCuckoo\n");
#ifdef GPUCODE
        fillClearyCuckoo << <numBlocks, numThreads >> > (N, vals, cc);
        gpuErrchk(cudaPeekAtLastError());
        gpuErrchk(cudaDeviceSynchronize());

        dupCheckClearyCuckoo << <numBlocks, numThreads >> > (N, vals, cc);
        gpuErrchk(cudaPeekAtLastError());
        gpuErrchk(cudaDeviceSynchronize());
#else

        std::vector<std::thread> vecThread1(numThreads);
        SpinBarrier barrier(numThreads);

        for (int i = 0; i < numThreads; i++) {
            vecThread1.at(i) = std::thread(static_cast<void(*)(int, uint64_cu*, ClearyCuckoo*, SpinBarrier*, int*, addtype, int, int)>(fillClearyCuckoo), N, vals, cc, &barrier, nullptr, 0, i, numThreads);
        }

        //Join Threads
        for (int i = 0; i < numThreads; i++) {
            vecThread1.at(i).join();
        }
#endif
        printf("Devices Synced\n");
        cc->print();

        //Check Table
        res[0] = true;
        printf("Checking Cleary-Cuckoo\n");
#ifdef GPUCODE
        checkClearyCuckoo << <1, 1 >> > (N, vals, cc, res);
        gpuErrchk(cudaPeekAtLastError());
        gpuErrchk(cudaDeviceSynchronize());
#else
        checkClearyCuckoo(N, vals, cc, res);
#endif
        printf("Devices Synced\n");
        if (res[0]) {
            printf("All still in the table\n");
        }
        else {
            //testres = false;
            printf("!---------------------Vals Missing---------------------!\n");
        }

        //Check for duplicates
        std::vector<uint64_cu> ccList = cc->toList();
        std::set<uint64_cu> ccSet(ccList.begin(), ccList.end());

        if (ccSet.size() != ccList.size()) {
            printf("Duplicates Detected\n");
            testres = false;
        }

#ifdef GPUCODE
        gpuErrchk(cudaFree(cc));
#else
        delete cc;
#endif
    }

    printf("Testc\n");
    if (c_bool) {
        //Create Table 2
        printf("CreatingC\n");
#ifdef GPUCODE
        Cleary* c;
        gpuErrchk(cudaMallocManaged((void**)&c, sizeof(Cleary)));
        new (c) Cleary(tablesize, numThreads);
#else
        Cleary* c = new Cleary(tablesize, numThreads);
#endif

        printf("Filling Cleary\n");

#ifdef GPUCODE
        fillCleary << <numBlocks, numThreads >> > (N, vals, c);
        gpuErrchk(cudaPeekAtLastError());
        gpuErrchk(cudaDeviceSynchronize());
#else
        std::vector<std::thread> vecThread2(numThreads);

        for (int i = 0; i < numThreads; i++) {
            vecThread2.at(i) = std::thread(fillCleary, N, vals, c, 0, i, numThreads);
        }

        //Join Threads
        for (int i = 0; i < numThreads; i++) {
            vecThread2.at(i).join();
        }
#endif

        printf("Devices Synced\n");
        c->print();

        //Checking
        res[0] = true;
        printf("Checking Cleary\n");

#ifdef GPUCODE
        checkCleary << <1, 1 >> > (N, vals, c, res);
        gpuErrchk(cudaPeekAtLastError());
        gpuErrchk(cudaDeviceSynchronize());
#else
        checkCleary(N, vals, c, res);
#endif

        printf("Devices Synced\n");
        if (res[0]) {
            printf("All still in the table\n");
        }
        else {
            testres = false;
            printf("!---------------------Vals Missing---------------------!\n");
        }

#ifdef GPUCODE
        gpuErrchk(cudaFree(c));
#else
        delete c;
#endif
    }

    if (cb_bool) {
        //Create Table 2
        printf("Creating Bucketed\n");
#ifdef GPUCODE
        ClearyCuckooBucketed<TILESIZE>* b;
        gpuErrchk(cudaMallocManaged((void**)&b, sizeof(ClearyCuckooBucketed<TILESIZE>))); //TODO
        new (b) ClearyCuckooBucketed<TILESIZE>(tablesize, 3);
#else
        ClearyCuckooBucketed* b = new ClearyCuckooBucketed<TILESIZE>(tablesize, 3);
#endif

        printf("Filling Bucketed\n");

#ifdef GPUCODE
        fillClearyCuckooBucketed<TILESIZE> << <numBlocks, numThreads >> > (N, vals, b);
        gpuErrchk(cudaPeekAtLastError());
        gpuErrchk(cudaDeviceSynchronize());

        dupCheckClearyCuckooBucketed<TILESIZE> << <numBlocks, numThreads >> > (N, vals, b);
        gpuErrchk(cudaPeekAtLastError());
        gpuErrchk(cudaDeviceSynchronize());

#else
        std::vector<std::thread> vecThread2(numThreads);

        for (int i = 0; i < numThreads; i++) {
            vecThread2.at(i) = std::thread(fillClearyCuckooBucketed<TILESIZE>, N, vals, b, 0, i, numThreads);
        }

        //Join Threads
        for (int i = 0; i < numThreads; i++) {
            vecThread2.at(i).join();
        }
#endif

        printf("Devices Synced\n");
        b->print();

        //Checking
        res[0] = true;
        printf("Checking Bucketed\n");

#ifdef GPUCODE
        checkClearyCuckooBucketed<TILESIZE> << <numBlocks, numThreads >> > (N, vals, b, res);
        gpuErrchk(cudaPeekAtLastError());
        gpuErrchk(cudaDeviceSynchronize());
#else
        checkClearyCuckooBucketed<TILESIZE>(N, vals, b, res);
#endif

        printf("Devices Synced\n");
        if (res[0]) {
            printf("All still in the table\n");
        }
        else {
            testres = false;
            printf("!---------------------Vals Missing---------------------!\n");
        }

#ifdef GPUCODE
        gpuErrchk(cudaFree(b));
#else
        delete b;
#endif
    }

    if (cuc_bool) {
        //Create Table 2
        printf("Creating Cuckoo\n");
#ifdef GPUCODE
        Cuckoo* cuc;
        gpuErrchk(cudaMallocManaged((void**)&cuc, sizeof(Cuckoo)));
        new (cuc) Cuckoo(tablesize, 4);
#else
        Cuckoo* cuc = new Cuckoo(tablesize, 4);
#endif

        printf("Filling Cuckoo\n");

#ifdef GPUCODE
        fillCuckoo << <1, 1 >> > (N, vals, cuc);
        gpuErrchk(cudaPeekAtLastError());
        gpuErrchk(cudaDeviceSynchronize());

        dupCheckCuckoo << <numBlocks, numThreads >> > (N, vals, cuc);
        gpuErrchk(cudaPeekAtLastError());
        gpuErrchk(cudaDeviceSynchronize());
#else
        std::vector<std::thread> vecThread2(numThreads);

        for (int i = 0; i < numThreads; i++) {
            vecThread2.at(i) = std::thread(fillCuckoo, N, vals, b, 0, i, numThreads);
        }

        //Join Threads
        for (int i = 0; i < numThreads; i++) {
            vecThread2.at(i).join();
        }
#endif

        printf("Devices Synced\n");
        cuc->print();

        //Checking
        res[0] = true;
        printf("Checking Cuckoo\n");

#ifdef GPUCODE
        checkCuckoo << <1, 1 >> > (N, vals, cuc, res);
        gpuErrchk(cudaPeekAtLastError());
        gpuErrchk(cudaDeviceSynchronize());
#else
        checkCuckoo(N, vals, cuc, res);
#endif

        printf("Devices Synced\n");
        if (res[0]) {
            printf("All still in the table\n");
        }
        else {
            testres = false;
            printf("!---------------------Vals Missing---------------------!\n");
        }

#ifdef GPUCODE
        gpuErrchk(cudaFree(cuc));
#else
        delete cuc;
#endif
    }

   

    if (b_bool) {
        //Create Table 2
        printf("Creating Bucketed\n");
#ifdef GPUCODE
        CuckooBucketed<TILESIZE_CBUC >* b;
        gpuErrchk(cudaMallocManaged((void**)&b, sizeof(CuckooBucketed<TILESIZE_CBUC >))); //TODO
        new (b) CuckooBucketed<TILESIZE_CBUC >(tablesize, 3);
#else
        CuckooBucketed* b = new CuckooBucketed<TILESIZE_CBUC >(tablesize, 3);
#endif

        printf("Filling Bucketed\n");

#ifdef GPUCODE
        fillCuckooBucketed<TILESIZE_CBUC> << <numBlocks, numThreads >> > (N, vals, b);
        gpuErrchk(cudaPeekAtLastError());
        gpuErrchk(cudaDeviceSynchronize());

        //printf("After Fill\n");

        //b->print();

        //printf("After Dup\n");

        dupCheckCuckooBucketed<TILESIZE_CBUC> << <numBlocks, numThreads >> > (N, vals, b);
        gpuErrchk(cudaPeekAtLastError());
        gpuErrchk(cudaDeviceSynchronize());

        //b->print();
#else
        std::vector<std::thread> vecThread2(numThreads);

        for (int i = 0; i < numThreads; i++) {
            vecThread2.at(i) = std::thread(fillCuckooBucketed<TILESIZE_CBUC>, N, vals, b, 0, i, numThreads);
        }

        //Join Threads
        for (int i = 0; i < numThreads; i++) {
            vecThread2.at(i).join();
        }
#endif

        printf("Devices Synced\n");
        b->print();

        //Checking
        res[0] = true;
        printf("Checking Bucketed\n");

#ifdef GPUCODE
        checkCuckooBucketed<TILESIZE_CBUC> << <numBlocks, numThreads >> > (N, vals, b, res);
        gpuErrchk(cudaPeekAtLastError());
        gpuErrchk(cudaDeviceSynchronize());
#else
        checkCuckooBucketed<TILESIZE_CBUC>(N, vals, b, res);
#endif

        printf("Devices Synced\n");
        if (res[0]) {
            printf("All still in the table\n");
        }
        else {
            testres = false;
            printf("!---------------------Vals Missing---------------------!\n");
        }

#ifdef GPUCODE
        gpuErrchk(cudaFree(b));
#else
        delete b;
#endif
    }



    //Destroy Vars
#ifdef GPUCODE
    gpuErrchk(cudaFree(res));
#else
    delete res;
#endif

    return testres;
}


GPUHEADER_G
void lockTestDevice(ClearyEntry<addtype, remtype>* T) {
    addtype left = 1;
    addtype right = 4;

    while (true) {
        printf("\tGetting First Lock\n");
        if (!T[left].lock(false)) {
            printf("\tFirst Lock Failed\n");
            continue;
        }

        printf("\tLeft");
        T[left].print();

        printf("\tGetting Second Lock\n");
        if (!T[right].lock(false)) {
            printf("\tSecond Lock Failed\n");
            printf("\tAbort Locking\n");
            T[left].unlock();
            printf("\tUnlocked\n");
            continue;
        }

        printf("\tRight");
        T[left].print();

        printf("\t'Insertion\' Succeeded\n");
        T[left].unlock();
        T[right].unlock();
        printf("\tUnlocked\n");

        printf("\tLeft");
        T[left].print();
        printf("\tRight");
        T[left].print();

        return;
    }

}

void lockTest() {
    int tablesize = 256;
    ClearyEntry<addtype, remtype>* T;
    gpuErrchk(cudaMallocManaged(&T, tablesize * sizeof(ClearyEntry<addtype, remtype>)));

    printf("\tInitializing Entries\n");
    for (int i = 0; i < tablesize; i++) {
        new (&T[i]) ClearyEntry<addtype, remtype>();
    }

    printf("\tStarting Lock Test\n");
#ifdef GPUCODE
    lockTestDevice << <1, 10 >> > (T);
#else

#endif
    gpuErrchk(cudaPeekAtLastError());
    gpuErrchk(cudaDeviceSynchronize());

    gpuErrchk(cudaFree(T));
}

void entryTest() {
    ClearyEntry<addtype, remtype> c{};
    c.setR(351629921636382);
    c.print();
    printf("Entry After R %" PRIl64 "\n", c.getR());
}



void TableTest(int N, int T, int L, bool c, bool cc, bool b, bool cb, bool cuc) {
    bool res = true;

    const int addressSize = N;
    const int testSize = std::pow(2, addressSize);
    //const int testSize = 5;


    //printf("Lock Test\n");
    //lockTest();

    for (int i = 0; i < L; i++) {

        printf("==============================================================================================================\n");
        printf("                              BASIC TEST                              \n");
        printf("==============================================================================================================\n");
        uint64_cu* testset1 = generateRandomSet(testSize, std::pow(2, 29));
        if (!TestFill(testSize, T, addressSize, testset1, c, cc, b, cb, cuc)) {
            res = false;
        }
#ifdef GPUCODE
        gpuErrchk(cudaFree(testset1));
#else
        delete[] testset1;
#endif

        printf("==============================================================================================================\n");
        printf("                            COLLISION TEST                            \n");
        printf("==============================================================================================================\n");
        uint64_cu* testset2 = generateCollidingSet(testSize, addressSize);
        if (!TestFill(testSize, T, addressSize, testset2, c, cc, b, cb, cuc)) {
            res = false;
        }
#ifdef GPUCODE
        gpuErrchk(cudaFree(testset2));
#else
        delete[] testset2;
#endif

        printf("==============================================================================================================\n");
        printf("                            DUP TEST                            \n");
        printf("==============================================================================================================\n");
        uint64_cu* testset3 = generateDuplicateSet(testSize, testSize/2);
        if (!TestFill(testSize, T, addressSize, testset3, c, cc, b, cb, cuc)) {
            res = false;
        }
#ifdef GPUCODE
        gpuErrchk(cudaFree(testset3));
#else
        delete[] testset3;
#endif

        if (!res) {
            printf("TEST FAILED\n");
            break;
        }
        else {
            printf("TEST PASSED\n");
        }
    }

#ifdef REHASH
    printf("==============================================================================================================\n");
    printf("                                          REHASH TEST                                                         \n");

    uint64_cu* testset3 = generateRandomSet(testSize, std::pow(2, 50));
    if (!testRehash(addressSize, testset3)) {
        printf("TEST FAILED\n");
        res = false;
    }
    else {
        printf("TEST PASSED\n");
    }
    printf("==============================================================================================================\n");
    #ifdef GPUCODE
    gpuErrchk(cudaFree(testset3));
    #else
    delete[] testset3;
    #endif
#endif

    if (res) {
        printf("==============================================================================================================\n");
        printf("                                             ALL TESTS PASSED                                                 \n");
        printf("==============================================================================================================\n");
    }
    else {
        printf("==============================================================================================================\n");
        printf("                                             TEST(S) FAILED                                                 \n");
        printf("==============================================================================================================\n");
    }
}

#ifndef GPUCODE
void barrierThread(SpinBarrier* b) {
    printf("%i: Waiting\n", getThreadID());
    b->Wait();
    printf("%i: Entering Phase\n", getThreadID());
    b->Wait();
    printf("%i: Phase Exited\n", getThreadID());
}

void barrierThreadWait(SpinBarrier* b) {
    std::this_thread::sleep_for(std::chrono::seconds(5));
    printf("%i: Waiting\n", getThreadID());
    b->Wait();
    printf("%i: Entering Phase\n", getThreadID());
    std::this_thread::sleep_for(std::chrono::seconds(3));
    b->Wait();
    printf("%i: Phase Exited\n", getThreadID());
}

void BarrierTest(int numThreads) {
    std::vector<std::thread> vecThread(numThreads);
    SpinBarrier barrier(numThreads);


    printf("Starting Threads\n");
    for (int i = 0; i < numThreads; i++) {
        if (i < numThreads - 1) {
            printf("\tStarting Thread %i\n", i);
            vecThread.at(i) = std::thread(barrierThread, &barrier);
        }
        else {
            printf("\tStarting WAIT Thread %i\n", i);
            vecThread.at(i) = std::thread(barrierThreadWait, &barrier);
        }
    }

    //Join Threads
    for (int i = 0; i < numThreads; i++) {
        vecThread.at(i).join();
    }
}
#endif
