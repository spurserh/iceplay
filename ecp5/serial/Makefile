PROJ=blinky
TRELLIS?=/usr/share/trellis

all: ${PROJ}.bit

blinky.json: blinky.v printer.v
	yosys -p "synth_ecp5 -json $@ -top top" blinky.v printer.v

%_out.config: %.json ecp5evn.lpf
	nextpnr-ecp5 --json $< --textcfg $@ --um5g-85k --package CABGA381 --lpf ecp5evn.lpf

%.bit: %_out.config
	ecppack --svf ${PROJ}.svf $< $@

${PROJ}.svf : ${PROJ}.bit

prog: ${PROJ}.svf
	openocd -f ${TRELLIS}/misc/openocd/ecp5-evn.cfg -c "transport select jtag; init; svf $<; exit"

clean:
	rm -f *.svf *.bit *.config *.json

.PHONY: prog clean
