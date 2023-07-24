#include <random>
#include <unordered_set>
#include <cuda.h>
#include <curand_kernel.h>
#include <inttypes.h>

# define PRIl64		"llu"

#ifndef MAIN
#define MAIN
#include "main.h"
#endif

#ifndef HASHINCLUDED
#define HASHINCLUDED
#include "hashfunctions.cu"
#endif

std::random_device rd_ng;
std::mt19937_64 e2_ng(rd_ng());

__host__ __device__
bool contains(uint64_cu* arr, uint64_cu val, int index) {
    for (int i = 0; i < index; i++) {
        if (val == arr[i]) {
            return true;
        }
    }
    return false;
}

void shuffle(uint64_cu* arr, int len)
{
    for (auto i = 0; i < len; i++) {
        std::uniform_int_distribution<int> d(i, len-1);
        int loc= d(rd_ng);
        std::swap(arr[i], arr[loc]);
    }
}



uint64_cu* generateRandomSet(int size, long long int max=std::pow(2, DATASIZE)) {
    //Random Number generator
    std::uniform_int_distribution<long long int> dist(0, std::llround(max));

#ifdef GPUCODE
    uint64_cu* res;
    gpuErrchk(cudaMallocManaged(&res, size * sizeof(uint64_cu)));
#else
    uint64_cu* res = new uint64_cu[size];
#endif
    std::unordered_set<uint64_cu> insertedSet;

    int i = 0;
    while ((int) insertedSet.size() != size) {
        uint64_cu rand = dist(e2_ng);
        if (!(insertedSet.find(rand) != insertedSet.end())) {
            insertedSet.insert(rand);
            res[i] = rand;
            i++;
        }
    }
    return res;
}

uint64_cu* generateDuplicateSet(int size, int numDups) {

#ifdef GPUCODE
    uint64_cu* res;
    gpuErrchk(cudaMallocManaged(&res, size * sizeof(uint64_cu)));
#else
    uint64_cu* res = new uint64_cu[size];
#endif

    int dupCounter = 0;
    int val = 0;
    for(int i=0; i< size; i++){
        res[i] = val;
        //Every few steps iterate value
        if (dupCounter++ >= numDups) {
            val++;
            dupCounter = 0;
        }
    }
    return res;
}

uint64_cu* generateNormalSet(int size) {
    //Random Number generator
    std::normal_distribution<> dist{std::pow(2, DATASIZE)/2 , 1000 };

#ifdef GPUCODE
    uint64_cu* res;
    gpuErrchk(cudaMallocManaged(&res, size * sizeof(uint64_cu)));
#else
    uint64_cu* res = new uint64_cu[size];
#endif
    std::unordered_set<uint64_cu> insertedSet;

    int i = 0;
    while ((int) insertedSet.size() != size) {
        uint64_cu rand = std::round(dist(e2_ng));
        if (!(insertedSet.find(rand) != insertedSet.end())) {
            insertedSet.insert(rand);
            res[i] = rand;
            i++;
        }
    }
    return res;
}

__global__
void setup_kernel(int seed, curandState* state) {
    int idx = threadIdx.x + blockDim.x * blockIdx.x;
    curand_init(seed, idx, 0, &state[idx]);
}

__global__
void firstPassGenSet(curandState* state, uint64_cu* res, int N, int setsize, int begin) {
    int index = blockIdx.x * blockDim.x + threadIdx.x;
    int stride = blockDim.x;

    int idx = threadIdx.x + blockDim.x * blockIdx.x;
    curandState localState = state[idx];

    int maxVal = setsize + begin < N ? setsize + begin : N;

    for (int i = index + begin; i < maxVal; i += stride) {
        float myrandf = curand_uniform(&localState);
        uint64_cu newval = myrandf * std::llround(std::pow(2, DATASIZE));

        res[i] = newval;
    }
    return;
}

__global__
void secondPassGenSet(curandState* state, uint64_cu* res, int N, int setsize, int begin) {

    int index = blockIdx.x * blockDim.x + threadIdx.x;
    int stride = blockDim.x;

    int idx = threadIdx.x + blockDim.x * blockIdx.x;
    curandState localState = state[idx];

    int maxVal = setsize + begin < N ? setsize + begin : N;

    for (int i = index + begin; i < maxVal; i += stride) {
        if (contains(res, res[i], i)) {
            while (true) {
                float myrandf = curand_uniform(&localState);
                uint64_cu newval = myrandf * std::llround(std::pow(2, DATASIZE));
                //Check if new in table
                if (!contains(res, newval, i)) {
                    res[i] = newval;
                    break;
                }
            }
        }
    }
    return;
}

uint64_cu* generateTestSetParallel(int size, int NUM_THREADS) {

    //Init States
    curandState* states;
    gpuErrchk(cudaMallocManaged(&states, sizeof(curandState) * NUM_THREADS));

    int setsize = 128;
    int split = (int)std::ceil((float)size / (float)setsize);
    split = split == 0 ? 1 : split;

    //Time For Seeding the Randomness
    const auto p1 = std::chrono::system_clock::now();
    setup_kernel << < 1, NUM_THREADS >> > (std::chrono::duration_cast<std::chrono::microseconds>(p1.time_since_epoch()).count(), states);
    gpuErrchk(cudaPeekAtLastError());
    gpuErrchk(cudaDeviceSynchronize());

    //Result array
    uint64_cu* res;
    gpuErrchk(cudaMallocManaged(&res, size * sizeof(uint64_cu)));

    //Fill With Values
    for (int i = 0; i < split; i++) {
        firstPassGenSet << <1, NUM_THREADS >> > (states, res, size, setsize, i * setsize);
        gpuErrchk(cudaPeekAtLastError());
        gpuErrchk(cudaDeviceSynchronize());
    }

    return res;

}

uint64_cu* generateCollidingSet(int size, int N) {

#ifdef GPUCODE
    uint64_cu* res;
    gpuErrchk(cudaMallocManaged(&res, size * sizeof(uint64_cu)));
#else
    uint64_cu* res = new uint64_cu[size];
#endif

    uint64_cu add = 7;

    for (int n = 0; n < (int)size / 2; ++n) {
        uint64_cu num = reformKey(add, n, N);
        uint64_cu nval = RHASH_INVERSE(HFSIZE, 0, num);
        if (!contains(res, nval, n)) {
            res[n] = nval;
        }
        else {
            //Redo the step
            n--;
        }
    }

    add = 10;

    for (int n = ((int)size / 2); n < size; ++n) {
        uint64_cu num = reformKey(add, n, N);
        uint64_cu nval = RHASH_INVERSE(HFSIZE, 0, num);
        if (!contains(res, nval, n)) {
            res[n] = nval;
        }
        else {
            //Redo the step
            n--;
        }
    }

    return res;
}

uint64_cu* generateCollisionSet(int N, int AS, int H, int* hs, int percentage, int depth) {
    std::uniform_int_distribution<long long int> dist64(0, std::llround(std::pow(2, DATASIZE)));
    std::uniform_int_distribution<long long int> dist16(0, std::llround(std::pow(2, 16)));

    int maxPercentage = std::floor(100.0 / ((float)H));
    if (percentage > maxPercentage) {
        printf("Error: Percentage too Large - 1/H being used instead");
        percentage = maxPercentage;
    }

#ifdef GPUCODE
    uint64_cu* res;
    gpuErrchk(cudaMallocManaged(&res, N * sizeof(uint64_cu)));
#else
    uint64_cu* res = new uint64_cu[N];
#endif
    std::unordered_set<uint64_cu> insertedSet;

    //Inserted Counter
    int n = 0;

    //Generate the Clean set first
    int fullSet = (int)(((float)N * (float)percentage) / 100.0);
    int halfSet = std::floor(((float)N * (float)percentage) / (100.0 * ((float)depth + 1)));

    for (int i = 0; i < halfSet*H; i++) {
        uint64_cu rand = dist64(e2_ng);
        if (!(insertedSet.find(rand) != insertedSet.end())) {
            insertedSet.insert(rand);
            res[i] = rand;
            n++;
        }
        else {
            i--;
        }
    }

    if (percentage != 0) {
        for (int h = 0; h < H; h++) {
            //Generate Half the Set First
            int start = n;

            int hash = hs[h];
            int outerLoop = std::floor((float)(fullSet - halfSet) / (float)depth);

            std::uniform_int_distribution<long long int> index(0, start);
            //printf("OuterLoop: %i\n", outerLoop);
            //Generate the Second value set
            for (int i = 0; i < fullSet - halfSet; i++) {
                uint64_cu add = 0;
                if (i % depth == 0) {
                    //Select a random index and get the address
                    int r = index(e2_ng);
                    uint64_cu hashed = RHASH(HFSIZE, hash, res[r]);
                    add = getAdd(hashed, AS);
                }

                //Create a new value
                uint64_cu newVal = reformKey(add, dist16(e2_ng), AS);
                uint64_cu toInsert = RHASH_INVERSE(HFSIZE, hash, newVal);

                //Check if value exists
                if (!(insertedSet.find(toInsert) != insertedSet.end())) {
                    insertedSet.insert(toInsert);
                    res[n] = toInsert;
                    n++;
                }
                else {
                    i--;
                }
            }
        }
    }

    for (int i = n; i < N; i++) {
        uint64_cu rand = dist64(e2_ng);
        if (!(insertedSet.find(rand) != insertedSet.end())) {
            insertedSet.insert(rand);
            res[i] = rand;
        }
        else {
            i--;
        }
    }

    shuffle(res, N);

    return res;
}

//Read CSV
uint64_cu* readCSV(std::string filename, int* setsize = nullptr) {
    std::vector<uint64_cu> vec;
    printf("Reading CSV\n");
    std::ifstream file;

    // Helper vars
    std::string line, colname;
    uint64_cu val;


    file.open(filename);
    if (!file.is_open()) {
        printf("\tFile Failed to Open\n");
        return nullptr;
    }
    printf("\tFile Opened\n");

    // Read data, line by line
    while (std::getline(file, line))
    {
        // Create a stringstream of the current line
        std::stringstream ss(line);

        // Extract each integer
        while (ss >> val) {

            // Add the current integer to the 'colIdx' column's values vector
            vec.push_back(val);

            // If the next token is a comma, ignore it and move on
            if (ss.peek() == ',') { ss.ignore(); };
        }
    }

    file.close();

    int size = vec.size();
    printf("Loaded Size %i\n", size);
    if (setsize != nullptr) {
        (*setsize) = size;
    }

#ifdef GPUCODE
    uint64_cu* res;
    gpuErrchk(cudaMallocManaged(&res, size * sizeof(uint64_cu)));
#else
    uint64_cu* res = new uint64_cu[size];
#endif

    int j = 0;
    printf("\tSample:");
    for (uint64_cu i : vec) {
        res[j++] = i;
        if (j < 10) {
            printf("%llu, ", i);
        }
    }
    printf("...\n");

   
    return res;

}

uint64_cu* moduloList(uint64_cu* ls, int size, uint64_t mod) {
#ifdef GPUCODE
    uint64_cu* res;
    gpuErrchk(cudaMallocManaged(&res, size * sizeof(uint64_cu)));
#else
    uint64_cu* res = new uint64_cu[size];
#endif

    for (int i = 0; i < size; i++) {
        res[i] = ls[i] % mod;
    }

    return res;
}