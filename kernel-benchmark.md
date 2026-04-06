## 1.0 | Introduction
It is well-known that debug tooling in the kernel and userland can have performance impacts.
The goal of this report is to provide information on the exact extent of this impact, for reference and to properly quantify the existing knowledge.

This report benchmarks three configurations of FreeBSD: FreeBSD 15.0-RELEASE, which acts as a control, FreeBSD 16.0-CURRENT, which includes all debug tooling, and FreeBSD 16.0-CURRENT compiled with the GENERIC-NODEBUG kernel and other configuration that removes debug tooling.

## 2.0 | Methods
All benchmarks were done on an Intel NUC10i7FNH, equipped with a 12-core Intel Core i7-10710U. The CPU architecture is x86_64.

### 2.1 | Subjects
This report benchmarks 3 subjects:
- FreeBSD 15.0-RELEASE, which will be referred to as RELEASE
- FreeBSD 16.0-CURRENT, which will be referred to as CURRENT-default
- FreeBSD 16.0-CURRENT without debug tooling, which will be referred to as CURRENT-nodebug
RELEASE and CURRENT-default were installed from the memstick image provided at https://www.freebsd.org/where/.
CURRENT-nodebug was compiled from source and installed onto a pre-existing CURRENT-default system.

The configuration for CURRENT-nodebug is as follows:
`make.conf`:
```
KERNCONF=GENERIC-NODEBUG
```

`src.conf`:
```
WITH_MALLOC_PRODUCTION="YES"
WITHOUT_LLVM_ASSERTIONS="YES"
```

### 2.2 | Benchmarks
Ten benchmarks were performed on each subject:
- Boot time
- FreeBSD source build time
- Git
- Postmark
- OpenSSL SHA-256
- OSBench:
	- Create Files
	- Create Threads
	- Launch Programs
	- Create Processes
	- Memory Allocations
With the exception of boot time and source build time, these tests were performed through the [Phoronix Test Suite](https://www.phoronix-test-suite.com/).
The FreeBSD source build time was benchmarked via [hyperfine](https://github.com/sharkdp/hyperfine), with the following command, run as root:
```
hyperfine --warmup 1 --runs 2 --prepare 'make cleanworld' --export-csv ~/benchmark-build.csv 'make buildworld buildkernel -j12 CROSS_TOOLCHAIN=llvm19 -DWITHOUT_CROSS_COMPILER' 
```

Boot time was measured across three trials, using timestamps present in dmesg log output. Timestamps were enabled by adding the following line to /boot/loader.conf:

```
kern.msgbuf_show_timestamp=2
```

As described in https://man.freebsd.org/cgi/man.cgi?dmesg, this setting provides timestamps with microsecond granularity.
Boot time was measured between startup and the last non-networking timestamp, as networking is intentionally slow.
As a result, the “boot time” benchmark measures not the actual time to boot, which will be longer than the observed results, but the relative impact of different configurations on boot time.

## 3.0 | Results
**Boot time:** Boot time was measured across three trials, using timestamps present in dmesg log output. Note that this does not represent the actual time to boot, as it excludes the network stack. 

**Table 1**: Boot time (less is better)

| Subject         | Time (s) | Ratio to RELEASE |
| --------------- | -------- | ---------------- |
| RELEASE         | 2.928698 | 1.00             |
| CURRENT-default | 3.046368 | 1.04             |
| CURRENT-nodebug | 2.911390 | 0.99             |

**FreeBSD source build time:** This benchmark measures the time it takes to build the FreeBSD userland and kernel. As noted in section 2.2, this benchmark the following [hyperfine](https://github.com/sharkdp/hyperfine) command:
```
hyperfine --warmup 1 --runs 2 --prepare 'make cleanworld' --export-csv ~/benchmark-build.csv 'make buildworld buildkernel -j12 CROSS_TOOLCHAIN=llvm19 -DWITHOUT_CROSS_COMPILER -DWITH_META_MODE'
```
This benchmarks the command `make buildworld buildkernel -j12 CROSS_TOOLCHAIN=llvm19 -DWITHOUT_CROSS_COMPILER`.

Hyperfine runs it three times, with the first being a warmup run (`--warmup 1 --runs 2`) to ensure consistent conditions across tests.
Before each test run, it also does `make cleanworld` (due to the option `--prepare 'make cleanworld'`) to ensure that all artefacts from previous runs are removed.

**Table 2**: FreeBSD source build time (less is better)

| Subject         | Time (s) | Ratio to RELEASE |
| --------------- | -------- | ---------------- |
| RELEASE         | 3874     | 1.00             |
| CURRENT-default | 4798     | 1.24             |
| CURRENT-nodebug | 3727     | 0.96             |

**Git:** This is a Phoronix Test Suite benchmark, which can be found at https://openbenchmarking.org/test/pts/git.
It measures the time taken to perform some Git operations on an example repository that, from the description, “happens to be a copy of the GNOME GTK tool-kit repository”.

**Table 3**: Git (less is better)

| Subject         | Time (s) | Ratio to RELEASE |
| --------------- | -------- | ---------------- |
| RELEASE         | 54.65    | 1.00             |
| CURRENT-default | 63.22    | 1.16             |
| CURRENT-nodebug | 55.07    | 1.01             |

**Postmark:** This is a Phoronix Test Suite benchmark, which can be found at https://openbenchmarking.org/test/pts/postmark.
It tests the ability of the system to handle many small files, “similar to the tasks endured by web and mail servers”.

**Table 4**: Postmark (more is better)

| Subject         | Transactions per second (T/s) | Ratio to RELEASE |
| --------------- | -------- | ---------------- |
| RELEASE         | 12500    | 1.00             |
| CURRENT-default | 5068     | 0.41             |
| CURRENT-nodebug | 12631    | 1.01             |

**OpenSSL SHA-256:** OpenSSL is a Phoronix Test Suite benchmark set, which can be found at https://openbenchmarking.org/test/pts/openssl.
It tests the ability of the system to perform various cryptographic operations, in this case hashing data with the SHA-256 algorithm.

**Table 5**: OpenSSL SHA-256 (more is better)

| Subject         | Bytes per second (B/s) | Ratio to RELEASE |
| --------------- | ---------------------- | ---------------- |
| RELEASE         | 1562779397             | 1.00             |
| CURRENT-default | 973197260              | 0.62             |
| CURRENT-nodebug | 1568799037             | 1.00             |

### 3.1 | OSBench results
OSBench is a Phoronix Test Suite benchmark set that can be found at https://openbenchmarking.org/test/pts/osbench.
It provides several smaller benchmarks that measure the performance of common tasks. As these are largely self-explanatory, no description will be provided.

**Table 6**: Create Files (less is better)

| Subject         | Time (μs) | Ratio to RELEASE |
| --------------- | --------- | ---------------- |
| RELEASE         | 26.18     | 1.00             |
| CURRENT-default | 81.63     | 3.12             |
| CURRENT-nodebug | 25.52     | 0.97             |

**Table 7**: Create Threads (less is better)

| Subject         | Time (μs) | Ratio to RELEASE |
| --------------- | --------- | ---------------- |
| RELEASE         | 2.264977  | 1.00             |
| CURRENT-default | 3.163020  | 1.40             |
| CURRENT-nodebug | 2.279281  | 1.01             |

**Table 8**: Launch Programs (less is better)

| Subject         | Time (μs) | Ratio to RELEASE |
| --------------- | --------- | ---------------- |
| RELEASE         | 71.07     | 1.00             |
| CURRENT-default | 107.69    | 1.52             |
| CURRENT-nodebug | 77.48     | 1.09             |

**Table 9**: Create Processes (less is better)

| Subject         | Time (μs) | Ratio to RELEASE |
| --------------- | --------- | ---------------- |
| RELEASE         | 27.59     | 1.00             |
| CURRENT-default | 56.53     | 2.05             |
| CURRENT-nodebug | 27.71     | 1.00             |

**Table 10**: Memory Allocation (less is better)

| Subject         | Time (ns) | Ratio to RELEASE |
| --------------- | --------- | ---------------- |
| RELEASE         | 22.12     | 1.00             |
| CURRENT-default | 246.91    | 11.16            |
| CURRENT-nodebug | 22.71     | 1.03             |

## 4.0 | Conclusion
In all tests, -CURRENT without debug tooling remains within 4% of the performance of RELEASE.
This indicates that the settings listed above are likely sufficient for an overview of performance, although more may be required for truly and accurate results.

Debug tooling appears to cause different amounts of slowdown in different tasks. Most notable are:
1. Memory allocation, in which the debug tooling (likely that around memory allocation, which is disabled in the CURRENT-nodebug test by `WITH_PRODUCTION_MALLOC="YES"` in `src.conf`) caused a slowdown of **1016%**
2. Creating files, in which the debug tooling caused a slowdown of **212%**
3. The Postmark benchmark, in which the debug tooling caused a slowdown of **144%**

However, for more complex and varied tasks, such as the source build, booting, and Git benchmarks, the effect is reduced to between 15% and 25%.
We theorize that this is because portions of these tasks are not significantly affected by the kernel and base system.

### 4.1 | Recommendations
Those seeking to benchmark the -CURRENT development branch of FreeBSD should, at minimum, build the kernel with `KERNCONF=GENERIC-NODEBUG` and build the userland with `WITH_MALLOC_PRODUCTION="YES"` and `WITHOUT_LLVM_ASSERTS="YES"` in `src.conf`.
These options avoid the vast majority of slowdowns caused by debug tooling. As demonstrated by the source build benchmark, they may also provide benefits to developers working on FreeBSD-CURRENT systems, if the information provided by debug tooling is not necessary.
