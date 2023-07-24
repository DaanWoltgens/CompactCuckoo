#ifndef MAIN
#define MAIN
#include "main.h"
#endif

#ifndef ENTRYINCLUDED
#define ENTRYINCLUDED
#include "TableEntry.h"
#endif
#include <math.h>


template <class ADD, class REM>
class ClearyEntry : public TableEntry <ADD, REM> {

private:
    int Rindex[2] = {  1, 56 };
    int Oindex[2] = { 57, 57 };
    int Vindex[2] = { 58, 58 };
    int Cindex[2] = { 59, 59 };
    int Lindex[2] = { 60, 60 };
    int Aindex[2] = { -1, -1 };

public:
    GPUHEADER
    ClearyEntry(REM R, bool O, bool V, bool C, int A, bool L, bool onDevice = true) noexcept : TableEntry<ADD, REM>() {
        setR(R, onDevice);
        setO(O, onDevice);
        setV(V, onDevice);
        setC(C, onDevice);
        setA(A, onDevice);
        setL(L, onDevice);
        return;
    }

    GPUHEADER
    ClearyEntry (uint64_cu x) noexcept : TableEntry< ADD, REM >(x) {}

    GPUHEADER
    ClearyEntry() noexcept : ClearyEntry(0, false, false, true, 0, false, false) {}

    GPUHEADER
    void exchValue(ClearyEntry* x) {
        //Atomically set this value to the new one
        #ifdef GPUCODE
            uint64_cu old = atomicExch(TableEntry<ADD, REM>::getValPtr(), x->getValue());
        #else
            uint64_cu old = *(TableEntry<ADD, REM>::getValPtr()).exchange(x->getValue());
        #endif
        //Return an entry with prev val
        x->setValue(old);
        return;
    }

    GPUHEADER
    void setR(REM x, bool onDevice = true) {
        TableEntry<ADD, REM>::setBits(Rindex[0], Rindex[1], x, onDevice);
        return;
    }

    GPUHEADER
    REM getR() {
        return (REM)TableEntry<ADD, REM>::getBits(Rindex[0], Rindex[1]);
    }

    GPUHEADER
    void setO(bool x, bool onDevice = true) {
        TableEntry<ADD, REM>::setBits(Oindex[0], Oindex[1], x, onDevice);
        return;
    }

    GPUHEADER
    bool getO() {
        return (bool)TableEntry<ADD, REM>::getBits(Oindex[0], Oindex[1]);
    }

    GPUHEADER
    void setV(bool x, bool onDevice = true) {
        TableEntry<ADD, REM>::setBits(Vindex[0], Vindex[1], x, onDevice);
        return;
    }

    GPUHEADER
    bool getV() {
        return (bool)TableEntry<ADD, REM>::getBits(Vindex[0], Vindex[1]);
    }

    GPUHEADER
    void setC(bool x, bool onDevice = true) {
        TableEntry<ADD, REM>::setBits(Cindex[0], Cindex[1], x, onDevice);
        return;
    }

    GPUHEADER
    bool getC() {
        return (bool)TableEntry<ADD, REM>::getBits(Cindex[0], Cindex[1]);
    }

    GPUHEADER
    void setA(int x, bool onDevice = true) {
        int Amin = -pow(2, (Aindex[1] - Aindex[0]) - 1);
        int Amax = pow(2, (Aindex[1] - Aindex[0]) - 1);

        if (x > Amax-1) {
            x = Amax;
        }
        if (x < Amin) {
            x = Amax;
        }

        TableEntry<ADD, REM>::setBits(Aindex[0], Aindex[1], TableEntry<ADD, REM>::signed_to_unsigned(x, Aindex[1]-Aindex[0]), onDevice);

        return;
    }

    GPUHEADER
    int getA() {
        return TableEntry<ADD, REM>::unsigned_to_signed(TableEntry<ADD, REM>::getBits(Aindex[0], Aindex[1]), Aindex[1] - Aindex[0]);
    }

    GPUHEADER
    void setL(bool x, bool onDevice = true) {
        TableEntry<ADD, REM>::setBits(Lindex[0], Lindex[1], x, onDevice);
        return;
    }

    GPUHEADER
    bool getL() {
        return TableEntry<ADD, REM>::getBits(Lindex[0], Lindex[1]);
    }

    //Need to do with CAS
    GPUHEADER
    bool lock(bool edgeVal) {
#ifdef GPUCODE
        //Store old TableEntry<ADD, REM>::value
        uint64_cu oldval = TableEntry<ADD, REM>::val;
        //Make the new value with lock locked
        uint64_cu newval = TableEntry<ADD, REM>::val;
        TableEntry<ADD, REM>::setBits(Lindex[0], Lindex[1], ((uint64_cu) 1), &newval, false);
#else
        //Store old TableEntry<ADD, REM>::value
        uint64_cu oldval = TableEntry<ADD, REM>::val.load();

        //Make the new value with lock locked
        uint64_cu newval = TableEntry<ADD, REM>::val.load();
        TableEntry<ADD, REM>::setBits(Lindex[0], Lindex[1], 1, &newval, false);
#endif
        //If not on edge of table, and location occupied, then return false
        if (!edgeVal) {
            if (TableEntry<ADD, REM>::getBits(Oindex[0], Oindex[1], &oldval)) {
                return false;
            }
        }

        //If Lockbit was already set return false
        if (TableEntry<ADD, REM>::getBits(Lindex[0], Lindex[1], &oldval)) {
            return false;
        }

        //Swap if the old value hasn't changed
        #ifdef GPUCODE
            uint64_cu res = atomicCAS(TableEntry<ADD, REM>::getValPtr(), oldval, newval);

            if (res == oldval) {
                //If val was oldVal, operation was success
                return true;
            }
            else {
                //Else lock failed
                return false;
            }
        #else
            bool res = std::atomic_compare_exchange_strong(TableEntry<ADD, REM>::getAtomValPtr(), &oldval, newval);
            return res;
        #endif
    }

    GPUHEADER
    bool unlock() {
        //Swap if the old value hasn't changed
        while(true){
#ifdef GPUCODE
            //Store old Value
            uint64_cu oldval = TableEntry<ADD, REM>::val;
            //Make the new value with lock unlocked
            uint64_cu newval = TableEntry<ADD, REM>::val;
            TableEntry<ADD, REM>::setBits(Lindex[0], Lindex[1], ((uint64_cu)0), &newval, false);
#else
            //Store old Value
            uint64_cu oldval = TableEntry<ADD, REM>::val.load();
            //Make the new value with lock unlocked
            uint64_cu newval = TableEntry<ADD, REM>::val.load();
            TableEntry<ADD, REM>::setBits(Lindex[0], Lindex[1], 0, &newval, false);
#endif

          //If Lockbit was already free return
          if (!TableEntry<ADD, REM>::getBits(Lindex[0], Lindex[1], &oldval)) {
              return true;
          }

          #ifdef GPUCODE
            uint64_cu res = atomicCAS(TableEntry<ADD, REM>::getValPtr(), oldval, newval);
            //Check if lockbit is now not set
            if (res == oldval) {
                return true;
            }
          #else
              bool res = std::atomic_compare_exchange_strong(TableEntry<ADD, REM>::getAtomValPtr(), &oldval, newval);
              return res;
          #endif


        }
    }

    //Print the value in an entry
    GPUHEADER
    void print() {
#ifdef GPUCODE
        printf("%" PRIl64  "\n", TableEntry<ADD, REM>::val);
#else
        printf("%" PRIu64  "\n", TableEntry<ADD, REM>::val.load());
#endif
        return;
    }

    //Do a compare and swap between two entries
    GPUHEADER
    uint64_cu compareAndSwap(ClearyEntry<ADD, REM>* comp, ClearyEntry<ADD, REM>* swap) {
        #ifdef GPUCODE
            uint64_cu newval = atomicCAS(TableEntry<ADD, REM>::getValPtr(), (*comp).getValue(), (*swap).getValue());
        #else
        uint64_cu oldval = (*comp).getValue();
        uint64_cu newval = (*swap).getValue();
        bool res = std::atomic_compare_exchange_strong(TableEntry<ADD, REM>::getAtomValPtr(), &oldval, newval);
        newval = oldval;
        #endif
        return newval;
    }

};
