// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vooo_execution_unit_tb.h for the primary calling header

#include "Vooo_execution_unit_tb__pch.h"
#include "Vooo_execution_unit_tb__Syms.h"
#include "Vooo_execution_unit_tb___024root.h"

void Vooo_execution_unit_tb___024root___ctor_var_reset(Vooo_execution_unit_tb___024root* vlSelf);

Vooo_execution_unit_tb___024root::Vooo_execution_unit_tb___024root(Vooo_execution_unit_tb__Syms* symsp, const char* v__name)
    : VerilatedModule{v__name}
    , __VdlySched{*symsp->_vm_contextp__}
    , vlSymsp{symsp}
 {
    // Reset structure values
    Vooo_execution_unit_tb___024root___ctor_var_reset(this);
}

void Vooo_execution_unit_tb___024root___configure_coverage(Vooo_execution_unit_tb___024root* vlSelf, bool first);

void Vooo_execution_unit_tb___024root::__Vconfigure(bool first) {
    (void)first;  // Prevent unused variable warning
    Vooo_execution_unit_tb___024root___configure_coverage(this, first);
}

Vooo_execution_unit_tb___024root::~Vooo_execution_unit_tb___024root() {
}

// Coverage
void Vooo_execution_unit_tb___024root::__vlCoverInsert(uint32_t* countp, bool enable, const char* filenamep, int lineno, int column,
    const char* hierp, const char* pagep, const char* commentp, const char* linescovp) {
    uint32_t* count32p = countp;
    static uint32_t fake_zero_count = 0;
    std::string fullhier = std::string{VerilatedModule::name()} + hierp;
    if (!fullhier.empty() && fullhier[0] == '.') fullhier = fullhier.substr(1);
    if (!enable) count32p = &fake_zero_count;
    *count32p = 0;
    VL_COVER_INSERT(vlSymsp->_vm_contextp__->coveragep(), VerilatedModule::name(), count32p,  "filename",filenamep,  "lineno",lineno,  "column",column,
        "hier",fullhier,  "page",pagep,  "comment",commentp,  (linescovp[0] ? "linescov" : ""), linescovp);
}
