// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Symbol table implementation internals

#include "Vooo_execution_unit_tb__pch.h"
#include "Vooo_execution_unit_tb.h"
#include "Vooo_execution_unit_tb___024root.h"

// FUNCTIONS
Vooo_execution_unit_tb__Syms::~Vooo_execution_unit_tb__Syms()
{
}

Vooo_execution_unit_tb__Syms::Vooo_execution_unit_tb__Syms(VerilatedContext* contextp, const char* namep, Vooo_execution_unit_tb* modelp)
    : VerilatedSyms{contextp}
    // Setup internal state of the Syms class
    , __Vm_modelp{modelp}
    // Setup module instances
    , TOP{this, namep}
{
        // Check resources
        Verilated::stackCheck(2298);
    // Configure time unit / time precision
    _vm_contextp__->timeunit(-12);
    _vm_contextp__->timeprecision(-12);
    // Setup each module's pointers to their submodules
    // Setup each module's pointer back to symbol table (for public functions)
    TOP.__Vconfigure(true);
}
