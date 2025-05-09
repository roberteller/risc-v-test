// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Symbol table internal header
//
// Internal details; most calling programs do not need this header,
// unless using verilator public meta comments.

#ifndef VERILATED_VOOO_EXECUTION_UNIT_TB__SYMS_H_
#define VERILATED_VOOO_EXECUTION_UNIT_TB__SYMS_H_  // guard

#include "verilated.h"

// INCLUDE MODEL CLASS

#include "Vooo_execution_unit_tb.h"

// INCLUDE MODULE CLASSES
#include "Vooo_execution_unit_tb___024root.h"

// SYMS CLASS (contains all model state)
class alignas(VL_CACHE_LINE_BYTES)Vooo_execution_unit_tb__Syms final : public VerilatedSyms {
  public:
    // INTERNAL STATE
    Vooo_execution_unit_tb* const __Vm_modelp;
    bool __Vm_activity = false;  ///< Used by trace routines to determine change occurred
    uint32_t __Vm_baseCode = 0;  ///< Used by trace routines when tracing multiple models
    VlDeleter __Vm_deleter;
    bool __Vm_didInit = false;

    // MODULE INSTANCE STATE
    Vooo_execution_unit_tb___024root TOP;

    // COVERAGE
    uint32_t __Vcoverage[970];

    // CONSTRUCTORS
    Vooo_execution_unit_tb__Syms(VerilatedContext* contextp, const char* namep, Vooo_execution_unit_tb* modelp);
    ~Vooo_execution_unit_tb__Syms();

    // METHODS
    const char* name() { return TOP.name(); }
};

#endif  // guard
