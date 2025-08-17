#!/bin/bash

# ===================================
# Script Instalasi Projek Home Server
# ===================================

# CATATAN
# 1. CONDITIONAL STATEMENT DIGUNAKAN UNTUK ANTISIPASI SCRIPT DIJALANKAN LEBIH SEKALI DAN MENGAKIBATKAN EXIT STATUS NON-ZERO
# 2. BUAT UNINSTALL SCRIPT UNTUK MENGHAPUS KONFIGURASI

# Menghentikan script saat ada command yang gagal dijalankan
set -e

#Fungsi Bantuan Notifikasi
buat_notifikasi() {
    local pesan="--- $1 ---"
    local panjang_pesan="${#pesan}"
    local garis
    garis=$(printf "%*s" "$panjang_pesan" " " | tr " " "=")

    printf "%s\n%s\n%s\n" "$garis" "$pesan" "$garis"
}


# Start instalasi
# --- Variabel Konfigurasi ---
# Konfigurasi Network berdasarkan input user masih belum diterapkan
STATIC_IP=192.168.1.50/24
GATEWAY=192.168.1.1
DNS=192.168.1.1,8.8.8.8,8.8.4.4
HARD_DRIVE_PATH=/dev/sda #pada OS Debian, external hard drive dimulai dari SDB. Raspbian dari SDA
MOUNT_PATH=/media/extStorage
FILE_SERVER_PATH=/media/extStorage/fileserver
DOCKER_DATA_PATH=/media/extStorage/docker
DOCKER_CONFIG_PATH=/media/extStorage/
HOME_DIR_PATH=/home/"$SUDO_USER"

# --- Cek Hak Akses Root ---
buat_notifikasi "Memeriksa akses root..."
if [ "$EUID" -ne 0 ]; then
    buat_notifikasi "Harap jalankan script ini sebagai user dengan hak akses root atau menggunakan sudo"
    exit 1
fi
buat_notifikasi "Hak akses root terdeteksi. Melanjutkan proses instalasi"

# --- Update Sistem ---
fungsi_update_sistem(){
    buat_notifikasi "Meng-update Sistem..."
    apt-get update && apt-get upgrade -y
    buat_notifikasi "Update Sistem Berhasil!"
}

# --- Mount Storage untuk File Server ---
fungsi_mount_storage() {
    buat_notifikasi "Mounting Storage..."
    # Next version: add a function to allow user to input their hard_drive_name and check if it's available/readable on system
    # Gunakan sudo fdisk -l untuk memeriksa nama hard drive yang hendak digunakan
    local TIPE_DEVICE
    local UUID_DEVICE
    TIPE_DEVICE=$(blkid -s TYPE -o value "$HARD_DRIVE_PATH")
    UUID_DEVICE=$(blkid -s UUID -o value "$HARD_DRIVE_PATH")

    # Memeriksa jika storage belum memiliki filesystem format
    if [ -z "$TIPE_DEVICE" ] || [ -z "$UUID_DEVICE" ]; then
        printf "Storage yang diharapkan belum memiliki filesystem format"
        exit 1
    fi

    # Memeriksa tipe filesystem storage
    if [ "$TIPE_DEVICE" != "ext4" ]; then
        printf "Harap menggunakan storage dengan tipe filesystem EXT4"
        exit 1
    fi
    
    # Unmount storage jika sudah di-mounting ke sebuah directory
    ## Note for myself: Kalau storage sudah di-mounting dan command mount di-execute kembali, akan menghasilkan command exit dengan non-zero status
    if grep -qs "$HARD_DRIVE_PATH" /proc/mounts; then
        umount "$HARD_DRIVE_PATH"
    fi

    # Mounting
    if [ ! -d "$MOUNT_PATH" ]; then
        mkdir "$MOUNT_PATH"
    fi
    mount "$HARD_DRIVE_PATH" "$MOUNT_PATH"

    # Konfigurasi dan Backup fstab
    if [ ! -f /etc/fstab.backup ]; then
        # Menghindari kasus script dijalankan lebih dari sekali sehingga backup fstab sudah bukan bawaan default lagi
        cp /etc/fstab /etc/fstab.backup
    fi
    if ! grep -qs "$HARD_DRIVE_PATH" /etc/fstab; then
        # Menghindari kasus script dijalankan lebih dari sekali sehingga entry menjadi duplikat
        echo ""$UUID_DEVICE" "$HARD_DRIVE_PATH" "$TIPE_DEVICE" defaults,auto,users,rw,nofail,noatime 0 0" | tee -a /etc/fstab > /dev/null
    fi
    systemctl daemon-reload
    buat_notifikasi "Mounting Storage Berhasil!"
} 

# --- Install dan Konfigurasi SAMBA ---
fungsi_install_samba() {
    buat_notifikasi "Meng-install dan konfigurasi Samba..."
    apt-get install -y samba
    if ! grep -qs /media/extStorage/fileserver /etc/samba/smb.conf; then
        printf "[fileserver]\npath = "$MOUNT_PATH"\nwriteable = yes\nbrowseable = yes\npublic = no" | tee -a /etc/samba/smb.conf > /dev/null
    fi

    # Membuat user untuk akses Samba Share
    buat_notifikasi "Buat Password untuk Akses Samba Share"
    local USER_SAMBA=user-nas
    printf "Untuk saat ini username menggunakan "user-nas".\nSilahkan cek dokumentasi di Git Repo\n"

    # Membuat user untuk samba
    if [ -z "$(id "$USER_SAMBA")" ]; then
        adduser "$USER_SAMBA"
    fi

    # Untuk saat ini belum menemukan solusi jika saat script dijalankan lebih dari sekali karena suatu masalah,
    # kemudian menginput samba-password yang sama akan memberikan command exit non-zero karena password yang diinputkan sama dengan sebelumnya.
    # Solusi sementara:
    # 1. Memeriksa apakah user tersebut sudah memiliki samba-password kemudian command smbpasswd akan dilewati
    # 2. Meng-input kan password yang berbeda saat inisialisasi script kemudian mengubahnya kembali setelah instalasi script selesai
    # Saya memutuskan menggunakan solusi #1
    if [ -z "$(pdbedit -L | grep "$USER_SAMBA")" ]; then
        smbpasswd -a "$USER_SAMBA"
    else
        echo "User Sudah Memiliki Password Samba"
    fi
    chown -R "$USER_SAMBA":"$USER_SAMBA" "$MOUNT_PATH"
    buat_notifikasi "Install dan Konfigurasi Samba Berhasil!"
}

# --- Install Docker ---
fungsi_install_docker() {
    buat_notifikasi "Menginstall Docker..."
    # --- Menambahkan GPG Key Docker ---
    apt-get install ca-certificates curl
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc

    # --- Meng-uninstall Package Docker yang Unofficial dari Debian ---
    for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do apt-get remove $pkg; done

    # --- Menambahkan Repository untuk menemukan package Docker ---
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
        $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
        tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update

    # --- Menginstall Docker Versi Terbaru ---
    apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
    
    # --- Menambahkan User ke Group Docker ---
    echo "Menambahkan user ke Docker group..."
    usermod -aG docker "$SUDO_USER"
    echo "User berhasil ditambahkan ke Docker group!"
    buat_notifikasi "Install Docker Berhasil!"
}

# --- Memindahkan Data Docker ke SSD ---
fungsi_pindah_data_docker() {
    buat_notifikasi "Memindahkan Data Docker ke SSD..."
    service docker stop
    printf '{"data-root": "'"$DOCKER_DATA_PATH"'"}' | tee /etc/docker/daemon.json > /dev/null
    apt-get install -y rsync
    rsync -aP /var/lib/docker "$DOCKER_DATA_PATH"
    
    # Backup /var/lib/docker
    if [ ! -d /var/lib/docker.old ]; then
        rsync -aP /var/lib/docker /var/lib/docker.old
    fi
    service docker start
    buat_notifikasi "Pemindahan Data Docker ke SSD Berhasil!"
}

# --- Menambahkan Template Docker Compose ---
fungsi_menambahkan_docker_compose_template() {
    buat_notifikasi "Menambahkan Template Docker Compose..."
    rsync -aP ./docker_compose_template "$HOME_DIR_PATH"
    buat_notifikasi "Berhasil menambahkan Template Docker Compose!"
}

# --- Memindahkan File Config App ---
fungsi_menambahkan_config_file_docker_apps() {
    buat_notifikasi "Menambahkan Config File Docker App..."
    rsync -aP ./docker-configs "$DOCKER_CONFIG_PATH"
    buat_notifikasi "Penambahan Config File Docker App Berhasil!"
}

# --- Membuat Network Docker ---
fungsi_membuat_network_docker() {
    buat_notifikasi "Membuat Network Docker..."
    # Berjaga-jaga script sudah dijalankan sebelumnya dan Network Docker sudah berhasil dibuat
    if [ -z "$(docker network ls | grep serverrumah)" ]; then
        docker network create serverrumah
    fi
    buat_notifikasi "Pembuatan Network Docker Berhasil!"
}

# --- Me-running App menggunakan Docker Compose ---
fungsi_run_docker_app() {
    buat_notifikasi "Menjalankan Docker Apps..."
    cd "$HOME_DIR_PATH"/docker_compose_template
    # --- Me-running Docker App CUPS (Print Server) ---
    # Pada debian, cups package sudah built-in pada OS tersebut, sehingga sevice tersebut perlu di-disable terlebih dahulu
    systemctl stop cups
    systemctl disable cups
    cd ./cups
    docker compose up -d
    buat_notifikasi "Print Server berhasil dijalankan!"
    # --- Me-running Docker App Jellyfin (Media Server) ---
    cd ../jellyfin
    docker compose up -d
    buat_notifikasi "Media Server berhasil dijalankan!"
    # --- Me-running Docker App Pi-Hole (DNS Server) ---
    cd ../pihole
    docker compose up -d
    buat_notifikasi "DNS Server berhasil dijalankan!"
    # --- Me-running Docker App NGNIX (Reverse Proxy Server) ---
    cd ../nginx
    docker compose up -d
    buat_notifikasi "Reverse Proxy Server berhasil dijalankan!"
    # -- Me-running Docker App Portainer (Container App Management) ---
    cd ..
    docker run -d -p 8000:8000 -p 9443:9443 -p 9000:9000 \
    --name portainer \
    --restart=always \
    -v /var/run/docker.sock:/var/run/docker.sock -v /media/extStorage/docker-services/portainer:/data \
    portainer/portainer-ce:lts
    buat_notifikasi "Portainer berhasil dijalankan!"

    buat_notifikasi "Semua Docker App berhasil dijalankan!"
}

# --- Konfigurasi Network ---
fungsi_konfigurasi_network() {
    buat_notifikasi "Mengubah Konfigurasi Network..."
    apt-get install network-manager -y
    local NAMA_NETWORK_DEVICE=$(nmcli -t -f general.devices connection show Wired\ connection\ 1 | cut -d: -f2)
    nmcli device modify "$NAMA_NETWORK_DEVICE" \
        ipv4.method manual \
        ipv4.addresses "$STATIC_IP" \
        ipv4.gateway "$GATEWAY" \
        ipv4.dns "$DNS"
    buat_notifikasi "Anda akan terputus dari akses SSH karena IP sudah berbeda, mohon akses kembali menggunakan IP 192.168.1.50" 
    systemctl restart NetworkManager
}

main(){
    buat_notifikasi "Memulai Instalasi Home Server by Faris"
    fungsi_update_sistem
    fungsi_mount_storage
    fungsi_install_samba
    fungsi_install_docker
    fungsi_pindah_data_docker
    fungsi_menambahkan_docker_compose_template
    fungsi_menambahkan_config_file_docker_apps
    fungsi_membuat_network_docker
    fungsi_run_docker_app
    fungsi_konfigurasi_network
    buat_notifikasi "Instalasi Home Server Berhasil!"
}

main

# Jika ada kritik maupun saran, bisa disampaikan di GitHub Repository saya