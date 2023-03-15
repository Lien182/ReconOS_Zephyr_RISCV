export ACTDIR=$(pwd)


sudo mkdir -p /opt/riscv/
sudo chmod 777 /opt/riscv/ -R

#install zeqhyr dependencies
sudo apt-get -y install --no-install-recommends git cmake ninja-build gperf \
    ccache dfu-util device-tree-compiler wget \
    python3-dev python3-pip python3-setuptools python3-tk python3-wheel xz-utils file \
    make gcc gcc-multilib g++-multilib libsdl2-dev libmagic1  python3-venv \
    autoconf automake autotools-dev curl python3 libmpc-dev libmpfr-dev libgmp-dev \
    gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev ninja-build


#fetch submodules
git submodule update --init --recursive

# install riscv toolchain
cd riscv-gnu-toolchain
./configure --prefix=/opt/riscv --with-arch=rv32gc --with-abi=ilp32d -enable-multilib
make 

export PATH=$PATH:/opt/riscv/bin

cd ..
##
python3 -m venv ~/zephyrproject/.venv
pip install west

python3 -m west init ~/zephyrproject
cd ~/zephyrproject
python3 -m west update
python3 -m west zephyr-export
pip install -r ~/zephyrproject/zephyr/scripts/requirements.txt



#Download the zeqhyr sdk
cd ~/
wget https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.15.2/zephyr-sdk-0.15.2_linux-x86_64.tar.gz
wget -O - https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.15.2/sha256.sum | shasum --check --ignore-missing

tar xvf zephyr-sdk-0.15.2_linux-x86_64.tar.gz
cd zephyr-sdk-0.15.2
./setup.sh -h -c


##
cd $ACTDIR
cd neorv32-setups/NEORV32/sw/example/hello_world
make exe

##

echo "export ZEPHYR_TOOLCHAIN_VARIANT=cross-compile" >> ~/zephyrproject/zephyr/zephyr-env.sh
echo "export CROSS_COMPILE=/opt/riscv/bin/riscv32-unknown-elf-" >> ~/zephyrproject/zephyr/zephyr-env.sh
echo "export PATH=~/zephyr-sdk-0.15.2/riscv64-zephyr-elf/bin/:\$PATH"  >> ~/zephyrproject/zephyr/zephyr-env.sh
echo "export PATH=$ACTDIR/neorv32-setups/NEORV32/sw/image_gen/:\$PATH" >> ~/zephyrproject/zephyr/zephyr-env.sh
echo "cmake -P \$ZEPHYR_BASE/share/zephyr-package/cmake/zephyr_export.cmake" >> ~/zephyrproject/zephyr/zephyr-env.sh
echo "source activate" >> ~/zephyrproject/zephyr/zephyr-env.sh
