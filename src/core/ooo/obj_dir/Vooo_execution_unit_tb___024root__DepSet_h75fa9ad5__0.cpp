// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vooo_execution_unit_tb.h for the primary calling header

#include "Vooo_execution_unit_tb__pch.h"
#include "Vooo_execution_unit_tb___024root.h"

VL_ATTR_COLD void Vooo_execution_unit_tb___024root___eval_initial__TOP(Vooo_execution_unit_tb___024root* vlSelf);
VlCoroutine Vooo_execution_unit_tb___024root___eval_initial__TOP__Vtiming__0(Vooo_execution_unit_tb___024root* vlSelf);
VlCoroutine Vooo_execution_unit_tb___024root___eval_initial__TOP__Vtiming__1(Vooo_execution_unit_tb___024root* vlSelf);
VlCoroutine Vooo_execution_unit_tb___024root___eval_initial__TOP__Vtiming__2(Vooo_execution_unit_tb___024root* vlSelf);

void Vooo_execution_unit_tb___024root___eval_initial(Vooo_execution_unit_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vooo_execution_unit_tb___024root___eval_initial\n"); );
    Vooo_execution_unit_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    Vooo_execution_unit_tb___024root___eval_initial__TOP(vlSelf);
    vlSelfRef.__Vm_traceActivity[1U] = 1U;
    Vooo_execution_unit_tb___024root___eval_initial__TOP__Vtiming__0(vlSelf);
    Vooo_execution_unit_tb___024root___eval_initial__TOP__Vtiming__1(vlSelf);
    Vooo_execution_unit_tb___024root___eval_initial__TOP__Vtiming__2(vlSelf);
}

void Vooo_execution_unit_tb___024root___act_sequent__TOP__0(Vooo_execution_unit_tb___024root* vlSelf);
void Vooo_execution_unit_tb___024root___act_comb__TOP__0(Vooo_execution_unit_tb___024root* vlSelf);

void Vooo_execution_unit_tb___024root___eval_act(Vooo_execution_unit_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vooo_execution_unit_tb___024root___eval_act\n"); );
    Vooo_execution_unit_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((4ULL & vlSelfRef.__VactTriggered.word(0U))) {
        Vooo_execution_unit_tb___024root___act_sequent__TOP__0(vlSelf);
    }
    if ((0xdULL & vlSelfRef.__VactTriggered.word(0U))) {
        Vooo_execution_unit_tb___024root___act_comb__TOP__0(vlSelf);
        vlSelfRef.__Vm_traceActivity[3U] = 1U;
    }
}

void Vooo_execution_unit_tb___024root___nba_sequent__TOP__0(Vooo_execution_unit_tb___024root* vlSelf);
void Vooo_execution_unit_tb___024root___nba_sequent__TOP__1(Vooo_execution_unit_tb___024root* vlSelf);
void Vooo_execution_unit_tb___024root___nba_comb__TOP__0(Vooo_execution_unit_tb___024root* vlSelf);
void Vooo_execution_unit_tb___024root___nba_comb__TOP__1(Vooo_execution_unit_tb___024root* vlSelf);
void Vooo_execution_unit_tb___024root___nba_sequent__TOP__3(Vooo_execution_unit_tb___024root* vlSelf);

void Vooo_execution_unit_tb___024root___eval_nba(Vooo_execution_unit_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vooo_execution_unit_tb___024root___eval_nba\n"); );
    Vooo_execution_unit_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((3ULL & vlSelfRef.__VnbaTriggered.word(0U))) {
        Vooo_execution_unit_tb___024root___nba_sequent__TOP__0(vlSelf);
        vlSelfRef.__Vm_traceActivity[4U] = 1U;
    }
    if ((1ULL & vlSelfRef.__VnbaTriggered.word(0U))) {
        Vooo_execution_unit_tb___024root___nba_sequent__TOP__1(vlSelf);
    }
    if ((4ULL & vlSelfRef.__VnbaTriggered.word(0U))) {
        Vooo_execution_unit_tb___024root___act_sequent__TOP__0(vlSelf);
    }
    if ((0xdULL & vlSelfRef.__VnbaTriggered.word(0U))) {
        Vooo_execution_unit_tb___024root___nba_comb__TOP__0(vlSelf);
        vlSelfRef.__Vm_traceActivity[5U] = 1U;
    }
    if ((0xfULL & vlSelfRef.__VnbaTriggered.word(0U))) {
        Vooo_execution_unit_tb___024root___nba_comb__TOP__1(vlSelf);
    }
    if ((3ULL & vlSelfRef.__VnbaTriggered.word(0U))) {
        Vooo_execution_unit_tb___024root___nba_sequent__TOP__3(vlSelf);
        vlSelfRef.__Vm_traceActivity[6U] = 1U;
    }
}

void Vooo_execution_unit_tb___024root___timing_commit(Vooo_execution_unit_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vooo_execution_unit_tb___024root___timing_commit\n"); );
    Vooo_execution_unit_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((! (8ULL & vlSelfRef.__VactTriggered.word(0U)))) {
        vlSelfRef.__VtrigSched_h3a7352f7__0.commit(
                                                   "@(posedge ooo_execution_unit_tb.rst_n)");
    }
    if ((! (1ULL & vlSelfRef.__VactTriggered.word(0U)))) {
        vlSelfRef.__VtrigSched_hc05f7348__0.commit(
                                                   "@(posedge ooo_execution_unit_tb.clk)");
    }
}

void Vooo_execution_unit_tb___024root___timing_resume(Vooo_execution_unit_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vooo_execution_unit_tb___024root___timing_resume\n"); );
    Vooo_execution_unit_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((8ULL & vlSelfRef.__VactTriggered.word(0U))) {
        vlSelfRef.__VtrigSched_h3a7352f7__0.resume(
                                                   "@(posedge ooo_execution_unit_tb.rst_n)");
    }
    if ((1ULL & vlSelfRef.__VactTriggered.word(0U))) {
        vlSelfRef.__VtrigSched_hc05f7348__0.resume(
                                                   "@(posedge ooo_execution_unit_tb.clk)");
    }
    if ((4ULL & vlSelfRef.__VactTriggered.word(0U))) {
        vlSelfRef.__VdlySched.resume();
    }
}

void Vooo_execution_unit_tb___024root___eval_triggers__act(Vooo_execution_unit_tb___024root* vlSelf);

bool Vooo_execution_unit_tb___024root___eval_phase__act(Vooo_execution_unit_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vooo_execution_unit_tb___024root___eval_phase__act\n"); );
    Vooo_execution_unit_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    VlTriggerVec<4> __VpreTriggered;
    CData/*0:0*/ __VactExecute;
    // Body
    Vooo_execution_unit_tb___024root___eval_triggers__act(vlSelf);
    Vooo_execution_unit_tb___024root___timing_commit(vlSelf);
    __VactExecute = vlSelfRef.__VactTriggered.any();
    if (__VactExecute) {
        __VpreTriggered.andNot(vlSelfRef.__VactTriggered, vlSelfRef.__VnbaTriggered);
        vlSelfRef.__VnbaTriggered.thisOr(vlSelfRef.__VactTriggered);
        Vooo_execution_unit_tb___024root___timing_resume(vlSelf);
        Vooo_execution_unit_tb___024root___eval_act(vlSelf);
    }
    return (__VactExecute);
}

bool Vooo_execution_unit_tb___024root___eval_phase__nba(Vooo_execution_unit_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vooo_execution_unit_tb___024root___eval_phase__nba\n"); );
    Vooo_execution_unit_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    CData/*0:0*/ __VnbaExecute;
    // Body
    __VnbaExecute = vlSelfRef.__VnbaTriggered.any();
    if (__VnbaExecute) {
        Vooo_execution_unit_tb___024root___eval_nba(vlSelf);
        vlSelfRef.__VnbaTriggered.clear();
    }
    return (__VnbaExecute);
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vooo_execution_unit_tb___024root___dump_triggers__nba(Vooo_execution_unit_tb___024root* vlSelf);
#endif  // VL_DEBUG
#ifdef VL_DEBUG
VL_ATTR_COLD void Vooo_execution_unit_tb___024root___dump_triggers__act(Vooo_execution_unit_tb___024root* vlSelf);
#endif  // VL_DEBUG

void Vooo_execution_unit_tb___024root___eval(Vooo_execution_unit_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vooo_execution_unit_tb___024root___eval\n"); );
    Vooo_execution_unit_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    IData/*31:0*/ __VnbaIterCount;
    CData/*0:0*/ __VnbaContinue;
    // Body
    __VnbaIterCount = 0U;
    __VnbaContinue = 1U;
    while (__VnbaContinue) {
        if (VL_UNLIKELY(((0x64U < __VnbaIterCount)))) {
#ifdef VL_DEBUG
            Vooo_execution_unit_tb___024root___dump_triggers__nba(vlSelf);
#endif
            VL_FATAL_MT("ooo_execution_unit_tb.sv", 1, "", "NBA region did not converge.");
        }
        __VnbaIterCount = ((IData)(1U) + __VnbaIterCount);
        __VnbaContinue = 0U;
        vlSelfRef.__VactIterCount = 0U;
        vlSelfRef.__VactContinue = 1U;
        while (vlSelfRef.__VactContinue) {
            if (VL_UNLIKELY(((0x64U < vlSelfRef.__VactIterCount)))) {
#ifdef VL_DEBUG
                Vooo_execution_unit_tb___024root___dump_triggers__act(vlSelf);
#endif
                VL_FATAL_MT("ooo_execution_unit_tb.sv", 1, "", "Active region did not converge.");
            }
            vlSelfRef.__VactIterCount = ((IData)(1U) 
                                         + vlSelfRef.__VactIterCount);
            vlSelfRef.__VactContinue = 0U;
            if (Vooo_execution_unit_tb___024root___eval_phase__act(vlSelf)) {
                vlSelfRef.__VactContinue = 1U;
            }
        }
        if (Vooo_execution_unit_tb___024root___eval_phase__nba(vlSelf)) {
            __VnbaContinue = 1U;
        }
    }
}

#ifdef VL_DEBUG
void Vooo_execution_unit_tb___024root___eval_debug_assertions(Vooo_execution_unit_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vooo_execution_unit_tb___024root___eval_debug_assertions\n"); );
    Vooo_execution_unit_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}
#endif  // VL_DEBUG
