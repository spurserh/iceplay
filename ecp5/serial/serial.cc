
#include "xls/contrib/xlscc/synth_only/xls_int.h"

namespace {

/*
enum StateName {
	State_Wait=0,
	State_TX=1,
	State_TX_Num=2
};
*/

#define State_Wait 0
#define State_Num 1
#define State_TX 2

typedef XlsInt<1, false> uai1;
typedef XlsInt<6, false> uai6;
typedef XlsInt<8, false> uai8;
typedef XlsInt<10, false> uai10;
typedef XlsInt<32, false> uai32;
typedef XlsInt<64, false> uai64;


// Credit to https://stackoverflow.com/questions/5558492/divide-by-10-using-bit-shifts
unsigned divu10(unsigned n) {
    unsigned q, r;
    q = (n >> 1) + (n >> 2);
    q = q + (q >> 4);
    q = q + (q >> 8);
    q = q + (q >> 16);
    q = q >> 3;
    r = n - (((q << 2) + q) << 1);
    return q + (r > 9);
}

const int MAX_CHARS = 12;

}  // namespace

struct State {
	XlsInt<3, false> state;
	XlsInt<32, true> cnt;

	XlsInt<10, false> shifter;
	XlsInt<4, false> bitcnt;

	uai8 str[MAX_CHARS];
	XlsInt<8, true> next_char_idx;

	uai32 number;
//	bool newline;


	#pragma hls_top
	void printer(uai1& tx_out, uai32 number_in) {
		const uai10 shifter_default = 0b1000000000;
		const int B115200 = 104;

		switch(state) {
			case State_Wait: 
				++cnt;
				// TODO: Array hack
	//			if(this->cnt[19]) {
				if(cnt.slc<1>(21)) {
					number = number_in;

					next_char_idx=0;
					str[next_char_idx] = '\n';
					++next_char_idx;

					if(number == 0) {
						str[next_char_idx] = '0';
						++next_char_idx;
					}
					state = State_Num;
				}
				break;

			case State_Num: {
				if(number > 0) {
					const unsigned by10 = divu10(number);
					const unsigned rem10 = number - by10*10;

					number = by10;

					str[next_char_idx] = '0' + rem10;
					state = State_Num;
					next_char_idx++;
				} else {
					cnt = B115200;
					bitcnt = 9;
					--next_char_idx;
					state = State_TX;
				}
				break;
			}
			
			case State_TX: 
				if(cnt == B115200) {
					cnt = 0;

					if(bitcnt == 9) {
						if(next_char_idx<0) {
							state = State_Wait;
							cnt = 0;
						} else {
							shifter = shifter_default;

							uai8 c = str[next_char_idx];
							shifter.set_slc(1, c);
							bitcnt=0;
							--next_char_idx;
						}
					} else {
						++bitcnt;
	//					this->shifter >>= 1;
						shifter = shifter >> 1;
					}
				} else {
					++cnt;
				}
				break;
		}
	//	tx_out = this->shifter[0];
		tx_out = shifter.slc<1>(0);
	}
};



