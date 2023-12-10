#!/usr/bin/env bash

PROG=$(basename "${0%%.*}")

NC='\033[0m'              # Text Reset

# Regular Colors
Black='\033[0;30m'        # Black
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
White='\033[0;37m'        # White

if [[ $EUID != 0 ]]; then
    echo -e "${Red}${PROG} needs root permission, please call with sudo${NC}"
    exit 1
fi

if [[ $# -ne 2 ]]; then
    echo -e "${Red}${PROG} requires two args${NC}"
    echo "Usage: $0 <block device> <hostname>"
    exit 1
fi

device="${1}"
flake_host="${2}"
if [[ ! -b "${device}" ]]; then
    echo -e "${Red}${device} is not a block device${NC}"
fi

part_prefix=""
if [[ "$(basename "${device}")" =~ "nvme" ]]; then
    echo "Detected usage of nvme device"
    part_prefix="p"
fi

echo -e "${Red}Warning:${NC} ${Yellow}continuing will erase all data on: ${device}"
read -r -p "Are you sure you want to continue? [y/N]${NC}" response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
    true
else
    exit
fi

echo -e "${Green}Creating partition table on a ${device}${NC}"
dd if=/dev/zero of="${device}" bs=4M count=10
parted "${device}" -- mklabel gpt
parted "${device}" -- mkpart primary 1GB -8GB
parted "${device}" -- mkpart primary linux-swap -8GB 100%
parted "${device}" -- mkpart ESP fat32 1MB 1GB
parted "${device}" -- set 3 esp on

btrfs_part="${device}${part_prefix}1"
boot_part="${device}${part_prefix}3"
echo -e "${Green}Formatting partitions${device}${NC}"
mkswap -L swap "${device}${part_prefix}2"
mkfs.fat -F 32 -n BOOT "${device}${part_prefix}3"
mkfs.btrfs -f -L nixos "${device}${part_prefix}1"


echo -e "${Green}Mounting partitions and creating BTRFS subvolumes${NC}"
mount "${btrfs_part}" /mnt
btrfs subvolume create /mnt/@
subvols=(home var nix tmp srv opt root)
for subvol in "${subvols[@]}"; do
  echo "Creating subvol: ${subvol}..."
  btrfs subvolume create "/mnt/@${subvol}"
done
echo "Disable Copy on Write on var subvol"
chattr +C /mnt/@var

default_subvol_id=$(btrfs subvol list /mnt | awk '/@$/{print $2; exit}')
echo "Setting @ with vol id ${default_subvol_id} to default subvol"
btrfs subvolume set-default "${default_subvol_id}" /mnt

echo "Remounting BTRFS volumes with compression"
umount /mnt
mount -o compress=zstd,noatime "${btrfs_part}" /mnt
mkdir -p /mnt/{home,var,nix,tmp,srv,opt,root,boot}
for subvol in "${subvols[@]}"; do
  echo "Mounting subvol: ${subvol}..."
  mount -o compress=zstd,noatime,subvol="@${subvol}" "${btrfs_part}" "/mnt/${subvol}"
done

echo "Mounting boot partition"
mount "${boot_part}" /mnt/boot

echo "Starting nixos install"
nixos-generate-config --root /mnt
mv /mnt/etc/nixos ~/generated-config
git clone https://github.com/hurricanehrndz/nixcfg.git ~/nixcfg
# fix btrfs compression mounting
sed -e 's%\(subvol=@\w\+"\).*%\1 "noatime" "compress=zstd" ]; %' \
    "$HOME/generated-config/hardware-configuration.nix" > "${HOME}/nixcfg/nixos/machines/${flake_host}/hardware-configuration.nix"

pushd "${HOME}/nixcfg" || exit 1
git-crypt unlock
popd || exit 1

read -r -p "About to start nixos-install, press any key to continue" response

nixos-install --root /mnt --no-root-passwd --flake "${HOME}/nixcfg#${flake_host}"
