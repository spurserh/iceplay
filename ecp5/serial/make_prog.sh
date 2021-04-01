set -e

~/xls/bazel-bin/xls/contrib/xlscc/xlscc ./serial.cc --clang_args_file ./clang.args > test.ir
~/xls/bazel-bin/xls/tools/opt_main test.ir > test.opt.ir
~/xls/bazel-bin/xls/tools/codegen_main test.opt.ir --generator combinational --entry printer > printer.v

make prog
