# cpuman
Dynamic CPU throttler for preventing thermal damage during long compute runs at 100% utilization.

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

## Installing 

This is a bash script that has some prerequisites that need to be installed from standard registries like `apt`

It has `install` mode that will pull these prerequisites. If you re not on Debian then might need to adjust 
for your package manager

Once it's happy with the prerequisites and starts, drop it in `usr/local/bin` and run it. It will monitor in the bg.
You can also configure it to start on boot. 

    
