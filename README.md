# cpuman

Dynamic CPU throttler for preventing thermal damage during long compute runs at 100% utilization.

The utility applies max speed delta to keep the CPU temperature between 60 and 70 C. 

When temperature falls below 60 it will increase speed cap by 1/4 GHz, and when temp raises above 70 C it will drop the cap by 1/4 Ghz.

## Use cases

Any compute job that takes all CPU cores to 100% for prolonged periods will take CPU core temperature close to 90C

Most laptops will throttle automatically but on towers, especially gaming types do not by default expect prolonged
thermal load on CPUs and will have thermal protection manually configured in BIOS

This means that they can either trigger a breaker and shutdown instantly, or run at close to 100 degrees C depending
on configuration, which is bad either way. 

Gaming PCs are geared to expect bursts of 100% load but not prolonged runs of 5+ mins at full load. 

If you're running these types of activities then `cpuman` can make your PC live longer

- Long multi threaded back-testing jobs
- Running long C++ Ninja builds
- Lighmaps computations for 3D games

## Preview

```
=== Active Dynamic CPU Monitor (Press Ctrl+C to exit) ===
Timestamp: 2026-11-08 21:44:28
---------------------------------------------------------
Throttle: Unchanged (At Max Limit: 3.6 GHz | Max Temp: 38°C)
Active Speed Limit: 3.6 GHz

Core     | Core 0   | Core 1   | Core 2   | Core 3
Temp     | 38.0°C   | 38.0°C   | 37.0°C   | 38.0°C
Speed    | 2.98 GHz | 2.37 GHz | 3.00 GHz | 3.00 GHz

```

## Installing 

This is a bash script that has some prerequisites that need to be installed from standard registries like `apt`

It has `install` mode that will pull these prerequisites. If you re not on Debian then might need to adjust 
for your package manager

Once it's happy with the prerequisites and starts, drop it in `usr/local/bin` and run it. It will monitor in the bg.
You can also configure it to start on boot. 

**Note** The `formatter.sh` script needs to go to the same dir as `cpuman`

## Issues

The hard speed cap sometimes is not accurately reflected 1 for 1 due to power saving specifics:
On some hardware there will be margin above the cap, e..g cap is set at 3 Ghz but the CPU will run at 3.7.

The "hard cap" is not critical here though, since the main throttling logic is based on CPU temperature and that works 100%

TBH the hard speed cap is not necessary and I might remove it altogether.

