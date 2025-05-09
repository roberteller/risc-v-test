// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See Vooo_execution_unit_tb.h for the primary calling header

#ifndef VERILATED_VOOO_EXECUTION_UNIT_TB___024UNIT_H_
#define VERILATED_VOOO_EXECUTION_UNIT_TB___024UNIT_H_  // guard

#include "verilated.h"
#include "verilated_cov.h"
#include "verilated_timing.h"


class Vooo_execution_unit_tb__Syms;

class alignas(VL_CACHE_LINE_BYTES) Vooo_execution_unit_tb___024unit final : public VerilatedModule {
  public:

    // DESIGN SPECIFIC STATE
    CData/*0:0*/ __VmonitorOff;
    QData/*63:0*/ __VmonitorNum;

    // INTERNAL VARIABLES
    Vooo_execution_unit_tb__Syms* const vlSymsp;

    // CONSTRUCTORS
    Vooo_execution_unit_tb___024unit(Vooo_execution_unit_tb__Syms* symsp, const char* v__name);
    ~Vooo_execution_unit_tb___024unit();
    VL_UNCOPYABLE(Vooo_execution_unit_tb___024unit);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
    void __vlCoverInsert(uint32_t* countp, bool enable, const char* filenamep, int lineno, int column,
        const char* hierp, const char* pagep, const char* commentp, const char* linescovp);
};


#endif  // guard
