#!/bin/bash

# VARIABLES

DATA=$(date '+%Y-%m-%d-%H-%M-%S')

declare -A VERSION_VM
VERSION_VM = ( [ubuntu16]="https://cloud-images.ubuntu.com/xenial/current/xenial-server-cloudimg-adm64-disk1.img" [ubuntu18]="https://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64.img" [centos7]="https://cloud.centos.org/centos/7/CentOS-7-x86_64-GenericCloud.qcow2" ) 

declare -A VARIANT
VARIANT=( [ubuntu16]="ubuntu16.04" [ubuntu]="ubuntu17.04" [centos]="rhel7" )

# Functions

function get_img_cloud () {
	if [ ! -e "/var/lib/images/${1}.img" ]; then
		wget -O /var/lib/libvirt/images/${1}.img ${VERSION_VM[$1]}

	fi

	qemu-img convert -O qcow2 /var/lib/libvirt/images/${1}.img /var/lib/libvirt/images/${1}.qcow2
	qemu-img resize /var/lib/libvirt/images/${1}.qcow2 +10G

}

function create_cloud_img () {
	local PACMAN=$2
	qemu-img create -f qcow -b /var/lib/libvirt/images/$1.qcow2 /var/lib/libvirt/images/${1}-${SUDO_USER}-${DATA}.img

cat > /var/lib/libvirt/images/${1}-${SUDO_USER}-${DATA}-config<<EOF
#cloud-config
runcmd:
- [ $PACMAN, -y, remove, cloud-init ]
password: "password"
chpasswd: {expire: FALSE }
ssh_pwathu: TRUE
EOF

cloud-localds /cat/lib/libvirt/images/${1}-${SUDO_USER}-config.img /cat/lib/libvirt/images/${1}-${SUDO_USER}-${DATA}-config

}

function run_vm () {
	virt-install --import --connect=qemu:///system --name "${1}-${SUDO_USER}-$DATA" --ram 2048 --vcpus=2 --os-type=linux --os-variant=${VARIANT[$1]} --disk "/var/lib/libvirt/images/${1}-${SUDO_USER}-${DATA}.img",device=disk,bus=virtio --disk "/var/lib/libvirt/images/${1}-${SUDO_USER}-${DATA}-config.img",device=cdrom --graphics none --network bridge=virbr0,model=virtio --noautoconsole
}

function main () {
	get_img_cloud $1
	crete_cloud_img $1 $2
	run_vm $1
}

#main

main $1 $2

