
#include "xls/contrib/xlscc/synth_only/xls_int.h"

/*
enum StateName {
	State_Wait=0,
	State_TX=1,
	State_TX_Num=2
};
*/

#define State_Wait 0
#define State_TX 1
#define State_TX_Num 2

struct State {
	XlsInt<32, true> cnt;
	XlsInt<1, false> last_fb;
	XlsInt<1, false> dbg_reg;
	XlsInt<10, false> shifter;
	XlsInt<4, false> bitcnt;
	XlsInt<8, false> char_idx;
	XlsInt<3, false> state;
	XlsInt<1, false> number;
};

typedef XlsInt<1, false> uai1;
typedef XlsInt<6, false> uai6;
typedef XlsInt<8, false> uai8;
typedef XlsInt<10, false> uai10;
typedef XlsInt<64, false> uai64;

#pragma hls_top
void printer(State &state, uai1& tx_out, uai64 word) {
	const uai10 shifter_default = 0b1000000000;
	const int B115200 = 104;

	switch(state.state) {
		case State_Wait: 
			++state.cnt;
			// TODO: Array hack
//			if(state.cnt[19]) {
			if(state.cnt.slc<1>(19)) {
				state.state = State_TX;
				state.cnt = B115200;
				state.bitcnt = 9;
				state.char_idx = ~0;
			}
			break;
		
		case State_TX: 
			if(state.cnt == B115200) {
				state.cnt = 0;

				if(state.bitcnt == 9) {
					if(state.char_idx == 8) {
						state.state = State_Wait;
						state.cnt = 0;
					} else {
						state.shifter = shifter_default;
						const uai8 c = word.slc<8>(uai6(state.char_idx) * 8);
						state.shifter.set_slc(1, c);
						++state.char_idx;
						state.bitcnt=0;
					}
				} else {
					++state.bitcnt;
//					state.shifter >>= 1;
					state.shifter = state.shifter >> 1;
				}
			} else {
				++state.cnt;
			}
			break;
	}
//	tx_out = state.shifter[0];
	tx_out = state.shifter.slc<1>(0);
}
