// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Tracing implementation internals
#include "verilated_vcd_c.h"
#include "Vooo_execution_unit_tb__Syms.h"


void Vooo_execution_unit_tb___024root__trace_chg_0_sub_0(Vooo_execution_unit_tb___024root* vlSelf, VerilatedVcd::Buffer* bufp);

void Vooo_execution_unit_tb___024root__trace_chg_0(void* voidSelf, VerilatedVcd::Buffer* bufp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vooo_execution_unit_tb___024root__trace_chg_0\n"); );
    // Init
    Vooo_execution_unit_tb___024root* const __restrict vlSelf VL_ATTR_UNUSED = static_cast<Vooo_execution_unit_tb___024root*>(voidSelf);
    Vooo_execution_unit_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    if (VL_UNLIKELY(!vlSymsp->__Vm_activity)) return;
    // Body
    Vooo_execution_unit_tb___024root__trace_chg_0_sub_0((&vlSymsp->TOP), bufp);
}

void Vooo_execution_unit_tb___024root__trace_chg_0_sub_0(Vooo_execution_unit_tb___024root* vlSelf, VerilatedVcd::Buffer* bufp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vooo_execution_unit_tb___024root__trace_chg_0_sub_0\n"); );
    Vooo_execution_unit_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    uint32_t* const oldp VL_ATTR_UNUSED = bufp->oldp(vlSymsp->__Vm_baseCode + 1);
    // Body
    if (VL_UNLIKELY(((vlSelfRef.__Vm_traceActivity[1U] 
                      | vlSelfRef.__Vm_traceActivity
                      [2U])))) {
        bufp->chgIData(oldp+0,(vlSelfRef.ooo_execution_unit_tb__DOT__instruction),32);
        bufp->chgIData(oldp+1,(vlSelfRef.ooo_execution_unit_tb__DOT__pc),32);
        bufp->chgIData(oldp+2,(vlSelfRef.ooo_execution_unit_tb__DOT__rf_read_data1),32);
        bufp->chgIData(oldp+3,(vlSelfRef.ooo_execution_unit_tb__DOT__rf_read_data2),32);
        bufp->chgCData(oldp+4,((0x1fU & (vlSelfRef.ooo_execution_unit_tb__DOT__instruction 
                                         >> 0xfU))),5);
        bufp->chgCData(oldp+5,((0x1fU & (vlSelfRef.ooo_execution_unit_tb__DOT__instruction 
                                         >> 0x14U))),5);
        bufp->chgBit(oldp+6,(vlSelfRef.ooo_execution_unit_tb__DOT__mem_req_ready));
        bufp->chgIData(oldp+7,(vlSelfRef.ooo_execution_unit_tb__DOT__mem_resp_data),32);
        bufp->chgBit(oldp+8,(vlSelfRef.ooo_execution_unit_tb__DOT__mem_resp_valid));
        bufp->chgCData(oldp+9,((0x1fU & (vlSelfRef.ooo_execution_unit_tb__DOT__instruction 
                                         >> 7U))),5);
    }
    if (VL_UNLIKELY(((vlSelfRef.__Vm_traceActivity[3U] 
                      | vlSelfRef.__Vm_traceActivity
                      [5U])))) {
        bufp->chgBit(oldp+10,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__dispatch_valid));
        bufp->chgBit(oldp+11,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__dispatch_is_load));
        bufp->chgBit(oldp+12,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__dispatch_is_store));
        bufp->chgIData(oldp+13,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__dispatch_addr),32);
        bufp->chgIData(oldp+14,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__dispatch_store_data),32);
        bufp->chgBit(oldp+15,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__rs_dispatch_valid));
        bufp->chgBit(oldp+16,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__lsq_dispatch_valid));
    }
    if (VL_UNLIKELY((vlSelfRef.__Vm_traceActivity[4U]))) {
        bufp->chgCData(oldp+17,(vlSelfRef.ooo_execution_unit_tb__DOT__rf_write_addr),5);
        bufp->chgIData(oldp+18,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__wb_data),32);
        bufp->chgBit(oldp+19,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__commit_valid));
        bufp->chgBit(oldp+20,((0x40U != (IData)(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__rob__DOT__count))));
        bufp->chgCData(oldp+21,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__dispatch_phys_reg),5);
        bufp->chgBit(oldp+22,((0x40U == (IData)(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__rob__DOT__count))));
        bufp->chgBit(oldp+23,((0U == (IData)(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__rob__DOT__count))));
        bufp->chgCData(oldp+24,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__commit_tag),5);
        bufp->chgCData(oldp+25,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__commit_phys_reg),5);
        bufp->chgBit(oldp+26,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__commit_is_load));
        bufp->chgBit(oldp+27,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__commit_is_store));
        bufp->chgBit(oldp+28,((0x20U != (IData)(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__rs__DOT__count))));
        bufp->chgCData(oldp+29,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__rs__DOT__tail_ptr),5);
        bufp->chgBit(oldp+30,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__exec_valid));
        bufp->chgIData(oldp+31,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__exec_instruction),32);
        bufp->chgIData(oldp+32,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__exec_rs1_data),32);
        bufp->chgIData(oldp+33,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__exec_rs2_data),32);
        bufp->chgBit(oldp+34,((1U & (~ (IData)(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__wb_valid)))));
        bufp->chgBit(oldp+35,((0U != (IData)(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__lsq__DOT__count))));
        bufp->chgBit(oldp+36,((0U == (IData)(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__lsq__DOT__count))));
        bufp->chgBit(oldp+37,((0U == (IData)(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__free_list__DOT__count))));
        bufp->chgCData(oldp+38,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__free_list_tag),5);
        bufp->chgBit(oldp+39,((0U != (IData)(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__free_list__DOT__count))));
        bufp->chgBit(oldp+40,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__wb_valid));
        bufp->chgCData(oldp+41,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__wb_tag),5);
        bufp->chgCData(oldp+42,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__rename_rd_tag),5);
        bufp->chgCData(oldp+43,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__free_list__DOT__count),6);
        bufp->chgCData(oldp+44,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__free_list__DOT__head_ptr),5);
        bufp->chgCData(oldp+45,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__free_list__DOT__tail_ptr),5);
        bufp->chgIData(oldp+46,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__free_list__DOT__unnamedblk1__DOT__i),32);
        bufp->chgCData(oldp+47,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__commit_tag),6);
        bufp->chgWData(oldp+48,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__lsq__DOT__entries),2336);
        bufp->chgCData(oldp+121,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__lsq__DOT__head_ptr),5);
        bufp->chgCData(oldp+122,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__lsq__DOT__tail_ptr),5);
        bufp->chgCData(oldp+123,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__lsq__DOT__count),6);
        bufp->chgIData(oldp+124,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__lsq__DOT__unnamedblk3__DOT__i),32);
        bufp->chgIData(oldp+125,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__lsq__DOT__unnamedblk4__DOT__i),32);
        bufp->chgCData(oldp+126,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__rename__DOT__rename_table[0]),5);
        bufp->chgCData(oldp+127,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__rename__DOT__rename_table[1]),5);
        bufp->chgCData(oldp+128,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__rename__DOT__rename_table[2]),5);
        bufp->chgCData(oldp+129,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__rename__DOT__rename_table[3]),5);
        bufp->chgCData(oldp+130,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__rename__DOT__rename_table[4]),5);
        bufp->chgCData(oldp+131,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__rename__DOT__rename_table[5]),5);
        bufp->chgCData(oldp+132,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__rename__DOT__rename_table[6]),5);
        bufp->chgCData(oldp+133,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__rename__DOT__rename_table[7]),5);
        bufp->chgCData(oldp+134,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__rename__DOT__rename_table[8]),5);
        bufp->chgCData(oldp+135,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__rename__DOT__rename_table[9]),5);
        bufp->chgCData(oldp+136,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__rename__DOT__rename_table[10]),5);
        bufp->chgCData(oldp+137,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__rename__DOT__rename_table[11]),5);
        bufp->chgCData(oldp+138,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__rename__DOT__rename_table[12]),5);
        bufp->chgCData(oldp+139,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__rename__DOT__rename_table[13]),5);
        bufp->chgCData(oldp+140,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__rename__DOT__rename_table[14]),5);
        bufp->chgCData(oldp+141,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__rename__DOT__rename_table[15]),5);
        bufp->chgCData(oldp+142,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__rename__DOT__rename_table[16]),5);
        bufp->chgCData(oldp+143,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__rename__DOT__rename_table[17]),5);
        bufp->chgCData(oldp+144,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__rename__DOT__rename_table[18]),5);
        bufp->chgCData(oldp+145,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__rename__DOT__rename_table[19]),5);
        bufp->chgCData(oldp+146,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__rename__DOT__rename_table[20]),5);
        bufp->chgCData(oldp+147,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__rename__DOT__rename_table[21]),5);
        bufp->chgCData(oldp+148,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__rename__DOT__rename_table[22]),5);
        bufp->chgCData(oldp+149,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__rename__DOT__rename_table[23]),5);
        bufp->chgCData(oldp+150,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__rename__DOT__rename_table[24]),5);
        bufp->chgCData(oldp+151,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__rename__DOT__rename_table[25]),5);
        bufp->chgCData(oldp+152,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__rename__DOT__rename_table[26]),5);
        bufp->chgCData(oldp+153,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__rename__DOT__rename_table[27]),5);
        bufp->chgCData(oldp+154,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__rename__DOT__rename_table[28]),5);
        bufp->chgCData(oldp+155,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__rename__DOT__rename_table[29]),5);
        bufp->chgCData(oldp+156,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__rename__DOT__rename_table[30]),5);
        bufp->chgCData(oldp+157,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__rename__DOT__rename_table[31]),5);
        bufp->chgIData(oldp+158,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__rename__DOT__unnamedblk1__DOT__i),32);
        bufp->chgIData(oldp+159,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__rename__DOT__unnamedblk2__DOT__i),32);
        bufp->chgWData(oldp+160,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__rob__DOT__entries),896);
        bufp->chgCData(oldp+188,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__rob__DOT__head_ptr),6);
        bufp->chgCData(oldp+189,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__rob__DOT__tail_ptr),6);
        bufp->chgCData(oldp+190,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__rob__DOT__count),7);
        bufp->chgIData(oldp+191,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__rob__DOT__unnamedblk1__DOT__i),32);
        bufp->chgWData(oldp+192,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__rs__DOT__entries),3488);
        bufp->chgCData(oldp+301,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__rs__DOT__head_ptr),5);
        bufp->chgCData(oldp+302,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__rs__DOT__count),6);
        bufp->chgBit(oldp+303,((0x20U == (IData)(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__rs__DOT__count))));
        bufp->chgBit(oldp+304,((0U == (IData)(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__rs__DOT__count))));
        bufp->chgIData(oldp+305,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__rs__DOT__unnamedblk1__DOT__i),32);
        bufp->chgIData(oldp+306,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__rs__DOT__unnamedblk2__DOT__i),32);
    }
    if (VL_UNLIKELY((vlSelfRef.__Vm_traceActivity[6U]))) {
        bufp->chgBit(oldp+307,(vlSelfRef.ooo_execution_unit_tb__DOT__fetch_stall));
        bufp->chgBit(oldp+308,(vlSelfRef.ooo_execution_unit_tb__DOT__mem_req_valid));
        bufp->chgBit(oldp+309,(vlSelfRef.ooo_execution_unit_tb__DOT__mem_req_is_load));
        bufp->chgIData(oldp+310,(vlSelfRef.ooo_execution_unit_tb__DOT__mem_req_addr),32);
        bufp->chgIData(oldp+311,(vlSelfRef.ooo_execution_unit_tb__DOT__mem_req_data),32);
        bufp->chgIData(oldp+312,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__lsq__DOT__unnamedblk1__DOT__i),32);
        bufp->chgCData(oldp+313,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__lsq__DOT__unnamedblk1__DOT__unnamedblk2__DOT__ptr),5);
    }
    bufp->chgBit(oldp+314,(vlSelfRef.ooo_execution_unit_tb__DOT__clk));
    bufp->chgBit(oldp+315,(vlSelfRef.ooo_execution_unit_tb__DOT__rst_n));
    bufp->chgCData(oldp+316,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__rename_rs1_tag),5);
    bufp->chgCData(oldp+317,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__rename_rs2_tag),5);
    bufp->chgBit(oldp+318,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__rename_rs1_ready));
    bufp->chgBit(oldp+319,(vlSelfRef.ooo_execution_unit_tb__DOT__dut__DOT__rename_rs2_ready));
}

void Vooo_execution_unit_tb___024root__trace_cleanup(void* voidSelf, VerilatedVcd* /*unused*/) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vooo_execution_unit_tb___024root__trace_cleanup\n"); );
    // Init
    Vooo_execution_unit_tb___024root* const __restrict vlSelf VL_ATTR_UNUSED = static_cast<Vooo_execution_unit_tb___024root*>(voidSelf);
    Vooo_execution_unit_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    // Body
    vlSymsp->__Vm_activity = false;
    vlSymsp->TOP.__Vm_traceActivity[0U] = 0U;
    vlSymsp->TOP.__Vm_traceActivity[1U] = 0U;
    vlSymsp->TOP.__Vm_traceActivity[2U] = 0U;
    vlSymsp->TOP.__Vm_traceActivity[3U] = 0U;
    vlSymsp->TOP.__Vm_traceActivity[4U] = 0U;
    vlSymsp->TOP.__Vm_traceActivity[5U] = 0U;
    vlSymsp->TOP.__Vm_traceActivity[6U] = 0U;
}
