#include <iostream>
#include <random>
#include <algorithm>
#include <fstream>
#include <inttypes.h>
#include <chrono>
#include <vector>
#include <unordered_set>
#include <string>
#include <iomanip>
#include <sstream>
#include <thread>

#include <cuda.h>
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

#include "Test.cu"

#include "Benchmark.cu"

#ifndef TABLES
#define TABLES
#include "ClearyCuckoo.cu"
#include "Cleary.cu"
#include "ClearyCuckooBucketed.cu"
#include "CuckooBucketed.cu"
#include "Cuckoo.cu"
#endif

#ifndef CCENTRY
#define CCENTRY
#include "ClearyCuckooEntry.cu"
#include "ClearyCuckooEntryCompact.cu"
#endif

/*
 *
 *	Helper Functions
 *
 */


//Sources: https://stackoverflow.com/questions/1894886/parsing-a-comma-delimited-stdstring
//         https://stackoverflow.com/questions/11876290/c-fastest-way-to-read-only-last-line-of-text-file
std::vector<std::string>* getLastArgs(std::string filename) {
    std::string line;
    std::ifstream infile;
    infile.open(filename);

    if (infile.is_open())
    {
        char ch;
        infile.seekg(-1, std::ios::end);        // move to location 65
        infile.get(ch);                         // get next char at loc 66
        if (ch == '\n')
        {
            infile.seekg(-2, std::ios::cur);    // move to loc 64 for get() to read loc 65
            infile.seekg(-1, std::ios::cur);    // move to loc 63 to avoid reading loc 65
            infile.get(ch);                     // get the char at loc 64 ('5')
            while (ch != '\n')                   // read each char backward till the next '\n'
            {
                infile.seekg(-2, std::ios::cur);
                infile.get(ch);
            }
            std::string lastLine;
            std::getline(infile, lastLine);
            std::cout << "The last line : " << lastLine << '\n';
            line = lastLine;
        }
        else
            printf("Exception:Check CSV format\n");
            throw std::exception();
    }
    else {
        printf("File failed to open\n");
        return nullptr;
    }

    std::vector<std::string>* vect = new  std::vector<std::string>;
    std::stringstream ss(line);
    std::string field;

    while (getline(ss, field, ',')) {
        vect->push_back(field);
    }

    for (std::size_t i = 0; i < vect->size(); i++){
        std::cout << vect->at(i) << std::endl;
    }

    return vect;
}

void copyArray(uint64_cu* source, uint64_cu* dest, int N) {
    for (int i = 0; i < N; i++) {
        dest[i] = source[i];
    }
}

/*
 *
 * Main Function
 *
 */

int main(int argc, char* argv[])
{
    if (argc == 1) {
        printf("No Arguments Passed\n");
        return 0;
    }

    if (strcmp(argv[1], "test") == 0) {
        if (strcmp(argv[2], "TABLE") == 0) {
            bool c = false;
            bool cc = false;
            bool b = false;
            bool cb = false;
            bool cuc = false;

            if (argc < 6) {
                printf("Not Enough Arguments Passed\n");
                printf("Required: TABLESIZE, NUM_THREADS, SAMPLES, TABlETYPE (c cc ccc b)\n");
                return 0;
            }

            std::string s = argv[6];
            c = (strcmp(argv[6], "c") == 0);
            cc = (strcmp(argv[6], "cc") == 0);
            b = (strcmp(argv[6], "b") == 0);
            cuc = (strcmp(argv[6], "cuc") == 0);
            cb = (strcmp(argv[6], "cb") == 0);

            if (s == "all") {
                c = true;
                cc = true;
                b = true;
                cuc = true;
                cb = true;
            }

            TableTest(std::stoi(argv[3]), std::stoi(argv[4]), std::stoi(argv[5]), c, cc, b, cb, cuc);
        }
        else if (strcmp(argv[2], "NUMGEN") == 0) {
            if (argc < 7) {
                printf("Not Enough Arguments Passed\n");
                printf("Required: , NUM_HASHES, PERCENTAGE, DEPTH\n");
                return 0;
            }

            numGenCollisionTest(std::stoi(argv[3]), std::stoi(argv[4]), std::stoi(argv[5]), std::stoi(argv[6]));
        }
        else if (strcmp(argv[2], "QUEUE") == 0) {
            if (argc < 5) {
                printf("Not Enough Arguments Passed\n");
                printf("Required: MAXSIZE, NUM_THREADS \n");
                return 0;
            }

            queueTest(std::stoi(argv[3]), std::stoi(argv[4]));
        }
        else if (strcmp(argv[2], "BARRIER") == 0) {
            if (argc < 4) {
                printf("Not Enough Arguments Passed\n");
                printf("Required: NUM_THREADS \n");
                return 0;
            }
#ifdef GPUCODE
            printf("Not available on GPU Version");
#else
            BarrierTest(std::stoi(argv[3]));
#endif
        }
        else {
            printf("Possible Tests:\nTABLE, NUMGEN, QUEUE\n");
        }
    }
    else if (strcmp(argv[1], "benchmax") == 0) {
        if (argc < 6) {
            printf("Not Enough Arguments Passed\n");
            printf("Required: TABLE_START, NUM_TABLES, HASH_START, NUM_HASHES, HASH_STEP, NUM_LOOPS, LOOP_STEP, NUM_REHASHES, REHASH_STEP, NUM_SAMPLES\n");
            return 0;
        }
        BenchmarkMaxOccupancy(std::stoi(argv[2]), std::stoi(argv[3]), std::stoi(argv[4]), std::stoi(argv[5]), std::stoi(argv[6]), std::stoi(argv[7]), std::stoi(argv[8]), std::stoi(argv[9]), std::stoi(argv[10]), std::stoi(argv[11]));
    }
    else if (strcmp(argv[1], "benchfill") == 0) {
        if (argc < 10) {
            printf("Not Enough Arguments Passed\n");
            printf("Required: NUM_TABLES start, end, INTERVAL, NUM_SAMPLES, NUM_THREADS, NUM_LOOPS, LOOP_STEP, NUM_HASHES, HASH_STEP, NUM_REHASHES, PERCENTAGE, PERCENTAGE_STEPSIZE, DEPTH\n");
            return 0;
        }
        else if (strcmp(argv[2], "continue") == 0) {
            printf("Continuing from Last Position\n");
            std::vector<std::string>* lastargs = getLastArgs("results/benchfill.csv");

            BenchmarkGeneralFilling(std::stoi(argv[3]), std::stoi(argv[4]), std::stoi(argv[5]), std::stoi(argv[6]), std::stoi(argv[7]), std::stoi(argv[8]), std::stoi(argv[9]), std::stoi(argv[9]), std::stoi(argv[10]), std::stoi(argv[11]), std::stoi(argv[12]), std::stoi(argv[13]), std::stoi(argv[14]), lastargs);
            delete lastargs;
            return 0;
        }

        BenchmarkGeneralFilling(std::stoi(argv[2]), std::stoi(argv[3]), std::stoi(argv[4]), std::stoi(argv[5]), std::stoi(argv[6]), std::stoi(argv[7]), std::stoi(argv[8]), std::stoi(argv[9]), std::stoi(argv[10]), std::stoi(argv[11]), std::stoi(argv[12]), std::stoi(argv[13]), std::stoi(argv[14]));
    }

    else if (strcmp(argv[1], "benchmax2") == 0) {
        if (argc < 6) {
            printf("Not Enough Arguments Passed\n");
            printf("Required: TABLE_START, NUM_TABLES, HASH_START, NUM_HASHES, HASH_STEP, NUM_LOOPS, LOOP_STEP, NUM_SAMPLES\n");
            return 0;
        }
        BenchmarkMaxOccupancyBucket(std::stoi(argv[2]), std::stoi(argv[3]), std::stoi(argv[4]), std::stoi(argv[5]), std::stoi(argv[6]), std::stoi(argv[7]), std::stoi(argv[8]), std::stoi(argv[9]));
    }

    else if (strcmp(argv[1], "benchspeed") == 0) {
        if (argc < 10) {
            printf("Not Enough Arguments Passed\n");
            printf("Required: NUM_TABLES_start,  NUM_TABLES, INTERVAL, NUM_SAMPLES, NUM_THREADS, PERCENTAGE, P_STEPSIZE, DEPTH ,(CLEARY) (SRC)\n");
            return 0;
        }

        bool cleary = true;

        if (argc >= 11) {
            cleary = !(strcmp(argv[10], "nocleary") == 0);
        }

        std::string src = "";
        if (argc >= 12) {
            src = argv[11];
        }

        BenchmarkSpeed(std::stoi(argv[2]), std::stoi(argv[3]), std::stoi(argv[4]), std::stoi(argv[5]), std::stoi(argv[6]), std::stoi(argv[7]), std::stoi(argv[8]), std::stoi(argv[9]), cleary, src);
    }

    else if (strcmp(argv[1], "readInput") == 0) {
        uint64_cu* list = readCSV(argv[2]);

        printf("Elmt %i: %" PRIl64 "\n", std::stoi(argv[3]), list[std::stoi(argv[3])]);

#ifdef GPUCODE
        gpuErrchk(cudaFree(list));
#else
        //printf("Deleting\n");
        delete[] list;
#endif
    }

    else if (strcmp(argv[1], "debug") == 0) {
        ClearyCuckooEntryCompact<uint32_t, uint64_t> test = ClearyCuckooEntryCompact<uint32_t, uint64_t>(32);
        printf("Pre Insertion\n");
        test.print();
        test.setR(std::stoi(argv[2]),1, false);
        printf("R Set to %" PRIu64 "\n", test.getR(1));
        test.print();
        test.setR(std::stoi(argv[3]), 0, false);
        printf("R Set to %" PRIu64 "\n", test.getR(0));
        test.print();
    }

    else if (strcmp(argv[1], "debug2") == 0) {
        uint64_cu x = std::stoll(argv[2]);
        int hashsize = std::stoll(argv[3]);
        

        for (int i = 0; i < 10; i++) {
            uint64_cu h = RHASH(hashsize, i, x);
            printf("Orignal: %" PRIl64 " HASHED: %" PRIl64 " INVERSE: %" PRIl64 "\n", x, h, RHASH_INVERSE(hashsize, i, h));
        }
    }


    else if (strcmp(argv[1], "gen") == 0) {
        for (int i = 0; i < 64; i++) {
            int val = i;
            printf("const uint64_cu VAL%i = %i %% DATASIZE;\nconst uint64_cu VAL%iC = DATASIZE - VAL%i;\n\n", val, val, val, val);
        }
    }


    return 0;
}
