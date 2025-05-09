// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See Vooo_execution_unit_tb.h for the primary calling header

#ifndef VERILATED_VOOO_EXECUTION_UNIT_TB___024ROOT_H_
#define VERILATED_VOOO_EXECUTION_UNIT_TB___024ROOT_H_  // guard

#include "verilated.h"
#include "verilated_cov.h"
#include "verilated_timing.h"


class Vooo_execution_unit_tb__Syms;

class alignas(VL_CACHE_LINE_BYTES) Vooo_execution_unit_tb___024root final : public VerilatedModule {
  public:

    // DESIGN SPECIFIC STATE
    // Anonymous structures to workaround compiler member-count bugs
    struct {
        CData/*0:0*/ ooo_execution_unit_tb__DOT__clk;
        CData/*0:0*/ ooo_execution_unit_tb__DOT__rst_n;
        CData/*0:0*/ ooo_execution_unit_tb__DOT__fetch_stall;
        CData/*4:0*/ ooo_execution_unit_tb__DOT__rf_write_addr;
        CData/*0:0*/ ooo_execution_unit_tb__DOT__mem_req_valid;
        CData/*0:0*/ ooo_execution_unit_tb__DOT__mem_req_is_load;
        CData/*0:0*/ ooo_execution_unit_tb__DOT__mem_req_ready;
        CData/*0:0*/ ooo_execution_unit_tb__DOT__mem_resp_valid;
        CData/*0:0*/ ooo_execution_unit_tb__DOT____Vtogcov__clk;
        CData/*0:0*/ ooo_execution_unit_tb__DOT____Vtogcov__rst_n;
        CData/*0:0*/ ooo_execution_unit_tb__DOT____Vtogcov__fetch_stall;
        CData/*4:0*/ ooo_execution_unit_tb__DOT____Vtogcov__rf_write_addr;
        CData/*0:0*/ ooo_execution_unit_tb__DOT____Vtogcov__rf_write_en;
        CData/*0:0*/ ooo_execution_unit_tb__DOT____Vtogcov__mem_req_valid;
        CData/*0:0*/ ooo_execution_unit_tb__DOT____Vtogcov__mem_req_is_load;
        CData/*0:0*/ ooo_execution_unit_tb__DOT____Vtogcov__mem_req_ready;
        CData/*0:0*/ ooo_execution_unit_tb__DOT____Vtogcov__mem_resp_valid;
        CData/*0:0*/ ooo_execution_unit_tb__DOT____Vtogcov__branch_taken;
        CData/*0:0*/ ooo_execution_unit_tb__DOT__dut__DOT__dispatch_valid;
        CData/*4:0*/ ooo_execution_unit_tb__DOT__dut__DOT__dispatch_rob_tag;
        CData/*4:0*/ ooo_execution_unit_tb__DOT__dut__DOT__dispatch_phys_reg;
        CData/*0:0*/ ooo_execution_unit_tb__DOT__dut__DOT__dispatch_is_load;
        CData/*0:0*/ ooo_execution_unit_tb__DOT__dut__DOT__dispatch_is_store;
        CData/*0:0*/ ooo_execution_unit_tb__DOT__dut__DOT__rob_full;
        CData/*0:0*/ ooo_execution_unit_tb__DOT__dut__DOT__rob_empty;
        CData/*0:0*/ ooo_execution_unit_tb__DOT__dut__DOT__commit_valid;
        CData/*4:0*/ ooo_execution_unit_tb__DOT__dut__DOT__commit_tag;
        CData/*4:0*/ ooo_execution_unit_tb__DOT__dut__DOT__commit_phys_reg;
        CData/*0:0*/ ooo_execution_unit_tb__DOT__dut__DOT__commit_is_load;
        CData/*0:0*/ ooo_execution_unit_tb__DOT__dut__DOT__commit_is_store;
        CData/*0:0*/ ooo_execution_unit_tb__DOT__dut__DOT__rs_dispatch_valid;
        CData/*4:0*/ ooo_execution_unit_tb__DOT__dut__DOT__rs_dispatch_phys_reg;
        CData/*0:0*/ ooo_execution_unit_tb__DOT__dut__DOT__exec_valid;
        CData/*0:0*/ ooo_execution_unit_tb__DOT__dut__DOT__lsq_dispatch_valid;
        CData/*4:0*/ ooo_execution_unit_tb__DOT__dut__DOT__lsq_dispatch_tag;
        CData/*0:0*/ ooo_execution_unit_tb__DOT__dut__DOT__lsq_full;
        CData/*4:0*/ ooo_execution_unit_tb__DOT__dut__DOT__free_list_tag;
        CData/*0:0*/ ooo_execution_unit_tb__DOT__dut__DOT__free_list_valid;
        CData/*0:0*/ ooo_execution_unit_tb__DOT__dut__DOT__wb_valid;
        CData/*4:0*/ ooo_execution_unit_tb__DOT__dut__DOT__wb_tag;
        CData/*4:0*/ ooo_execution_unit_tb__DOT__dut__DOT__rename_rs1_tag;
        CData/*4:0*/ ooo_execution_unit_tb__DOT__dut__DOT__rename_rs2_tag;
        CData/*4:0*/ ooo_execution_unit_tb__DOT__dut__DOT__rename_rd_tag;
        CData/*0:0*/ ooo_execution_unit_tb__DOT__dut__DOT__rename_rs1_ready;
        CData/*0:0*/ ooo_execution_unit_tb__DOT__dut__DOT__rename_rs2_ready;
        CData/*0:0*/ ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__dispatch_valid;
        CData/*0:0*/ ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__dispatch_ready;
        CData/*4:0*/ ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__dispatch_rob_tag;
        CData/*4:0*/ ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__dispatch_phys_reg;
        CData/*0:0*/ ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__dispatch_is_load;
        CData/*0:0*/ ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__dispatch_is_store;
        CData/*0:0*/ ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__rob_full;
        CData/*0:0*/ ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__rob_empty;
        CData/*4:0*/ ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__commit_tag;
        CData/*4:0*/ ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__commit_phys_reg;
        CData/*0:0*/ ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__commit_is_load;
        CData/*0:0*/ ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__commit_is_store;
        CData/*0:0*/ ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__rs_dispatch_valid;
        CData/*0:0*/ ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__rs_dispatch_ready;
        CData/*4:0*/ ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__rs_dispatch_tag;
        CData/*4:0*/ ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__rs_dispatch_phys_reg;
        CData/*0:0*/ ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__exec_valid;
        CData/*0:0*/ ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__exec_ready;
        CData/*0:0*/ ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__lsq_dispatch_valid;
    };
    struct {
        CData/*0:0*/ ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__lsq_dispatch_ready;
        CData/*4:0*/ ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__lsq_dispatch_tag;
        CData/*0:0*/ ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__lsq_full;
        CData/*0:0*/ ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__free_list_empty;
        CData/*4:0*/ ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__free_list_tag;
        CData/*0:0*/ ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__free_list_valid;
        CData/*0:0*/ ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__wb_valid;
        CData/*4:0*/ ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__wb_tag;
        CData/*4:0*/ ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__rename_rs1_tag;
        CData/*4:0*/ ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__rename_rs2_tag;
        CData/*4:0*/ ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__rename_rd_tag;
        CData/*0:0*/ ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__rename_rs1_ready;
        CData/*0:0*/ ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__rename_rs2_ready;
        CData/*5:0*/ ooo_execution_unit_tb__DOT__dut__DOT__rob__DOT__head_ptr;
        CData/*5:0*/ ooo_execution_unit_tb__DOT__dut__DOT__rob__DOT__tail_ptr;
        CData/*6:0*/ ooo_execution_unit_tb__DOT__dut__DOT__rob__DOT__count;
        CData/*5:0*/ ooo_execution_unit_tb__DOT__dut__DOT__rob__DOT____Vtogcov__head_ptr;
        CData/*5:0*/ ooo_execution_unit_tb__DOT__dut__DOT__rob__DOT____Vtogcov__tail_ptr;
        CData/*6:0*/ ooo_execution_unit_tb__DOT__dut__DOT__rob__DOT____Vtogcov__count;
        CData/*0:0*/ ooo_execution_unit_tb__DOT__dut__DOT__rob__DOT____Vlvbound_h3339764f__0;
        CData/*0:0*/ ooo_execution_unit_tb__DOT__dut__DOT__rob__DOT____Vlvbound_h59e1373c__0;
        CData/*4:0*/ ooo_execution_unit_tb__DOT__dut__DOT__rob__DOT____Vlvbound_h5c1ef3ac__0;
        CData/*4:0*/ ooo_execution_unit_tb__DOT__dut__DOT__rob__DOT____Vlvbound_h5c1daf78__0;
        CData/*0:0*/ ooo_execution_unit_tb__DOT__dut__DOT__rob__DOT____Vlvbound_h5a177b2e__0;
        CData/*0:0*/ ooo_execution_unit_tb__DOT__dut__DOT__rob__DOT____Vlvbound_h025d1fc4__0;
        CData/*0:0*/ ooo_execution_unit_tb__DOT__dut__DOT__rob__DOT____Vlvbound_h5fca0916__0;
        CData/*4:0*/ ooo_execution_unit_tb__DOT__dut__DOT__rs__DOT__head_ptr;
        CData/*4:0*/ ooo_execution_unit_tb__DOT__dut__DOT__rs__DOT__tail_ptr;
        CData/*5:0*/ ooo_execution_unit_tb__DOT__dut__DOT__rs__DOT__count;
        CData/*0:0*/ ooo_execution_unit_tb__DOT__dut__DOT__rs__DOT__full;
        CData/*4:0*/ ooo_execution_unit_tb__DOT__dut__DOT__rs__DOT____Vtogcov__head_ptr;
        CData/*5:0*/ ooo_execution_unit_tb__DOT__dut__DOT__rs__DOT____Vtogcov__count;
        CData/*0:0*/ ooo_execution_unit_tb__DOT__dut__DOT__rs__DOT____Vtogcov__full;
        CData/*0:0*/ ooo_execution_unit_tb__DOT__dut__DOT__rs__DOT____Vtogcov__empty;
        CData/*0:0*/ ooo_execution_unit_tb__DOT__dut__DOT__rs__DOT____Vlvbound_had35632b__0;
        CData/*0:0*/ ooo_execution_unit_tb__DOT__dut__DOT__rs__DOT____Vlvbound_had1398b7__0;
        CData/*0:0*/ ooo_execution_unit_tb__DOT__dut__DOT__rs__DOT____Vlvbound_had12c6a0__0;
        CData/*4:0*/ ooo_execution_unit_tb__DOT__dut__DOT__rs__DOT____Vlvbound_h964c8d06__0;
        CData/*4:0*/ ooo_execution_unit_tb__DOT__dut__DOT__rs__DOT____Vlvbound_hf571a7d0__0;
        CData/*0:0*/ ooo_execution_unit_tb__DOT__dut__DOT__rs__DOT____Vlvbound_h246cbe77__0;
        CData/*5:0*/ ooo_execution_unit_tb__DOT__dut__DOT__free_list__DOT__count;
        CData/*4:0*/ ooo_execution_unit_tb__DOT__dut__DOT__free_list__DOT__head_ptr;
        CData/*4:0*/ ooo_execution_unit_tb__DOT__dut__DOT__free_list__DOT__tail_ptr;
        CData/*5:0*/ ooo_execution_unit_tb__DOT__dut__DOT__free_list__DOT____Vtogcov__count;
        CData/*4:0*/ ooo_execution_unit_tb__DOT__dut__DOT__free_list__DOT____Vtogcov__head_ptr;
        CData/*4:0*/ ooo_execution_unit_tb__DOT__dut__DOT__free_list__DOT____Vtogcov__tail_ptr;
        CData/*4:0*/ ooo_execution_unit_tb__DOT__dut__DOT__lsq__DOT__head_ptr;
        CData/*4:0*/ ooo_execution_unit_tb__DOT__dut__DOT__lsq__DOT__tail_ptr;
        CData/*5:0*/ ooo_execution_unit_tb__DOT__dut__DOT__lsq__DOT__count;
        CData/*5:0*/ ooo_execution_unit_tb__DOT__dut__DOT__lsq__DOT____Vtogcov__rob_tag;
        CData/*5:0*/ ooo_execution_unit_tb__DOT__dut__DOT__lsq__DOT____Vtogcov__commit_tag;
        CData/*4:0*/ ooo_execution_unit_tb__DOT__dut__DOT__lsq__DOT____Vtogcov__head_ptr;
        CData/*4:0*/ ooo_execution_unit_tb__DOT__dut__DOT__lsq__DOT____Vtogcov__tail_ptr;
        CData/*5:0*/ ooo_execution_unit_tb__DOT__dut__DOT__lsq__DOT____Vtogcov__count;
        CData/*4:0*/ ooo_execution_unit_tb__DOT__dut__DOT__lsq__DOT__unnamedblk1__DOT__unnamedblk2__DOT__ptr;
        CData/*0:0*/ ooo_execution_unit_tb__DOT__dut__DOT__lsq__DOT____Vlvbound_h5a372312__0;
        CData/*0:0*/ ooo_execution_unit_tb__DOT__dut__DOT__lsq__DOT____Vlvbound_h5939850f__0;
        CData/*0:0*/ ooo_execution_unit_tb__DOT__dut__DOT__lsq__DOT____Vlvbound_h5a1c4a95__0;
        CData/*5:0*/ ooo_execution_unit_tb__DOT__dut__DOT__lsq__DOT____Vlvbound_h555f7517__0;
        CData/*0:0*/ ooo_execution_unit_tb__DOT__dut__DOT__lsq__DOT____Vlvbound_h76456c52__0;
        CData/*0:0*/ ooo_execution_unit_tb__DOT__dut__DOT__lsq__DOT____Vlvbound_h2b616296__0;
        CData/*0:0*/ __VstlFirstIteration;
        CData/*0:0*/ __Vtrigprevexpr___TOP__ooo_execution_unit_tb__DOT__clk__0;
        CData/*0:0*/ __Vtrigprevexpr___TOP__ooo_execution_unit_tb__DOT__rst_n__0;
    };
    struct {
        CData/*0:0*/ __VactContinue;
        VlWide<28>/*895:0*/ ooo_execution_unit_tb__DOT__dut__DOT__rob__DOT__entries;
        IData/*31:0*/ ooo_execution_unit_tb__DOT__instruction;
        IData/*31:0*/ ooo_execution_unit_tb__DOT__pc;
        IData/*31:0*/ ooo_execution_unit_tb__DOT__rf_read_data1;
        IData/*31:0*/ ooo_execution_unit_tb__DOT__rf_read_data2;
        IData/*31:0*/ ooo_execution_unit_tb__DOT__mem_req_addr;
        IData/*31:0*/ ooo_execution_unit_tb__DOT__mem_req_data;
        IData/*31:0*/ ooo_execution_unit_tb__DOT__mem_resp_data;
        IData/*31:0*/ ooo_execution_unit_tb__DOT__num_tests;
        IData/*31:0*/ ooo_execution_unit_tb__DOT__num_passed;
        IData/*31:0*/ ooo_execution_unit_tb__DOT____Vtogcov__instruction;
        IData/*31:0*/ ooo_execution_unit_tb__DOT____Vtogcov__pc;
        IData/*31:0*/ ooo_execution_unit_tb__DOT____Vtogcov__rf_read_data1;
        IData/*31:0*/ ooo_execution_unit_tb__DOT____Vtogcov__rf_read_data2;
        IData/*31:0*/ ooo_execution_unit_tb__DOT____Vtogcov__rf_write_data;
        IData/*31:0*/ ooo_execution_unit_tb__DOT____Vtogcov__mem_req_addr;
        IData/*31:0*/ ooo_execution_unit_tb__DOT____Vtogcov__mem_req_data;
        IData/*31:0*/ ooo_execution_unit_tb__DOT____Vtogcov__mem_resp_data;
        IData/*31:0*/ ooo_execution_unit_tb__DOT__dut__DOT__dispatch_addr;
        IData/*31:0*/ ooo_execution_unit_tb__DOT__dut__DOT__dispatch_store_data;
        IData/*31:0*/ ooo_execution_unit_tb__DOT__dut__DOT__exec_instruction;
        IData/*31:0*/ ooo_execution_unit_tb__DOT__dut__DOT__exec_rs1_data;
        IData/*31:0*/ ooo_execution_unit_tb__DOT__dut__DOT__exec_rs2_data;
        IData/*31:0*/ ooo_execution_unit_tb__DOT__dut__DOT__wb_data;
        IData/*31:0*/ ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__dispatch_addr;
        IData/*31:0*/ ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__dispatch_store_data;
        IData/*31:0*/ ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__exec_instruction;
        IData/*31:0*/ ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__exec_rs1_data;
        IData/*31:0*/ ooo_execution_unit_tb__DOT__dut__DOT____Vtogcov__exec_rs2_data;
        IData/*31:0*/ ooo_execution_unit_tb__DOT__dut__DOT__rob__DOT__unnamedblk1__DOT__i;
        IData/*31:0*/ ooo_execution_unit_tb__DOT__dut__DOT__rs__DOT__unnamedblk2__DOT__i;
        IData/*31:0*/ ooo_execution_unit_tb__DOT__dut__DOT__rs__DOT__unnamedblk1__DOT__i;
        IData/*31:0*/ ooo_execution_unit_tb__DOT__dut__DOT__rs__DOT____Vlvbound_h7c6d3c92__0;
        IData/*31:0*/ ooo_execution_unit_tb__DOT__dut__DOT__rs__DOT____Vlvbound_h791930e5__0;
        IData/*31:0*/ ooo_execution_unit_tb__DOT__dut__DOT__rs__DOT____Vlvbound_h7de71c3f__0;
        IData/*31:0*/ ooo_execution_unit_tb__DOT__dut__DOT__rs__DOT____Vlvbound_hfa6c9d56__0;
        IData/*31:0*/ ooo_execution_unit_tb__DOT__dut__DOT__rs__DOT____Vlvbound_hf77db2f0__0;
        IData/*31:0*/ ooo_execution_unit_tb__DOT__dut__DOT__rename__DOT__unnamedblk1__DOT__i;
        IData/*31:0*/ ooo_execution_unit_tb__DOT__dut__DOT__rename__DOT__unnamedblk2__DOT__i;
        IData/*31:0*/ ooo_execution_unit_tb__DOT__dut__DOT__free_list__DOT__unnamedblk1__DOT__i;
        IData/*31:0*/ ooo_execution_unit_tb__DOT__dut__DOT__lsq__DOT__unnamedblk1__DOT__i;
        IData/*31:0*/ ooo_execution_unit_tb__DOT__dut__DOT__lsq__DOT__unnamedblk4__DOT__i;
        IData/*31:0*/ ooo_execution_unit_tb__DOT__dut__DOT__lsq__DOT__unnamedblk3__DOT__i;
        IData/*31:0*/ ooo_execution_unit_tb__DOT__dut__DOT__lsq__DOT____Vlvbound_ha8eb1039__0;
        IData/*31:0*/ ooo_execution_unit_tb__DOT__dut__DOT__lsq__DOT____Vlvbound_ha77d7307__0;
        IData/*31:0*/ ooo_execution_unit_tb__DOT__dut__DOT__lsq__DOT____Vlvbound_hc44b6764__0;
        IData/*31:0*/ __VactIterCount;
        VlWide<109>/*3487:0*/ ooo_execution_unit_tb__DOT__dut__DOT__rs__DOT__entries;
        VlWide<73>/*2335:0*/ ooo_execution_unit_tb__DOT__dut__DOT__lsq__DOT__entries;
        VlUnpacked<CData/*4:0*/, 32> ooo_execution_unit_tb__DOT__dut__DOT__rename__DOT__rename_table;
        VlUnpacked<CData/*0:0*/, 64> ooo_execution_unit_tb__DOT__dut__DOT__rename__DOT__reg_ready;
        VlUnpacked<CData/*4:0*/, 32> ooo_execution_unit_tb__DOT__dut__DOT__rename__DOT____Vtogcov__rename_table;
        VlUnpacked<CData/*0:0*/, 64> ooo_execution_unit_tb__DOT__dut__DOT__rename__DOT____Vtogcov__reg_ready;
        VlUnpacked<CData/*4:0*/, 64> ooo_execution_unit_tb__DOT__dut__DOT__free_list__DOT__free_list_storage;
        VlUnpacked<CData/*0:0*/, 7> __Vm_traceActivity;
    };
    VlDelayScheduler __VdlySched;
    VlTriggerScheduler __VtrigSched_h3a7352f7__0;
    VlTriggerScheduler __VtrigSched_hc05f7348__0;
    VlTriggerVec<1> __VstlTriggered;
    VlTriggerVec<4> __VactTriggered;
    VlTriggerVec<4> __VnbaTriggered;

    // INTERNAL VARIABLES
    Vooo_execution_unit_tb__Syms* const vlSymsp;

    // CONSTRUCTORS
    Vooo_execution_unit_tb___024root(Vooo_execution_unit_tb__Syms* symsp, const char* v__name);
    ~Vooo_execution_unit_tb___024root();
    VL_UNCOPYABLE(Vooo_execution_unit_tb___024root);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
    void __vlCoverInsert(uint32_t* countp, bool enable, const char* filenamep, int lineno, int column,
        const char* hierp, const char* pagep, const char* commentp, const char* linescovp);
};


#endif  // guard
