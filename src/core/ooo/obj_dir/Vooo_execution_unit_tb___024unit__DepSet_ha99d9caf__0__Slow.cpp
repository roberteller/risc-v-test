// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vooo_execution_unit_tb.h for the primary calling header

#include "Vooo_execution_unit_tb__pch.h"
#include "Vooo_execution_unit_tb___024unit.h"

VL_ATTR_COLD void Vooo_execution_unit_tb___024unit___ctor_var_reset(Vooo_execution_unit_tb___024unit* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+  Vooo_execution_unit_tb___024unit___ctor_var_reset\n"); );
    Vooo_execution_unit_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelf->__VmonitorNum = VL_RAND_RESET_Q(64);
    vlSelf->__VmonitorOff = VL_RAND_RESET_I(1);
}

VL_ATTR_COLD void Vooo_execution_unit_tb___024unit___configure_coverage(Vooo_execution_unit_tb___024unit* vlSelf, bool first) {
    VL_DEBUG_IF(VL_DBG_MSGF("+  Vooo_execution_unit_tb___024unit___configure_coverage\n"); );
    Vooo_execution_unit_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    (void)first;  // Prevent unused variable warning
}
