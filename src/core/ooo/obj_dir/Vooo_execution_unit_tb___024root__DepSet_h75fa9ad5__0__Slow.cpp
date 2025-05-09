// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vooo_execution_unit_tb.h for the primary calling header

#include "Vooo_execution_unit_tb__pch.h"
#include "Vooo_execution_unit_tb___024root.h"

VL_ATTR_COLD void Vooo_execution_unit_tb___024root___eval_static(Vooo_execution_unit_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vooo_execution_unit_tb___024root___eval_static\n"); );
    Vooo_execution_unit_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__Vtrigprevexpr___TOP__ooo_execution_unit_tb__DOT__clk__0 
        = vlSelfRef.ooo_execution_unit_tb__DOT__clk;
    vlSelfRef.__Vtrigprevexpr___TOP__ooo_execution_unit_tb__DOT__rst_n__0 
        = vlSelfRef.ooo_execution_unit_tb__DOT__rst_n;
}

VL_ATTR_COLD void Vooo_execution_unit_tb___024root___eval_final(Vooo_execution_unit_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vooo_execution_unit_tb___024root___eval_final\n"); );
    Vooo_execution_unit_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vooo_execution_unit_tb___024root___dump_triggers__stl(Vooo_execution_unit_tb___024root* vlSelf);
#endif  // VL_DEBUG
VL_ATTR_COLD bool Vooo_execution_unit_tb___024root___eval_phase__stl(Vooo_execution_unit_tb___024root* vlSelf);

VL_ATTR_COLD void Vooo_execution_unit_tb___024root___eval_settle(Vooo_execution_unit_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vooo_execution_unit_tb___024root___eval_settle\n"); );
    Vooo_execution_unit_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    IData/*31:0*/ __VstlIterCount;
    CData/*0:0*/ __VstlContinue;
    // Body
    __VstlIterCount = 0U;
    vlSelfRef.__VstlFirstIteration = 1U;
    __VstlContinue = 1U;
    while (__VstlContinue) {
        if (VL_UNLIKELY(((0x64U < __VstlIterCount)))) {
#ifdef VL_DEBUG
            Vooo_execution_unit_tb___024root___dump_triggers__stl(vlSelf);
#endif
            VL_FATAL_MT("ooo_execution_unit_tb.sv", 1, "", "Settle region did not converge.");
        }
        __VstlIterCount = ((IData)(1U) + __VstlIterCount);
        __VstlContinue = 0U;
        if (Vooo_execution_unit_tb___024root___eval_phase__stl(vlSelf)) {
            __VstlContinue = 1U;
        }
        vlSelfRef.__VstlFirstIteration = 0U;
    }
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vooo_execution_unit_tb___024root___dump_triggers__stl(Vooo_execution_unit_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vooo_execution_unit_tb___024root___dump_triggers__stl\n"); );
    Vooo_execution_unit_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1U & (~ vlSelfRef.__VstlTriggered.any()))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if ((1ULL & vlSelfRef.__VstlTriggered.word(0U))) {
        VL_DBG_MSGF("         'stl' region trigger index 0 is active: Internal 'stl' trigger - first iteration\n");
    }
}
#endif  // VL_DEBUG

VL_ATTR_COLD void Vooo_execution_unit_tb___024root___stl_sequent__TOP__0(Vooo_execution_unit_tb___024root* vlSelf);
VL_ATTR_COLD void Vooo_execution_unit_tb___024root____Vm_traceActivitySetAll(Vooo_execution_unit_tb___024root* vlSelf);

VL_ATTR_COLD void Vooo_execution_unit_tb___024root___eval_stl(Vooo_execution_unit_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vooo_execution_unit_tb___024root___eval_stl\n"); );
    Vooo_execution_unit_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1ULL & vlSelfRef.__VstlTriggered.word(0U))) {
        Vooo_execution_unit_tb___024root___stl_sequent__TOP__0(vlSelf);
        Vooo_execution_unit_tb___024root____Vm_traceActivitySetAll(vlSelf);
    }
}

VL_ATTR_COLD void Vooo_execution_unit_tb___024root___eval_triggers__stl(Vooo_execution_unit_tb___024root* vlSelf);

VL_ATTR_COLD bool Vooo_execution_unit_tb___024root___eval_phase__stl(Vooo_execution_unit_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vooo_execution_unit_tb___024root___eval_phase__stl\n"); );
    Vooo_execution_unit_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    CData/*0:0*/ __VstlExecute;
    // Body
    Vooo_execution_unit_tb___024root___eval_triggers__stl(vlSelf);
    __VstlExecute = vlSelfRef.__VstlTriggered.any();
    if (__VstlExecute) {
        Vooo_execution_unit_tb___024root___eval_stl(vlSelf);
    }
    return (__VstlExecute);
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vooo_execution_unit_tb___024root___dump_triggers__act(Vooo_execution_unit_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vooo_execution_unit_tb___024root___dump_triggers__act\n"); );
    Vooo_execution_unit_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1U & (~ vlSelfRef.__VactTriggered.any()))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if ((1ULL & vlSelfRef.__VactTriggered.word(0U))) {
        VL_DBG_MSGF("         'act' region trigger index 0 is active: @(posedge ooo_execution_unit_tb.clk)\n");
    }
    if ((2ULL & vlSelfRef.__VactTriggered.word(0U))) {
        VL_DBG_MSGF("         'act' region trigger index 1 is active: @(negedge ooo_execution_unit_tb.rst_n)\n");
    }
    if ((4ULL & vlSelfRef.__VactTriggered.word(0U))) {
        VL_DBG_MSGF("         'act' region trigger index 2 is active: @([true] __VdlySched.awaitingCurrentTime())\n");
    }
    if ((8ULL & vlSelfRef.__VactTriggered.word(0U))) {
        VL_DBG_MSGF("         'act' region trigger index 3 is active: @(posedge ooo_execution_unit_tb.rst_n)\n");
    }
}
#endif  // VL_DEBUG

#ifdef VL_DEBUG
VL_ATTR_COLD void Vooo_execution_unit_tb___024root___dump_triggers__nba(Vooo_execution_unit_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vooo_execution_unit_tb___024root___dump_triggers__nba\n"); );
    Vooo_execution_unit_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1U & (~ vlSelfRef.__VnbaTriggered.any()))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if ((1ULL & vlSelfRef.__VnbaTriggered.word(0U))) {
        VL_DBG_MSGF("         'nba' region trigger index 0 is active: @(posedge ooo_execution_unit_tb.clk)\n");
    }
    if ((2ULL & vlSelfRef.__VnbaTriggered.word(0U))) {
        VL_DBG_MSGF("         'nba' region trigger index 1 is active: @(negedge ooo_execution_unit_tb.rst_n)\n");
    }
    if ((4ULL & vlSelfRef.__VnbaTriggered.word(0U))) {
        VL_DBG_MSGF("         'nba' region trigger index 2 is active: @([true] __VdlySched.awaitingCurrentTime())\n");
    }
    if ((8ULL & vlSelfRef.__VnbaTriggered.word(0U))) {
        VL_DBG_MSGF("         'nba' region trigger index 3 is active: @(posedge ooo_execution_unit_tb.rst_n)\n");
    }
}
#endif  // VL_DEBUG

VL_ATTR_COLD void Vooo_execution_unit_tb___024root____Vm_traceActivitySetAll(Vooo_execution_unit_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vooo_execution_unit_tb___024root____Vm_traceActivitySetAll\n"); );
    Vooo_execution_unit_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__Vm_traceActivity[0U] = 1U;
    vlSelfRef.__Vm_traceActivity[1U] = 1U;
    vlSelfRef.__Vm_traceActivity[2U] = 1U;
    vlSelfRef.__Vm_traceActivity[3U] = 1U;
    vlSelfRef.__Vm_traceActivity[4U] = 1U;
    vlSelfRef.__Vm_traceActivity[5U] = 1U;
    vlSelfRef.__Vm_traceActivity[6U] = 1U;
}

VL_ATTR_COLD void Vooo_execution_unit_tb___024root___ctor_var_reset(Vooo_execution_unit_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vooo_execution_unit_tb___024root___ctor_var_reset\n"); );
    Vooo_execution_unit_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelf->ooo_execution_unit_tb__DOT__clk = VL_RAND_RESET_I(1);
    vlSelf->ooo_execution_unit_tb__DOT__rst_n = VL_RAND_RESET_I(1);
    vlSelf->ooo_execution_unit_tb__DOT__instruction = VL_RAND_RESET_I(32);
    vlSelf->ooo_execution_unit_tb__DOT__pc = VL_RAND_RESET_I(32);
    vlSelf->ooo_execution_unit_tb__DOT__fetch_stall = VL_RAND_RESET_I(1);
    vlSelf->ooo_execution_unit_tb__DOT__rf_read_data1 = VL_RAND_RESET_I(32);
    vlSelf->ooo_execution_unit_tb__DOT__rf_read_data2 = VL_RAND_RESET_I(32);
    vlSelf->ooo_execution_unit_tb__DOT__rf_write_addr = VL_RAND_RESET_I(5);
    vlSelf->ooo_execution_unit_tb__DOT__mem_req_valid = VL_RAND_RESET_I(1);
    vlSelf->ooo_execution_unit_tb__DOT__mem_req_is_load = VL_RAND_RESET_I(1);
    vlSelf->ooo_execution_unit_tb__DOT__mem_req_addr = VL_RAND_RESET_I(32);
    vlSelf->ooo_execution_unit_tb__DOT__mem_req_data = VL_RAND_RESET_I(32);
    vlSelf->ooo_execution_unit_tb__DOT__mem_req_ready = VL_RAND_RESET_I(1);
    vlSelf->ooo_execution_unit_tb__DOT__mem_resp_data = VL_RAND_RESET_I(32);
    vlSelf->ooo_execution_unit_tb__DOT__mem_resp_valid = VL_RAND_RESET_I(1);
    vlSelf->ooo_execution_unit_tb__DOT__num_tests = 0;
    vlSelf->ooo_execution_unit_tb__DOT__num_passed = 0;
    vlSelf->ooo_execution_unit_tb__DOT____Vtogcov__clk = VL_RAND_RESET_I(1);
    vlSelf->ooo_execution_unit_tb__DOT____Vtogcov__rst_n = VL_RAND_RESET_I(1);
    vlSelf->ooo_execution_unit_tb__DOT____Vtogcov__instruction = VL_RAND_RESET_I(32);
    vlSelf->ooo_execution_unit_tb__DOT____Vtogcov__pc = VL_RAND_RESET_I(32);
    vlSelf->ooo_execution_unit_tb__DOT____Vtogcov__fetch_stall = VL_RAND_RESET_I(1);
    vlSelf->ooo_execution_unit_tb__DOT____Vtogcov__rf_read_data1 = VL_RAND_RESET_I(32);
    vlSelf->ooo_execution_unit_tb__DOT____Vtogcov__rf_read_data2 = VL_RAND_RESET_I(32);
    vlSelf->ooo_execution_unit_tb__DOT____Vtogcov__rf_write_addr = VL_RAND_RESET_I(5);
    vlSelf->ooo_execution_unit_tb__DOT____Vtogcov__rf_write_data = VL_RAND_RESET_I(32);
    vlSelf->ooo_execution_unit_tb__DOT____Vtogcov__rf_write_en = VL_RAND_RESET_I(1);
    vlSelf->ooo_execution_unit_tb__DOT____Vtogcov__mem_req_valid = VL_RAND_RESET_I(1);
    vlSelf->ooo_execution_unit_tb__DOT____Vtogcov__mem_req_is_load = VL_RAND_RESET_I(1);
    vlSelf->ooo_execution_unit_tb__DOT____Vtogcov__mem_req_addr = VL_RAND_RESET_I(32);
    vlSelf->ooo_execution_unit_tb__DOT____Vtogcov__mem_req_data = VL_RAND_RESET_I(32);
    vlSelf->ooo_execution_unit_tb__DOT____Vtogcov__mem_req_ready = VL_RAND_RESET_I(1);
    vlSelf->ooo_execution_unit_tb__DOT____Vtogcov__mem_resp_data = VL_RAND_RESET_I(32);
    vlSelf->ooo_execution_unit_tb__DOT____Vtogcov__mem_resp_valid = VL_RAND_RESET_I(1);
    vlSelf->ooo_execution_unit_tb__DOT____Vtogcov__branch_taken = VL_RAND_RESET_I(1);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__dispatch_valid = VL_RAND_RESET_I(1);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__dispatch_rob_tag = VL_RAND_RESET_I(5);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__dispatch_phys_reg = VL_RAND_RESET_I(5);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__dispatch_is_load = VL_RAND_RESET_I(1);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__dispatch_is_store = VL_RAND_RESET_I(1);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__dispatch_addr = VL_RAND_RESET_I(32);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__dispatch_store_data = VL_RAND_RESET_I(32);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__rob_full = VL_RAND_RESET_I(1);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__rob_empty = VL_RAND_RESET_I(1);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__commit_valid = VL_RAND_RESET_I(1);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__commit_tag = VL_RAND_RESET_I(5);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__commit_phys_reg = VL_RAND_RESET_I(5);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__commit_is_load = VL_RAND_RESET_I(1);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__commit_is_store = VL_RAND_RESET_I(1);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__rs_dispatch_valid = VL_RAND_RESET_I(1);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__rs_dispatch_phys_reg = VL_RAND_RESET_I(5);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__exec_valid = VL_RAND_RESET_I(1);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__exec_instruction = VL_RAND_RESET_I(32);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__exec_rs1_data = VL_RAND_RESET_I(32);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__exec_rs2_data = VL_RAND_RESET_I(32);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__lsq_dispatch_valid = VL_RAND_RESET_I(1);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__lsq_dispatch_tag = VL_RAND_RESET_I(5);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__lsq_full = VL_RAND_RESET_I(1);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__free_list_tag = VL_RAND_RESET_I(5);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__free_list_valid = VL_RAND_RESET_I(1);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__wb_valid = VL_RAND_RESET_I(1);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__wb_tag = VL_RAND_RESET_I(5);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__wb_data = VL_RAND_RESET_I(32);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__rename_rs1_tag = VL_RAND_RESET_I(5);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__rename_rs2_tag = VL_RAND_RESET_I(5);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__rename_rd_tag = VL_RAND_RESET_I(5);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__rename_rs1_ready = VL_RAND_RESET_I(1);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__rename_rs2_ready = VL_RAND_RESET_I(1);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__dispatch_valid = VL_RAND_RESET_I(1);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__dispatch_ready = VL_RAND_RESET_I(1);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__dispatch_rob_tag = VL_RAND_RESET_I(5);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__dispatch_phys_reg = VL_RAND_RESET_I(5);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__dispatch_is_load = VL_RAND_RESET_I(1);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__dispatch_is_store = VL_RAND_RESET_I(1);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__dispatch_addr = VL_RAND_RESET_I(32);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__dispatch_store_data = VL_RAND_RESET_I(32);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__rob_full = VL_RAND_RESET_I(1);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__rob_empty = VL_RAND_RESET_I(1);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__commit_tag = VL_RAND_RESET_I(5);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__commit_phys_reg = VL_RAND_RESET_I(5);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__commit_is_load = VL_RAND_RESET_I(1);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__commit_is_store = VL_RAND_RESET_I(1);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__rs_dispatch_valid = VL_RAND_RESET_I(1);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__rs_dispatch_ready = VL_RAND_RESET_I(1);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__rs_dispatch_tag = VL_RAND_RESET_I(5);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__rs_dispatch_phys_reg = VL_RAND_RESET_I(5);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__exec_valid = VL_RAND_RESET_I(1);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__exec_instruction = VL_RAND_RESET_I(32);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__exec_rs1_data = VL_RAND_RESET_I(32);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__exec_rs2_data = VL_RAND_RESET_I(32);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__exec_ready = VL_RAND_RESET_I(1);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__lsq_dispatch_valid = VL_RAND_RESET_I(1);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__lsq_dispatch_ready = VL_RAND_RESET_I(1);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__lsq_dispatch_tag = VL_RAND_RESET_I(5);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__lsq_full = VL_RAND_RESET_I(1);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__free_list_empty = VL_RAND_RESET_I(1);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__free_list_tag = VL_RAND_RESET_I(5);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__free_list_valid = VL_RAND_RESET_I(1);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__wb_valid = VL_RAND_RESET_I(1);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__wb_tag = VL_RAND_RESET_I(5);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__rename_rs1_tag = VL_RAND_RESET_I(5);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__rename_rs2_tag = VL_RAND_RESET_I(5);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__rename_rd_tag = VL_RAND_RESET_I(5);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__rename_rs1_ready = VL_RAND_RESET_I(1);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__rename_rs2_ready = VL_RAND_RESET_I(1);
    VL_RAND_RESET_W(896, vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__rob__DOT__entries);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__rob__DOT__head_ptr = VL_RAND_RESET_I(6);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__rob__DOT__tail_ptr = VL_RAND_RESET_I(6);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__rob__DOT__count = VL_RAND_RESET_I(7);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__rob__DOT____Vtogcov__head_ptr = VL_RAND_RESET_I(6);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__rob__DOT____Vtogcov__tail_ptr = VL_RAND_RESET_I(6);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__rob__DOT____Vtogcov__count = VL_RAND_RESET_I(7);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__rob__DOT__unnamedblk1__DOT__i = 0;
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__rob__DOT____Vlvbound_h3339764f__0 = VL_RAND_RESET_I(1);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__rob__DOT____Vlvbound_h59e1373c__0 = VL_RAND_RESET_I(1);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__rob__DOT____Vlvbound_h5c1ef3ac__0 = VL_RAND_RESET_I(5);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__rob__DOT____Vlvbound_h5c1daf78__0 = VL_RAND_RESET_I(5);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__rob__DOT____Vlvbound_h5a177b2e__0 = VL_RAND_RESET_I(1);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__rob__DOT____Vlvbound_h025d1fc4__0 = VL_RAND_RESET_I(1);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__rob__DOT____Vlvbound_h5fca0916__0 = VL_RAND_RESET_I(1);
    VL_RAND_RESET_W(3488, vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__rs__DOT__entries);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__rs__DOT__head_ptr = VL_RAND_RESET_I(5);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__rs__DOT__tail_ptr = VL_RAND_RESET_I(5);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__rs__DOT__count = VL_RAND_RESET_I(6);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__rs__DOT__full = VL_RAND_RESET_I(1);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__rs__DOT____Vtogcov__head_ptr = VL_RAND_RESET_I(5);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__rs__DOT____Vtogcov__count = VL_RAND_RESET_I(6);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__rs__DOT____Vtogcov__full = VL_RAND_RESET_I(1);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__rs__DOT____Vtogcov__empty = VL_RAND_RESET_I(1);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__rs__DOT__unnamedblk2__DOT__i = 0;
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__rs__DOT__unnamedblk1__DOT__i = 0;
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__rs__DOT____Vlvbound_had35632b__0 = VL_RAND_RESET_I(1);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__rs__DOT____Vlvbound_h7c6d3c92__0 = VL_RAND_RESET_I(32);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__rs__DOT____Vlvbound_h791930e5__0 = VL_RAND_RESET_I(32);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__rs__DOT____Vlvbound_h7de71c3f__0 = VL_RAND_RESET_I(32);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__rs__DOT____Vlvbound_had1398b7__0 = VL_RAND_RESET_I(1);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__rs__DOT____Vlvbound_had12c6a0__0 = VL_RAND_RESET_I(1);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__rs__DOT____Vlvbound_h964c8d06__0 = VL_RAND_RESET_I(5);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__rs__DOT____Vlvbound_hf571a7d0__0 = VL_RAND_RESET_I(5);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__rs__DOT____Vlvbound_h246cbe77__0 = VL_RAND_RESET_I(1);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__rs__DOT____Vlvbound_hfa6c9d56__0 = VL_RAND_RESET_I(32);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__rs__DOT____Vlvbound_hf77db2f0__0 = VL_RAND_RESET_I(32);
    for (int __Vi0 = 0; __Vi0 < 32; ++__Vi0) {
        vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__rename__DOT__rename_table[__Vi0] = VL_RAND_RESET_I(5);
    }
    for (int __Vi0 = 0; __Vi0 < 64; ++__Vi0) {
        vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__rename__DOT__reg_ready[__Vi0] = VL_RAND_RESET_I(1);
    }
    for (int __Vi0 = 0; __Vi0 < 32; ++__Vi0) {
        vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__rename__DOT____Vtogcov__rename_table[__Vi0] = VL_RAND_RESET_I(5);
    }
    for (int __Vi0 = 0; __Vi0 < 64; ++__Vi0) {
        vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__rename__DOT____Vtogcov__reg_ready[__Vi0] = VL_RAND_RESET_I(1);
    }
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__rename__DOT__unnamedblk1__DOT__i = 0;
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__rename__DOT__unnamedblk2__DOT__i = 0;
    for (int __Vi0 = 0; __Vi0 < 64; ++__Vi0) {
        vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__free_list__DOT__free_list_storage[__Vi0] = VL_RAND_RESET_I(5);
    }
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__free_list__DOT__count = VL_RAND_RESET_I(6);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__free_list__DOT__head_ptr = VL_RAND_RESET_I(5);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__free_list__DOT__tail_ptr = VL_RAND_RESET_I(5);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__free_list__DOT____Vtogcov__count = VL_RAND_RESET_I(6);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__free_list__DOT____Vtogcov__head_ptr = VL_RAND_RESET_I(5);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__free_list__DOT____Vtogcov__tail_ptr = VL_RAND_RESET_I(5);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__free_list__DOT__unnamedblk1__DOT__i = 0;
    VL_RAND_RESET_W(2336, vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__lsq__DOT__entries);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__lsq__DOT__head_ptr = VL_RAND_RESET_I(5);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__lsq__DOT__tail_ptr = VL_RAND_RESET_I(5);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__lsq__DOT__count = VL_RAND_RESET_I(6);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__lsq__DOT____Vtogcov__rob_tag = VL_RAND_RESET_I(6);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__lsq__DOT____Vtogcov__commit_tag = VL_RAND_RESET_I(6);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__lsq__DOT____Vtogcov__head_ptr = VL_RAND_RESET_I(5);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__lsq__DOT____Vtogcov__tail_ptr = VL_RAND_RESET_I(5);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__lsq__DOT____Vtogcov__count = VL_RAND_RESET_I(6);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__lsq__DOT__unnamedblk1__DOT__i = 0;
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__lsq__DOT__unnamedblk1__DOT__unnamedblk2__DOT__ptr = VL_RAND_RESET_I(5);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__lsq__DOT__unnamedblk4__DOT__i = 0;
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__lsq__DOT__unnamedblk3__DOT__i = 0;
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__lsq__DOT____Vlvbound_h5a372312__0 = VL_RAND_RESET_I(1);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__lsq__DOT____Vlvbound_h5939850f__0 = VL_RAND_RESET_I(1);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__lsq__DOT____Vlvbound_h5a1c4a95__0 = VL_RAND_RESET_I(1);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__lsq__DOT____Vlvbound_ha8eb1039__0 = VL_RAND_RESET_I(32);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__lsq__DOT____Vlvbound_ha77d7307__0 = VL_RAND_RESET_I(32);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__lsq__DOT____Vlvbound_h555f7517__0 = VL_RAND_RESET_I(6);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__lsq__DOT____Vlvbound_h76456c52__0 = VL_RAND_RESET_I(1);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__lsq__DOT____Vlvbound_hc44b6764__0 = VL_RAND_RESET_I(32);
    vlSelf->ooo_execution_unit_tb__DOT__dut__DOT__lsq__DOT____Vlvbound_h2b616296__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vtrigprevexpr___TOP__ooo_execution_unit_tb__DOT__clk__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vtrigprevexpr___TOP__ooo_execution_unit_tb__DOT__rst_n__0 = VL_RAND_RESET_I(1);
    for (int __Vi0 = 0; __Vi0 < 7; ++__Vi0) {
        vlSelf->__Vm_traceActivity[__Vi0] = 0;
    }
}
