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

echo -e "${Red}Warning:${NC} ${Yellow}continuing will erase all data on: ${device}${NC}"
read -r -p "Are you sure you want to continue? [y/N]" response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
    true
else
    exit
fi

echo -e "${Green}Creating partition table on a ${device}${NC}"
sudo dd if=/dev/zero of="${device}" bs=4M count=10
sudo parted "${device}" -- mklabel gpt
sudo parted "${device}" -- mkpart primary 1GB -8GB
sudo parted "${device}" -- mkpart primary linux-swap -8GB 100%
sudo parted "${device}" -- mkpart ESP fat32 1MB 1GB
sudo parted "${device}" -- set 3 esp on

echo -e "${Green}Formatting partitions${device}${NC}"
btrfs_part="${device}${part_prefix}1"
boot_part="${device}${part_prefix}3"
swap_part="${device}${part_prefix}2"
sudo mkswap -L swap "${swap_part}"
sudo mkfs.fat -F 32 -n BOOT "${boot_part}"
sudo mkfs.btrfs -f -L nixos "${btrfs_part}"


echo -e "${Green}Mounting partitions and creating BTRFS subvolumes${NC}"
subvols=(home var nix tmp srv opt root)
sudo mount "${btrfs_part}" /mnt
sudo btrfs subvolume create /mnt/@
for subvol in "${subvols[@]}"; do
  echo "Creating subvol: ${subvol}..."
  sudo btrfs subvolume create "/mnt/@${subvol}"
done
echo "Disable Copy on Write on var subvol"
sudo chattr +C /mnt/@var

default_subvol_id=$(sudo btrfs subvol list /mnt | awk '/@$/{print $2; exit}')
echo "Setting @ with vol id ${default_subvol_id} to default subvol"
sudo btrfs subvolume set-default "${default_subvol_id}" /mnt

echo "Remounting BTRFS volumes with compression"
sudo umount /mnt
sudo mount -o compress=zstd,noatime "${btrfs_part}" /mnt
sudo mkdir -p /mnt/{home,var,nix,tmp,srv,opt,root,boot}
for subvol in "${subvols[@]}"; do
  echo "Mounting subvol: ${subvol}..."
  sudo mount -o compress=zstd,noatime,subvol="@${subvol}" "${btrfs_part}" "/mnt/${subvol}"
done

echo "Mounting boot partition"
sudo mount "${boot_part}" /mnt/boot

echo "Starting nixos install"
sudo nixos-generate-config --root /mnt
sudo mv /mnt/etc/nixos "${HOME}/generated-config"

if [[ ! -d "${HOME}/nixcfg" ]]; then
    echo -e "${Red} nixcfg missing${NC}"
    exit 1
fi

# fix btrfs compression mounting
sed -e 's%\(subvol=@\w*"\).*%\1 "noatime" "compress=zstd" ];%' \
    "$HOME/generated-config/hardware-configuration.nix" >|"${HOME}/nixcfg/nixos/machines/${flake_host}/hardware-configuration.nix"

# fix swap
swap_uuid=$(sudo blkid "${swap_part}" | awk 'match($0, /UUID="(\S+)"/, m) {print m[1]}')
sed -i -e "s%swapDevices.*%swapDevices = [ { device = \"/dev/disk/by-uuid/${swap_uuid}\"; } ];%" \
    "${HOME}/nixcfg/nixos/machines/${flake_host}/hardware-configuration.nix"

echo -e "${Red}Check hardware-configuration for machine, make sure swap and root are correct${NC}"
echo ""
echo -e "${Yellow}Run the following command to complete installation:${NC}"
echo ""
echo -e "${Green}sudo nixos-install --root /mnt --no-root-passwd --flake \"${HOME}/nixcfg#${flake_host}\" --override-input bootstrap path:./bootstrap-flags/true${NC}"
echo ""
echo -e "${Yellow}The --override-input bootstrap flag disables agenix secrets during initial install.${NC}"
echo -e "${Yellow}After first boot, run: sudo nixos-rebuild switch --flake .#${flake_host}${NC}"
