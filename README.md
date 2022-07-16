# Swapcleaner mini project

Swapcleaner serves sole purpouse to reload swap contents back to RAM after
sufficient amount memory is free again and the system load decreased to
sensible levels. It does so simply by turning swap off and on again.

Currently it checks:
1. if 1 minute load is less than number of cores and
2. 5 minute load is lower than 1 minute load
3. then it checks if there is enough free memory and
4. whether there is enough stuff in swap already to make sure we're not fighting kernel over a few megabytes.

## Caveats
* no config file nor program options yet [^1]
* written in Haskell

[^1]: edit swapcleaner.hs
### swap_trigger_size
in kilobytes, default 500000 (500MB)

### run_every
in microseconds, default is 10_000_000 (10seconds)

## Changes

* Removed
### swap_device
path to swap, default is /swapfile
Now swap list is read from /proc/swaps

* Changed
### run_every - to 10s from 1s
