// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Model implementation (design independent parts)

#include "Vooo_execution_unit_tb__pch.h"
#include "verilated_vcd_c.h"

//============================================================
// Constructors

Vooo_execution_unit_tb::Vooo_execution_unit_tb(VerilatedContext* _vcontextp__, const char* _vcname__)
    : VerilatedModel{*_vcontextp__}
    , vlSymsp{new Vooo_execution_unit_tb__Syms(contextp(), _vcname__, this)}
    , rootp{&(vlSymsp->TOP)}
{
    // Register model with the context
    contextp()->addModel(this);
    contextp()->traceBaseModelCbAdd(
        [this](VerilatedTraceBaseC* tfp, int levels, int options) { traceBaseModel(tfp, levels, options); });
}

Vooo_execution_unit_tb::Vooo_execution_unit_tb(const char* _vcname__)
    : Vooo_execution_unit_tb(Verilated::threadContextp(), _vcname__)
{
}

//============================================================
// Destructor

Vooo_execution_unit_tb::~Vooo_execution_unit_tb() {
    delete vlSymsp;
}

//============================================================
// Evaluation function

#ifdef VL_DEBUG
void Vooo_execution_unit_tb___024root___eval_debug_assertions(Vooo_execution_unit_tb___024root* vlSelf);
#endif  // VL_DEBUG
void Vooo_execution_unit_tb___024root___eval_static(Vooo_execution_unit_tb___024root* vlSelf);
void Vooo_execution_unit_tb___024root___eval_initial(Vooo_execution_unit_tb___024root* vlSelf);
void Vooo_execution_unit_tb___024root___eval_settle(Vooo_execution_unit_tb___024root* vlSelf);
void Vooo_execution_unit_tb___024root___eval(Vooo_execution_unit_tb___024root* vlSelf);

void Vooo_execution_unit_tb::eval_step() {
    VL_DEBUG_IF(VL_DBG_MSGF("+++++TOP Evaluate Vooo_execution_unit_tb::eval_step\n"); );
#ifdef VL_DEBUG
    // Debug assertions
    Vooo_execution_unit_tb___024root___eval_debug_assertions(&(vlSymsp->TOP));
#endif  // VL_DEBUG
    vlSymsp->__Vm_activity = true;
    vlSymsp->__Vm_deleter.deleteAll();
    if (VL_UNLIKELY(!vlSymsp->__Vm_didInit)) {
        vlSymsp->__Vm_didInit = true;
        VL_DEBUG_IF(VL_DBG_MSGF("+ Initial\n"););
        Vooo_execution_unit_tb___024root___eval_static(&(vlSymsp->TOP));
        Vooo_execution_unit_tb___024root___eval_initial(&(vlSymsp->TOP));
        Vooo_execution_unit_tb___024root___eval_settle(&(vlSymsp->TOP));
    }
    VL_DEBUG_IF(VL_DBG_MSGF("+ Eval\n"););
    Vooo_execution_unit_tb___024root___eval(&(vlSymsp->TOP));
    // Evaluate cleanup
    Verilated::endOfEval(vlSymsp->__Vm_evalMsgQp);
}

//============================================================
// Events and timing
bool Vooo_execution_unit_tb::eventsPending() { return !vlSymsp->TOP.__VdlySched.empty(); }

uint64_t Vooo_execution_unit_tb::nextTimeSlot() { return vlSymsp->TOP.__VdlySched.nextTimeSlot(); }

//============================================================
// Utilities

const char* Vooo_execution_unit_tb::name() const {
    return vlSymsp->name();
}

//============================================================
// Invoke final blocks

void Vooo_execution_unit_tb___024root___eval_final(Vooo_execution_unit_tb___024root* vlSelf);

VL_ATTR_COLD void Vooo_execution_unit_tb::final() {
    Vooo_execution_unit_tb___024root___eval_final(&(vlSymsp->TOP));
}

//============================================================
// Implementations of abstract methods from VerilatedModel

const char* Vooo_execution_unit_tb::hierName() const { return vlSymsp->name(); }
const char* Vooo_execution_unit_tb::modelName() const { return "Vooo_execution_unit_tb"; }
unsigned Vooo_execution_unit_tb::threads() const { return 1; }
void Vooo_execution_unit_tb::prepareClone() const { contextp()->prepareClone(); }
void Vooo_execution_unit_tb::atClone() const {
    contextp()->threadPoolpOnClone();
}
std::unique_ptr<VerilatedTraceConfig> Vooo_execution_unit_tb::traceConfig() const {
    return std::unique_ptr<VerilatedTraceConfig>{new VerilatedTraceConfig{false, false, false}};
};

//============================================================
// Trace configuration

void Vooo_execution_unit_tb___024root__trace_decl_types(VerilatedVcd* tracep);

void Vooo_execution_unit_tb___024root__trace_init_top(Vooo_execution_unit_tb___024root* vlSelf, VerilatedVcd* tracep);

VL_ATTR_COLD static void trace_init(void* voidSelf, VerilatedVcd* tracep, uint32_t code) {
    // Callback from tracep->open()
    Vooo_execution_unit_tb___024root* const __restrict vlSelf VL_ATTR_UNUSED = static_cast<Vooo_execution_unit_tb___024root*>(voidSelf);
    Vooo_execution_unit_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    if (!vlSymsp->_vm_contextp__->calcUnusedSigs()) {
        VL_FATAL_MT(__FILE__, __LINE__, __FILE__,
            "Turning on wave traces requires Verilated::traceEverOn(true) call before time 0.");
    }
    vlSymsp->__Vm_baseCode = code;
    tracep->pushPrefix(std::string{vlSymsp->name()}, VerilatedTracePrefixType::SCOPE_MODULE);
    Vooo_execution_unit_tb___024root__trace_decl_types(tracep);
    Vooo_execution_unit_tb___024root__trace_init_top(vlSelf, tracep);
    tracep->popPrefix();
}

VL_ATTR_COLD void Vooo_execution_unit_tb___024root__trace_register(Vooo_execution_unit_tb___024root* vlSelf, VerilatedVcd* tracep);

VL_ATTR_COLD void Vooo_execution_unit_tb::traceBaseModel(VerilatedTraceBaseC* tfp, int levels, int options) {
    (void)levels; (void)options;
    VerilatedVcdC* const stfp = dynamic_cast<VerilatedVcdC*>(tfp);
    if (VL_UNLIKELY(!stfp)) {
        vl_fatal(__FILE__, __LINE__, __FILE__,"'Vooo_execution_unit_tb::trace()' called on non-VerilatedVcdC object;"
            " use --trace-fst with VerilatedFst object, and --trace-vcd with VerilatedVcd object");
    }
    stfp->spTrace()->addModel(this);
    stfp->spTrace()->addInitCb(&trace_init, &(vlSymsp->TOP));
    Vooo_execution_unit_tb___024root__trace_register(&(vlSymsp->TOP), stfp->spTrace());
}
