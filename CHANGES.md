v0.3.11
=======
+ add --fragment-mode (#246 from @LudvigOlsen). calculates coverage over a full fragment, including insert.

v0.3.10
=======
+ write sfi index in d4 files (#243)

v0.3.9
======
+ fix d4 output (#237)

v0.3.8
======
+ mosdepth is now much faster on bams/crams with a large number of contigs (#229)

v0.3.7
======
+ support CRAM v3.1. only updates htslib that binary is built with to v1.19.1 (#224)

v0.3.6
======
+ allow filtering on fragment length thanks @LudvigOlsen for implementing! (#214)
+ fix bug where empty chromosomes are not reported as having 0 depth (#216)

v0.3.5
======
+ fix bug with summary min for regions (#207 thanks to Xavier for supplying test-case)

v0.3.4
======
+ bump version for build supporting gs:// urls
+ dont error on regions larger than chromosome.

v0.3.3
======
+ allow specifying a custom index by passing '/path/to/bam##idx##/other-path/to/index.bai'

v0.3.1
======
+ fix bug with regions and d4 that would cause error even when --d4 was not used.

v0.3.0
======
+ allow chromosome names containing '-' as arguments for -c
+ d4 output

0.2.9
=====
+ modifies region.dist.txt to contain the aggregate coverage of each window when -b (integer) is specified
  (otherwise region.dist.txt and global.disk.txt are identical with -b (integer) )
+ improve speed by ~30% when using per-base output with better int2str method
  
0.2.8
=====
+ fix off-by-one error in CSI index (but not data) of output bed files (#98)

0.2.7
=====
+ small optimizations
+ exit with 1 on bad help #80
+ fix check on remote bam (brentp/hts-nim#48)
+ fix erroneous assert #99
+ update static binary to htslib 1.10 (this fixes other bugs reported and closed in mosdepth)

0.2.6
=====
+ fix #54. for quantize
+ add summary file output (implemented by @danielecook)
+ add `--median` flag to output the median for each region from --by (default is to use mean).

0.2.5
=====
+ remove dependency on PCRE
+ don't double count fully overlapping reads (thanks to @jaudoux for the fix in #73)

0.2.4
=====
+ Add optional `--include-flag` to allow counting only reads that have some bits in the specified flag set.
  This will only be used rarely--e.g. to count only supplemental reads, use `-F 0 --include-flag 2048`.
+ Fix case when only a single argument was given to --quantize
+ add --read-groups option to allow specifying that only certain read-groups should be used in the depth calculation. (#60)
+ add --fast-mode that does not look at internal cigar operations like (I)insertions or (D)eletions, but does consider soft and
  hard-clips at the end of the alignment. Also does not correct for mate overlap. This makes mosdepth as much as **2X faster for 
  CRAM** and is likely the desired mode for people using the depth for CNV or general coverage values as drops in coverage
  due to CIGAR operations are often not of interest for coverage-based analyses.

0.2.3
=====
+ fix bug in region.dist with chromosomes in bam header, but without any reads. thanks (@vladsaveliev for reporting)
+ support for chromosomes larger than 2^29. (thanks @kaspernie for reporting #41)

0.2.2
=====
+ fix overflow with huge intervals to --by
+ **NOTE** change to output file name of `*.dist.txt`. A file named `$prefix.mosdepth.global.dist.txt`
  will always be created and `$prefix.mosdepth.region.dist.txt` will be created if `--by` is specified.
  Previously, there was only a single file named `$prefix.mosdepth.dist.txt` which no longer exists.
  This allows users to, for example, use --by to see coverage of gene regions for WGS, and to see the
  global WGS coverage and the coverage in their genes of interest.
+ fix bug that would manifest with consecutive chromosomes of the same length. chromosomes other than
  the first of a given length would have incorrect values.

0.2.1
=====
+ allow unsorted bed as input to --by
+ allow setting precision with env var, e.g. `MOSDEPTH_PRECISION=5`
+ moderate performance increase.
+ build using holy-build box to better support systems with older libc.

0.2.0
=====
+ **2X speed improvement for CRAM** by not decoding unused base-qualities.
+ add new `--thresholds` argument. See README for usage. thresholds and quantization are highly recommended over
+ when using quantize, labels now indicate the range of depths encompassed by that region.
+ for quantize and per-base, mosdepth will output all chromosomes in the bam header, even if they have no alignments.
  this makes it so that mosdepth output for files aligned to the same reference have the same number and order of chromosomes
  and same total base coverage
  per-base output when possible as they are more compact and faster to output.
+ fix bug with dist output for chroms larger than 2.1 billion bases that also affected total output in some cases.
