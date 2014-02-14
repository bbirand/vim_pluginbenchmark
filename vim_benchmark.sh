#
# Check the loading time of the various vundle scripts
#

# Defaults

# Location of vimrc
VIMRC="$HOME/.vimrc"

# Location of the vim file
VIM=/Applications/MacVim.app/Contents/MacOS/Vim

# Number of runs
NO_RUN=10


########### ########### ########### ###########
########### ########### ########### ###########

SLEEP_SEC=0.5

function show_help {
  echo "$0: -f -c"
}

while getopts "h?v:r:n:" opt; do
    case "$opt" in
    h|\?)
        show_help
        exit 0
        ;;
    v)  VIM=$OPTARG 
        ;;
    r)  VIMRC=$OPTARG
        ;;
    n)  NO_RUN=$OPTARG
        ;;
    esac
done

echo "Using vimrc: $VIMRC"
echo "Using vim: $VIM"

# Count the "header" portion
# This is the part up to the first Bundle
HEADER_LINE=$(cat $VIMRC | grep -n 'Bundle' |cut -d: -f 1 | head -n 1)
#echo "Header line is ", $HEADER_LINE

# Separate vim file
head -n $(($HEADER_LINE)) $VIMRC > vimrc_top
grep -v '^Bundle' $VIMRC | tail -n +$(($HEADER_LINE+1)) > vimrc_bottom
grep '^Bundle' $VIMRC | grep -v 'gmarik/vundle' > vimrc_bundles
grep '^Bundle' $VIMRC | grep 'NO_BENCHMARK' > vimrc_nobm_bundles

# Read the bundles into array
IFS=$'\r\n' BUNDLES=($(cat vimrc_bundles))
BUNDLE_NO=${#BUNDLES[@]}

#
# Launch empty for cold-start
#
$VIM -u NONE +:q 
$VIM +:q 

#
# No bundles (just the rest of the vimrc)
#
TOT=0  # running sum in nanoseconds
for t in $(seq $NO_RUN); do
  cat vimrc_top > vimrc_testing
  cat vimrc_nobm_bundles >> vimrc_testing
  cat vimrc_bottom >> vimrc_testing
  sleep $SLEEP_SEC
  S=$(date +%s.%N)
  $VIM -u vimrc_testing +:q 
  E=$(date +%s.%N)
  TOT=$(echo "$TOT + ($E - $S)" | bc -l)
done
NTIME=$(echo "($TOT / $NO_RUN)" | bc -l)
#echo -e "NONE:\t\t\t$NTIME ms"
printf "%-30.30s: %10f ms\n" NONE $(echo "$NTIME * 1000" | bc -l)

#
# Bundles
#
for n in $(seq 0 $(($BUNDLE_NO-1)) );
do
  B=${BUNDLES[n]}
  #echo $B

  cat vimrc_top > vimrc_testing
  cat vimrc_nobm_bundles >> vimrc_testing
  echo $B >> vimrc_testing
  cat vimrc_bottom >> vimrc_testing

  BNAME=$(echo $B | sed "s/.*'\(.*\)'.*$/\1/")

  TOT=0  # running sum in nanoseconds
  for t in $(seq $NO_RUN); do
    sleep $SLEEP_SEC
    S=$(date +%s.%N)
    $VIM -u vimrc_testing +:q
    E=$(date +%s.%N)
    TOT=$(echo "$TOT + ($E - $S)" | bc -l)
  done
  BTIME=$(echo "(($TOT / $NO_RUN)- $NTIME) *1000" | bc -l)

  #echo -e "$BNAME:\t\t\t$BTIME ms"
  printf "%-30.30s: %10f ms\n" $BNAME $BTIME
done

# clean-up
rm -f vimrc_bundles vimrc_testing vimrc_top vimrc_nobm_bundles vimrc_bottom
