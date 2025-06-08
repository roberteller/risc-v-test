#!/bin/bash

# RISC-V Linux Build Script for Multicore Processor
# This script builds Linux 6.6 with BusyBox for testing on the RISC-V processor

set -e

# Configuration
LINUX_VERSION="6.6"
BUSYBOX_VERSION="1.35.0"
BUILDROOT_VERSION="2023.11"
CROSS_COMPILE="riscv64-linux-gnu-"
ARCH="riscv"
BUILD_DIR="$(pwd)/build"
LINUX_CONFIG="defconfig"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

check_tools() {
    log "Checking required tools..."
    
    # Check cross-compiler
    if ! command -v ${CROSS_COMPILE}gcc &> /dev/null; then
        error "RISC-V cross-compiler not found. Please install riscv64-linux-gnu-gcc"
    fi
    
    # Check device tree compiler
    if ! command -v dtc &> /dev/null; then
        error "Device tree compiler (dtc) not found. Please install device-tree-compiler"
    fi
    
    log "All required tools found"
}

setup_directories() {
    log "Setting up build directories..."
    mkdir -p $BUILD_DIR/{linux,busybox,buildroot,output,initramfs}
}

download_sources() {
    log "Downloading source code..."
    
    cd $BUILD_DIR
    
    # Download Linux kernel
    if [ ! -d "linux-${LINUX_VERSION}" ]; then
        log "Downloading Linux ${LINUX_VERSION}..."
        wget -O linux-${LINUX_VERSION}.tar.gz \
            https://github.com/torvalds/linux/archive/refs/tags/v${LINUX_VERSION}.tar.gz
        tar -xzf linux-${LINUX_VERSION}.tar.gz
    fi
    
    # Download BusyBox
    if [ ! -d "busybox-${BUSYBOX_VERSION}" ]; then
        log "Downloading BusyBox ${BUSYBOX_VERSION}..."
        wget -O busybox-${BUSYBOX_VERSION}.tar.bz2 \
            https://busybox.net/downloads/busybox-${BUSYBOX_VERSION}.tar.bz2
        tar -xjf busybox-${BUSYBOX_VERSION}.tar.bz2
    fi
}

build_busybox() {
    log "Building BusyBox..."
    
    cd $BUILD_DIR/busybox-${BUSYBOX_VERSION}
    
    # Configure BusyBox
    make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE defconfig
    
    # Enable static linking
    sed -i 's/# CONFIG_STATIC is not set/CONFIG_STATIC=y/' .config
    
    # Build BusyBox
    make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE -j$(nproc)
    
    # Install to initramfs
    make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE install \
         CONFIG_PREFIX=$BUILD_DIR/initramfs
}

create_initramfs() {
    log "Creating initramfs..."
    
    cd $BUILD_DIR/initramfs
    
    # Create basic directory structure
    mkdir -p {bin,sbin,etc,proc,sys,dev,tmp,var,lib,root,home,mnt}
    
    # Create device nodes
    sudo mknod dev/console c 5 1
    sudo mknod dev/null c 1 3
    sudo mknod dev/ttyS0 c 4 64
    
    # Create init script
    cat > init << 'EOF'
#!/bin/sh

# Mount essential filesystems
mount -t proc proc /proc
mount -t sysfs sysfs /sys
mount -t devtmpfs devtmpfs /dev

# Create additional device nodes
mknod /dev/ram0 b 1 0 2>/dev/null || true

echo "Starting RISC-V Linux on multicore processor..."
echo "Available commands: ls, cat, echo, mount, ps, top, free, df"
echo ""

# Show system information
echo "=== System Information ==="
echo "Kernel: $(uname -a)"
echo "CPU info:"
cat /proc/cpuinfo | head -20
echo ""
echo "Memory info:"
cat /proc/meminfo | head -10
echo ""

# Start shell
exec /bin/sh
EOF
    
    chmod +x init
    
    # Create fstab
    cat > etc/fstab << 'EOF'
proc            /proc           proc    defaults        0       0
sysfs           /sys            sysfs   defaults        0       0
devtmpfs        /dev            devtmpfs defaults       0       0
EOF
    
    # Create inittab
    cat > etc/inittab << 'EOF'
::sysinit:/etc/init.d/rcS
ttyS0::respawn:/sbin/getty -L ttyS0 115200 vt100
::ctrlaltdel:/sbin/reboot
::shutdown:/bin/umount -a -r
EOF
    
    # Create simple rcS
    mkdir -p etc/init.d
    cat > etc/init.d/rcS << 'EOF'
#!/bin/sh
mount -a
echo "Boot complete"
EOF
    chmod +x etc/init.d/rcS
}

build_linux_kernel() {
    log "Building Linux kernel..."
    
    cd $BUILD_DIR/linux-${LINUX_VERSION}
    
    # Apply kernel configuration
    make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE defconfig
    
    # Enable required options for our hardware
    cat >> .config << 'EOF'
CONFIG_64BIT=y
CONFIG_SMP=y
CONFIG_NR_CPUS=4
CONFIG_EARLY_PRINTK=y
CONFIG_PRINTK_TIME=y
CONFIG_SERIAL_8250=y
CONFIG_SERIAL_8250_CONSOLE=y
CONFIG_SERIAL_OF_PLATFORM=y
CONFIG_INITRAMFS_SOURCE="../initramfs"
CONFIG_INITRAMFS_ROOT_UID=0
CONFIG_INITRAMFS_ROOT_GID=0
CONFIG_DEVTMPFS=y
CONFIG_DEVTMPFS_MOUNT=y
CONFIG_BLK_DEV_RAM=y
CONFIG_BLK_DEV_RAM_SIZE=65536
CONFIG_RISCV_SBI_V01=y
CONFIG_VIRTIO=y
CONFIG_VIRTIO_MMIO=y
CONFIG_VIRTIO_BLK=y
CONFIG_EXT4_FS=y
CONFIG_PROC_FS=y
CONFIG_SYSFS=y
CONFIG_TMPFS=y
EOF
    
    # Build kernel
    make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE -j$(nproc)
    
    # Copy kernel to output
    cp arch/riscv/boot/Image $BUILD_DIR/output/
}

build_device_tree() {
    log "Building device tree..."
    
    # Copy our device tree
    cp ../devicetree.dts $BUILD_DIR/output/
    
    cd $BUILD_DIR/output
    
    # Compile device tree
    dtc -O dtb -o devicetree.dtb devicetree.dts
}

create_test_scripts() {
    log "Creating test scripts..."
    
    cd $BUILD_DIR/output
    
    # Create QEMU test script
    cat > test_qemu.sh << 'EOF'
#!/bin/bash

# Test the Linux build with QEMU
qemu-system-riscv64 \
    -machine virt \
    -cpu rv64 \
    -smp 4 \
    -m 512M \
    -nographic \
    -kernel Image \
    -dtb devicetree.dtb \
    -append "console=ttyS0,115200 earlycon root=/dev/ram0 rw"
EOF
    chmod +x test_qemu.sh
    
    # Create hardware test script
    cat > test_hardware.sh << 'EOF'
#!/bin/bash

# Deploy to actual hardware
echo "To test on hardware:"
echo "1. Load Image and devicetree.dtb into processor memory"
echo "2. Set boot address to kernel entry point"
echo "3. Configure UART for console output"
echo "4. Start processor execution"
EOF
    chmod +x test_hardware.sh
}

generate_summary() {
    log "Build complete! Summary:"
    echo ""
    echo "=== Build Artifacts ==="
    echo "Linux kernel:     $BUILD_DIR/output/Image"
    echo "Device tree:      $BUILD_DIR/output/devicetree.dtb"
    echo "Test scripts:     $BUILD_DIR/output/test_*.sh"
    echo ""
    echo "=== Next Steps ==="
    echo "1. Test with QEMU: cd $BUILD_DIR/output && ./test_qemu.sh"
    echo "2. Deploy to hardware using your processor's bootloader"
    echo "3. Run compliance tests: python3 ../../test/compliance_tests.py"
    echo "4. Run CoreMark benchmark on Linux"
    echo ""
    echo "=== Expected Features ==="
    echo "✓ 4-core SMP support"
    echo "✓ Virtual memory with Sv39"
    echo "✓ UART console"
    echo "✓ BusyBox userspace"
    echo "✓ VirtIO device support"
    echo ""
}

main() {
    log "Starting RISC-V Linux build for multicore processor"
    
    check_tools
    setup_directories
    download_sources
    build_busybox
    create_initramfs
    build_linux_kernel
    build_device_tree
    create_test_scripts
    generate_summary
    
    log "Build completed successfully!"
}

# Run main function
main "$@" 