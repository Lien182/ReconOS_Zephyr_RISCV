# Steps to build a Zephyr based ReconOS design 

## Installation

Just run the install script.

```sh
bash install.sh
```

## Building a Zephyr-ReconOS project

First, initialize the workspace with 
```sh
source ~/zephyrproject/.venv/bin/activate && source settings.sh
```
After that, you can export and build the demos (e.g., sort_demo_zephyr) or your own project:    
    
### Software

```sh
rdk export_sw && rdk build_sw
```
    
### Hardware

```sh
rdk export_hw && rdk build_hw
```
