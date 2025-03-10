#!/bin/bash
unset MOSDEPTH_Q0
unset MOSDEPTH_Q1
unset MOSDEPTH_Q2
unset MOSDEPTH_PRECISION

test -e ssshtest || wget -q https://raw.githubusercontent.com/ryanlayer/ssshtest/master/ssshtest

. ssshtest

set -o nounset


set -e
nim c --boundChecks:on -x:on -d:useSysAssert -d:useGcAssert --lineDir:on --debuginfo --mm:refc mosdepth.nim
nim c -x:on --mm:refc -d:useSysAssert -d:useGcAssert --lineDir:on --debuginfo -r tests/funcs.nim
set +e
exe=./mosdepth
bam=/data/human/NA12878.subset.bam


unset REF_PATH
run cram_no_ref $exe xx tests/tt.cram
assert_exit_code 1

run overlapM $exe t tests/ovl.bam
assert_exit_code 0
assert_equal "$(zgrep ^MT t.per-base.bed.gz)" "MT	0	80	1
MT	80	16569	0"
assert_equal "$(zgrep -w ^1 t.per-base.bed.gz)" "1	0	249250621	0"
assert_equal "$(cat t.mosdepth.summary.txt | grep 'MT')" "MT	16569	80	0.00	0	1"
assert_equal "$(cat t.mosdepth.summary.txt | grep 'total')" "total	16569	80	0.00	0	1"

run overlapFastMode $exe t --fast-mode tests/ovl.bam
assert_equal "$(zgrep ^MT t.per-base.bed.gz)" "MT	0	6	1
MT	6	42	2
MT	42	80	1
MT	80	16569	0"
assert_equal $(cat t.mosdepth.summary.txt  | cut -f 2 | tail -n+2 | sort | uniq) 16569
assert_equal $(cat t.mosdepth.summary.txt  | cut -f 4 | tail -n+2 | sort | uniq) "0.01"
assert_exit_code 0


run missing_chrom $exe -c nonexistent --by 20000 t tests/ovl.bam
assert_in_stderr "[mosdepth] chromosome nonexistent not found"
assert_exit_code 1

run unordered_bed $exe --by tests/unordered.bed t tests/ovl.bam
assert_exit_code 0
assert_equal $(zcat < t.regions.bed.gz | wc -l) 2

# theres data left in the bam but the region tree is empty...
run missing_bed_chrom $exe --by tests/missing.bed t tests/ovl.bam
assert_exit_code 0

run big_window $exe t tests/ovl.bam --by 100000000
assert_exit_code 0
assert_equal $(zgrep -c "MT" t.per-base.bed.gz) 2
assert_equal "MT	0	16569	0.00" "$(zgrep ^MT t.regions.bed.gz)"


# fragment length filtering
run length_filter $exe t tests/ovl.bam --min-frag-len 80 --max-frag-len 80
assert_exit_code 0
assert_equal $(zgrep -c "MT" t.per-base.bed.gz) 2
assert_equal "MT 0 80 1 MT 80 16569 0 " "$(zgrep ^MT t.per-base.bed.gz | tr -s '[:space:]' ' ')"

run length_filter $exe t tests/ovl.bam --min-frag-len 81
assert_exit_code 0
assert_equal "MT	0	16569	0" "$(zgrep ^MT t.per-base.bed.gz)"

run length_filter $exe t tests/ovl.bam --max-frag-len 79
assert_exit_code 0
assert_equal "MT	0	16569	0" "$(zgrep ^MT t.per-base.bed.gz)"

run bad_frag_len_filter $exe t tests/ovl.bam --min-frag-len 10 --max-frag-len 9
assert_in_stderr "--max-frag-len was lower than --min-frag-len."
assert_exit_code 2


# fragment-mode
run fragment_mode $exe t --fragment-mode tests/full-fragment-pairs.bam
assert_equal "$(zcat < t.per-base.bed.gz)" "chr22:20000000-23000000	0	17318	0
chr22:20000000-23000000	17318	17320	1
chr22:20000000-23000000	17320	17420	2
chr22:20000000-23000000	17420	17756	1
chr22:20000000-23000000	17756	52130	0
chr22:20000000-23000000	52130	52135	1
chr22:20000000-23000000	52135	52235	2
chr22:20000000-23000000	52235	52546	1
chr22:20000000-23000000	52546	3000001	0"
assert_exit_code 0

# midpoint-mode
run midpoint_mode $exe t --fragment-mode --midpoint-mode tests/full-fragment-pairs.bam
assert_equal "$(zcat < t.per-base.bed.gz)" "chr22:20000000-23000000	0	17370	0
chr22:20000000-23000000	17370	17371	1
chr22:20000000-23000000	17371	17537	0
chr22:20000000-23000000	17537	17538	1
chr22:20000000-23000000	17538	52185	0
chr22:20000000-23000000	52185	52186	1
chr22:20000000-23000000	52186	52338	0
chr22:20000000-23000000	52338	52339	1
chr22:20000000-23000000	52339	3000001	0"
assert_exit_code 0

unset MOSDEPTH_Q0
unset MOSDEPTH_Q1
unset MOSDEPTH_Q2
rm -f t.quantized.bed.gz
run quantest $exe -q 0:1:1000 t tests/ovl.bam
assert_exit_code 0
assert_equal "$(zgrep ^MT t.quantized.bed.gz)" "MT	0	80	1:1000
MT	80	16569	0:1"
assert_equal "$(zgrep -w ^1 t.quantized.bed.gz)" "1	0	249250621	0:1"

run single-quant $exe -q 60 t tests/nanopore.bam
assert_exit_code 0


rm -f t.thresholds.bed.gz*
run threshold_test $exe --by 100 -T 0,1,2,3,4,5 -c MT t tests/ovl.bam
assert_equal "$(zcat < t.thresholds.bed.gz | tail -n +2 | head -1)" "MT	0	100	unknown	100	80	0	0	0	0"
assert_equal "0" "$(zcat < t.thresholds.bed.gz | tail -n+2 | cut -f 7 | uniq)"
assert_exit_code 0

rm -f t.thresholds.bed.gz*
run threshold_test_by $exe --by tests/track.bed -T 0,1,2 -c MT t tests/ovl.bam
assert_equal "$(zcat < t.thresholds.bed.gz | tail -n +2)" "MT	2	80	aregion	78	78	0"
assert_exit_code 0

export MOSDEPTH_Q0=AAA
export MOSDEPTH_Q1=BBB
rm -f t.quantized.bed.gz t.mosdepth.global.dist.txt
MOSDEPTH_PRECISION=7 run quantest-named-and-precision $exe -q 0:1:1000 t tests/ovl.bam
assert_exit_code 0
assert_equal "$(zgrep -w ^MT t.quantized.bed.gz)" "MT	0	80	BBB
MT	80	16569	AAA"
assert_equal "$(head -1 t.mosdepth.global.dist.txt)" "MT	1	0.0048283"
assert_equal "$(tail -n +2 t.mosdepth.summary.txt | head -1)" "MT	16569	80	0.0048283	0	1"
assert_equal "$(tail -n 1 t.mosdepth.summary.txt)" "total	16569	80	0.0048283	0	1"


run track_header $exe --by tests/track.bed t tests/ovl.bam
assert_exit_code 0
assert_equal "$(zcat < t.regions.bed.gz)" "MT	2	80	aregion	1.00"

run track_header_by $exe --by tests/bad.bed t tests/ovl.bam
assert_exit_code 1
assert_in_stderr "skipping bad bed line:MT	2"
assert_in_stderr "invalid integer: asdf"


$exe -n t tests/ovl.bam
run test_read_group $exe -n tt tests/ovl.bam -R GT04008021_119
assert_equal $(cat tt.mosdepth.global.dist.txt | wc -l) 4 
assert_equal $(diff tt.mosdepth.global.dist.txt t.mosdepth.global.dist.txt | wc -l) 0
assert_exit_code 0

run test_missing_read_group $exe -n tt tests/ovl.bam -R MISSING
assert_equal "$(cat tt.mosdepth.global.dist.txt)" "MT	0	1.00
total	0	1.00"

run big_chrom $exe t tests/big.bam
assert_equal $(cat t.mosdepth.summary.txt | wc -l) 3
assert_equal $(cat t.mosdepth.summary.txt  | cut -f 3 | tail -n +2 | uniq) 15
assert_equal $(cat t.mosdepth.summary.txt  | cut -f 5 | tail -n +2 | uniq) 0
assert_equal $(cat t.mosdepth.summary.txt  | cut -f 6 | tail -n +2 | uniq) 1
assert_exit_code 0

rm -f tt.*
rm -f t.*

run empty_tids $exe t -n --thresholds 1,5 --by tests/empty-tids.bed tests/empty-tids.bam
assert_exit_code 0
assert_equal $(grep -w HPV26 -c t.mosdepth.region.dist.txt) 0
rm -f t.*

#regions and global should not be the same when -b is specified
run regions $exe t_regions -n -b 100 tests/empty-tids.bam 
assert_equal $(diff -u t_regions.mosdepth.region.dist.txt t_regions.mosdepth.global.dist.txt | wc -l) 1436
rm -f t_regions.*

run overlappingPairs $exe t tests/overlapping-pairs.bam
assert_equal "$(zcat < t.per-base.bed.gz)" "1	0	565173	0
1	565173	565253	1
1	565253	249250621	0"
assert_exit_code 0
rm -f t.*


nim c -d:d4 --boundChecks:on -x:on mosdepth.nim
rm -f t.per-base.bed.gz
run d4test $exe --d4 t --fast-mode tests/ovl.bam
assert_exit_code 0


test -e $bam || exit

run short $exe -c chrM t $bam
assert_equal "$(zgrep -w "chrM	9999	10000" t.per-base.bed.gz)" "chrM	9999	10000	19073"
assert_exit_code 0

run flag $exe -c chrM -F 4 --by 20000 tx /data/human/NA12878.subset.bam
assert_exit_code 0


run check_exit_code_on_bad_args $exe -t4prefix sample.bam
assert_exit_code 1
assert_in_stderr "error parsing arguments"




