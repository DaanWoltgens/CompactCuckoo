#ifndef MAIN
#define MAIN
#include "main.h"
#endif

#ifndef ENTRYINCLUDED
#define ENTRYINCLUDED
#include "TableEntry.h"
#endif

//#include <inttypes.h>


template <class ADD, class REM>
class ClearyCuckooEntryCompact : public TableEntry <ADD, REM> {

private:
    int bucketSize;
    int valSize;

    int Rindex[2] = { 1, 4 };
    int Hindex[2] = { 5, 6 };
    int Oindex[2] = { 7, 7 };

    GPUHEADER
    int indexCalc(int locIndex, int valIndex) {
        return locIndex * valSize + valIndex;
    }

    GPUHEADER
    void setIndices(int valSize) {
        Rindex[0] = 1;
        Rindex[1] = valSize - 4;

        Hindex[0] = valSize - 3;
        Hindex[1] = valSize - 2;

        Oindex[0] = valSize - 1;
        Oindex[1] = valSize - 1;

        //printf("R:%i H:%i O:%i\n", Rindex[1], Hindex[1], Oindex[1]);
    }

public:

    GPUHEADER
    ClearyCuckooEntryCompact(REM R, int H, bool O, int BUCKET_SIZE, bool onDevice = true) noexcept : bucketSize(BUCKET_SIZE)  {
        valSize = ENTRYSIZE / bucketSize;
        setIndices(valSize);

        TableEntry<ADD, REM>::val = 0;
        for (int i = 0; i < ((int)(ENTRYSIZE / valSize)); i++) {
            setR(R, i, onDevice);
            setH(H, i, onDevice);
            setO(O, i, onDevice);
        }
        return;
    }

    GPUHEADER
    ClearyCuckooEntryCompact(REM R, int H, bool O, int BUCKET_SIZE, int locIndex, bool onDevice = true) noexcept : bucketSize(BUCKET_SIZE) {
        //printf("CompactEntryConstructor\n");
        valSize = ENTRYSIZE / bucketSize;
        setIndices(valSize);

        //printf("SetVal\n");
        TableEntry<ADD, REM>::val = 0;
        //printf("SetOtherStuff\n");
        setR(R, locIndex, onDevice);
        setH(H, locIndex, onDevice);
        setO(O, locIndex, onDevice);
        //printf("Constructor Done\n");
        return;
    }

    GPUHEADER
        ClearyCuckooEntryCompact(int BUCKET_SIZE, uint64_cu VAL) noexcept : bucketSize(BUCKET_SIZE) {
        valSize = ENTRYSIZE / bucketSize;
        setIndices(valSize);

        TableEntry<ADD, REM>::val = VAL;
        return;
    }

    GPUHEADER
    ClearyCuckooEntryCompact(int BUCKET_SIZE) noexcept : ClearyCuckooEntryCompact(BUCKET_SIZE, 0)  { }

    GPUHEADER
        ClearyCuckooEntryCompact() noexcept : valSize(ENTRYSIZE) { }

    GPUHEADER_D
        void tableSwap(ClearyCuckooEntryCompact<ADD, REM>* x, int locIndexTable, int locIndexFrom) {
        //printf("%i: \t\t\t\t\t\tTABLESWAP: swap %i %i\n", getThreadID(), locIndexTable, locIndexFrom);
        //Atomically set this TableEntry<ADD, REM>::value to the new one
        while (true) {
            //Store oldval
            uint64_cu old_val = TableEntry<ADD, REM>::getValue();

            //Get the subvalues that need to be swapped
            uint64_cu table = old_val;
            uint64_cu tableSubVal = getSubVal(locIndexTable, &table);
            //printf("%i: \t\t\t\t\t\ttableSubVal: %" PRIu64 " \n", getThreadID(), tableSubVal);
            uint64_cu temp = x->getValue();
            //printf("%i: \t\t\t\t\t\ttemp: %" PRIu64 " \n", getThreadID(), temp);
            uint64_cu newSubVal = getSubVal(locIndexFrom, &temp);
            //printf("%i: \t\t\t\t\t\tnewSubVal: %" PRIu64 " \n", getThreadID(), newSubVal);

            //Insert the new value in the table entry copy
            uint64_cu newTable = setValBits(indexCalc(locIndexTable, Rindex[0]), indexCalc(locIndexTable, Oindex[1]), newSubVal, &table);
            //printf("%i: \t\t\t\t\t\tnewTable: %" PRIu64 " \n", getThreadID(), newTable);

            //Atomically exchange new version
            uint64_cu res = atomicCAS(TableEntry<ADD,REM>::getValPtr(), old_val, newTable);

            //Make sure the value hasn't changed in the meantime
            if (res == old_val) {
                //printf("%i: \t\t\t\t\t\tSWAP DONE: Table-%" PRIu64 " Old-%" PRIu64 " OldSubVal-%" PRIu64 " \n", getThreadID(), TableEntry<ADD, REM>::getValue(), res, tableSubVal);
                //Put the from entry into the subLoc in the to entry
                setSubVal(tableSubVal, locIndexFrom, x->getValPtr());
                return;
            }
        }
        return;
    }


    GPUHEADER
    void setR(REM x, int locIndex,  bool onDevice=true) {
        //printf("\tSet R %" PRIu64" %i %i\n", x, locIndex, onDevice);
        //printf("\t\tIndex1:%i Index2:%i\n", indexCalc(locIndex, Rindex[0]), indexCalc(locIndex, Rindex[1]));
        TableEntry<ADD, REM>::setBits(indexCalc(locIndex, Rindex[0]), indexCalc(locIndex, Rindex[1]), x, onDevice);
        //printf("\tR Set: %" PRIu64 "\n", TableEntry<ADD, REM>::getValue());
        return;

    }

    GPUHEADER
    REM getR(int locIndex) {
        return (REM)TableEntry<ADD, REM>::getBits(indexCalc(locIndex, Rindex[0]), indexCalc(locIndex, Rindex[1]));
    }

    GPUHEADER
    void setH(int x, int locIndex, bool onDevice = true) {
        //printf("\tSet H %i %i %i\n", x, locIndex, onDevice);
        TableEntry<ADD, REM>::setBits(indexCalc(locIndex, Hindex[0]), indexCalc(locIndex, Hindex[1]), x, onDevice);
        //printf("\tH Set: %" PRIu64 "\n", TableEntry<ADD, REM>::getValue());
        return;
    }

    GPUHEADER
    int getH( int locIndex) {
        return (int) TableEntry<ADD, REM>::getBits(indexCalc(locIndex, Hindex[0]), indexCalc(locIndex, Hindex[1]));
    }

    GPUHEADER
    void setO(bool x, int locIndex, bool onDevice = true) {
        //printf("\tSet O %i %i %i\n", x, locIndex, onDevice);
        TableEntry<ADD, REM>::setBits(indexCalc(locIndex, Oindex[0]), indexCalc(locIndex, Oindex[1]), x, onDevice);
        //printf("\tO Set: %" PRIu64 "\n", TableEntry<ADD, REM>::getValue());
        return;
    }

    GPUHEADER
    bool getO( int locIndex) {
        return (bool)TableEntry<ADD, REM>::getBits(indexCalc(locIndex, Oindex[0]), indexCalc(locIndex, Oindex[1]));
    }

    GPUHEADER
        uint64_cu getSubVal(int locIndex, uint64_cu* loc) {
        //printf("\t\t\t\t\t\t\tGet SubVal %i %i (%i %i)\n", indexCalc(locIndex, Rindex[0]), indexCalc(locIndex, Oindex[1]), Rindex[0], Oindex[1]);
        return (uint64_cu)TableEntry<ADD, REM>::getBits(indexCalc(locIndex, Rindex[0]), indexCalc(locIndex, Oindex[1]), loc);
    }

    GPUHEADER
        void setSubVal(uint64_cu x, int locIndex, uint64_cu* loc, bool onDevice = true) {
        TableEntry<ADD, REM>::setBits(indexCalc(locIndex, Rindex[0]), indexCalc(locIndex, Oindex[1]), x, loc, onDevice);
    }

    GPUHEADER
    void clear() {
        TableEntry<ADD, REM>::val = 0;
    }

    GPUHEADER
    void print() {
#ifdef GPUCODE
        printf("%" PRIl64  "\n", TableEntry<ADD, REM>::getValue());
#else
        //printf("%" PRIu64  "\n", TableEntry<ADD, REM>::val.load());
#endif
        return;
    }

};
