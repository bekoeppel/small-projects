Faillog
=======

Executes a script and captures the script's output. If the script ends successfully, the output is silently discarded. If the script exits with a code != 0, the 
output is printed to STDOUT. This makes it possible to run verbose scripts, but only retain the output if the script failed.

Examples:
./fail.sh
	demo script, which will print a few lines to STDOUT and STDERR and return with exit code 1 (failure)

./fail.sh nofail
	the same demo script, but it will exit with code 0 (success)

./faillog.sh ./fail.sh
	will run `./fail.sh` (see above). Because the script fails, faillog will print it's output

./faillog.sh ./fail.sh nofail
	will run `./fail.sh nofail`, which is successful. All output is discarded
