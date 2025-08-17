# Raspberry-4B-Home-Server

## Table of Contents
- [Ringkasan](#-ringkasan)
- [Fitur Utama](#-fitur-utama)
- [Prasyarat](#️-prasyarat)
- [Konfigurasi](#️-konfigurasi)
- [Instalasi](#️-instalasi)
  - [Menggunakan Instalasi Script](#menggunakan-instalasi-script)
  - [Tanpa Instalasi Script](#tanpa-instalasi-script)
    - [Update](#update)
    - [Download Dependencies](#download-dependencies)
    - [Konfigurasi Network](#konfigurasi-network)
    - [Mounting External Storage](#mounting-external-storage)
    - [Konfigurasi Samba](#konfigurasi-samba)
    - [Install Docker](#install-docker)
    - [Konfigurasi Docker (disarankan)](#konfigurasi-docker-disarankan)
    - [Akses Docker tanpa Sudo](#akses-docker-tanpa-sudo)
    - [Docker App](#docker-app)
    - [Running Docker App](#running-docker-app)
    - [Konfigurasi Pi-Hole](#konfigurasi-pi-hole)
    - [Konfigurasi NGINX](#konfigurasi-nginx)
    - [Konfigurasi Jellyfin (khusus Raspberry Pi)](#konfigurasi-jellyfin-khusus-raspberry-pi)
- [Screenshot Server Rumah](#-screenshot-home-server)

---

## 📜 Ringkasan

<img src=screenshot/home_server.jpg alt="Foto Home Server Raspberry Pi"/>
<div style="font-style: italic; text-align: center;">Home Server Raspberry Pi (abaikan debu)</div><br>

Server Rumah menggunakan Raspberry Pi (Single-Board Computer, SBC) yang memungkinkan penghuni rumah untuk mengakses layanan printer tanpa harus memusingkan lepas pasang kabel printer ke lebih dari 1 perangkat, layanan media seperti Netflix untuk menonton film maupun serial yang disukai, dan layanan pemblokiran iklan yang sering mengganggu kesenangan aktifitas berselancar di web.

Dibuat dengan ide awal ingin memungkinkan melakukan printing dokumen tanpa harus melepas-memasang kabel printer saat hendak dipakai oleh orang rumah, kemudian ide tersebut berkembang dengan ingin menambahkan media server seperti Netflix untuk menikmati film-film yang dimiliki dan DNS server untuk pemblokiran iklan saat berselancar di web.

---

## ✨ Fitur Utama
- **File Server:** Memungkinkan untuk berbagi file di seluruh jaringan dan antar OS (Operating System) seperti Windows dan Linux. Menggunakan package Samba yang memanfaatkan protocol SMB (Simple Message Block)
- **Printer Server:** Memungkinkan printing dokumen secara wireless. Menggunakan Docker App CUPS
- **Media Server:** Memungkinkan menikmati media seperti film maupun serial seperti menggunakan Netflix. Menggunakan Docker App Jellyfin
- **DNS-Server** Memungkinkan jaringan rumah memblokir iklan saat berselancar di web. Menggunakan Docker App Pi-Hole
- **Reverse Proxy:** Memungkinkan akses mudah ke layanan di atas menggunakan domain name (co. `http://jellyfin.home.server`). Menggunakan Docker App NGINX 
- **Docker Management:** Sebagai dashboard GUI untuk manajemen Docker. Menggunakan Docker App Portainer

---

## 📋 Prasyarat
Skrip yang saya gunakan diterapkan pada hardware dan software di bawah ini:

* **Perangkat Keras:**
  * Raspberry Pi 4 Model B (menggunakan Raspberry Pi 3 atau lebih baru juga memungkinkan)
  * microSD Card 16GB untuk instalasi OS
  * SUPTRONICS X872 USB3.0 to M.2 NVMe SSD Shield
  * SSD eksternal 512GB
  * Kabel Ethernet (RJ45)
  * Laptop (Untuk akses SSH ke Raspberry Pi)
  * WiFi Router / ONT Rumah
* **Perangkat Lunak:**
  * OS **Raspberry Pi OS Lite (64-bit)** (OS berbasis Debian Bookworm)
  * MobaXterm (SSH Client)

Beberapa perangkat keras di atas seperti microSD card, SSD Shield, dan SSD external tidak diharuskan sama persis

---

## ⚙️ Konfigurasi
Script ini dikhususkan untuk perangkat Raspberry Pi, khususnya perangkat yang menggunakan OS Raspbian, karena mengubah konfigurasi pada perangkat sesuai tabel di bawah ini,

| Konfigurasi | Nilai Konfigurasi |
| :--- | :--- |
| IP Address* | 192.168.1.50/24 |
| IP Gateway* | 192.168.1.1 |
| DNS* | 192.168.1.1, 8.8.8.8, 8.8.4.4 |
| Lokasi Hard Drive** | /dev/sda |
| Lokasi Mount SSD | /media/fileserver |
| Lokasi Docker | /media/fileserver/docker |
| Lokasi Config Docker App | /media/fileserver/docker-configs |

```
*IP Address, IP Gateway, dan DNS dapat disesuaikan berdasarkan kondisi jaringan rumah masing-masing, karena pada beberapa user, memiliki IP subnet yang berbeda (co. 192.168.0.1/24).

**Lokasi Hard Drive atau lokasi external storage drive yang pertama kali dikenali oleh Raspberry Pi adalah `/mnt/sda`. Untuk OS Debian, lokasi external storage drive yang pertama dikenali adalah `/mnt/sdb`

Untuk saat ini script belum saya mungkinkan untuk membaca input dari user untuk merubah konfigurasi ke-4 variabel konfigurasi di atas, sehingga untuk sementara ini harus merubah langsung pada script
```

> **Catatan:** Meski pada pernyataan di atas disebutkan bahwa 'script ini dikhususkan untuk perangkat Raspberry Pi', namun script ini juga bekerja untuk perangkat dengan OS Debian dengan sedikit perubahan value variabel pada script. Hal ini dikarenakan dalam proses pembuatan script, saya uji coba menggunakan VM (Virtual Machine) dengan OS Debian. Perubahan value 

---

## ▶️ Instalasi

### Menggunakan Instalasi Script


Instalasi menggunakan script dari repository saya memberikan benefit untuk mereka yang masih awam mengenai OS Linux, Jaringan (IP, DNS, dll.), 

Untuk penggunaan script sebagai instalasi otomatis cukup dengan meng-inputkan 2-4 command saja. Supaya directory pada Raspberry Pi masih tersusun rapih, dibuat terlebih dahulu directory khusus tempat penyimpanan script dan folder-folder pendukung. Hal ini **opsional**, namun jika ingin dilakukan dapat dengan menginputkan command-command di bawah ini,

```bash
mkdir ./home-server-project
cd ./home-server-project
```

Jika tidak terlalu mempedulikan kerapihan directory atau sudah memiliki directory khusus untuk instalasi server rumah pada repo ini, bisa langsung menginputkan 2 command di bawah ini,

```bash
git clone https://github.com/farishafidh/Raspberry-4B-Home-Server.git
sudo bash install.sh
```

Setelah instalasi script selesai, disarankan untuk me-restart perangkat server

```bash
sudo reboot
```

---

### Tanpa Instalasi Script

Instalasi tanpa script akan memberikan fleksibilitas dalam konfigurasi sesuai dengan kondisi lingkungan, seperti alamat IP maupun alamat external storage drive SSD.

Dengan asumsi perangkat server sudah memiliki akses SSH server dan laptop/pc atau perangkat lain yang digunakan bisa mengakses server melalui SSH, berikut tahapan-tahapan yang dilalui untuk membuat server rumah yang sama dengan GitHub repository ini,

- #### Update

Update package list dan package Raspberry Pi terlebih dahulu

```bash
sudo apt-get update && apt-get upgrade -y
```

- #### Download Dependencies

Download package yang diperlukan untuk server rumah ini

```bash
sudo apt-get install -y samba rsync network-manager
```

> **Catatan:** Package 'network-manager' merupakan salah satu package yang sudah terinstall pada OS Raspbian, namun pada OS Debian belum terinstall. Untuk berjaga-jaga, package tersebut tetap saya masukkan pada command di atas

- #### Konfigurasi Network

Server memerlukan alamat IP yang statik atau selalu sama, sehingga ketika sewaktu-waktu router mengalami kondisi restart, alamat IP yang digunakan oleh server selau sama dan perangkat yang memerlukan akses ke server tidak perlu mengganti alamat IP tujuan.

Konfigurasi network/jaringan perangkat sengaja ditaruh di-akhir di dalam script, sehingga instalasi menggunakan script tidak terganggu sampai akhir.

```bash
# Periksa nama network device untuk koneksi kabel / wired connection
nmcli -t -f general.devices connection show Wired\ connection\ 1 | cut -d: -f2

nmcli device modify <NETWORK_DEVICE_NAME> # eth0 untuk Raspberry Pi \
  ipv4.method manual \
  ipv4.addresses <STATIC_IP_ADDRESS> \
  ipv4.gateway <GATEWAY_ADDRESS> \
  ipv4.dns <DNS_ADDRESS>
```

Command pertama di atas akan mencari tahu nama network device untuk koneksi wired connection, network device tersebut yang kemudian akan dimodifikasi dengan command-command setelahnya. Command setelahnya mengkonfigurasi network device tersebut menjadi mode static. Sesuaikan nilai `<STATIC_IP_ADDRESS>`, `<GATEWAY_ADDRESS>`, dan `<DNS_ADDRESS>` dengan kondisi network rumah.

> **Catatan:** DNS Address pada umumnya diisi dengan Google Public DNS: 8.8.8.8 dan 8.8.4.4, bisa juga diisi hanya dengan alamat IP Gateway router. pada OS Raspian dan Debian bisa diisi dengan ketiganya. Pada OS Windows hanya bisa diisi 2 DNS address, dalam hal ini bisa cukup diisi dengan Google Public DNS

- #### Mounting External Storage

Mounting SSD atau external storage yang akan dijadikan sebagai tempat penyimpanan file, dokumen, film, Docker, dll., yang akan digunakan oleh Samba untuk file sharing, dan Docker untuk tempat penyimpanan konfigurasi, container, dan image.

> **Catatan:** Docker bisa saja tidak dipindahkan dari internal storage, namun sangat disarankan untuk dipindahkan ke storage dengan daya tampung yang lebih besar dibanding internal storage. Hal ini dikarenakan Docker App Jellyfin akan memakai tempat penyimpanan yang lebih besar dibandingkan Docker App lainnya.

```bash
sudo umount <HARD_DRIVE_PATH>
```

Command di atas opsional untuk dijalankan. Jika external storage sebelumnya sudah di-mount, disarankan untuk unmounting terlebih dahulu. Jika belum pernah di-mounting, silahkan langsung jalankan command selanjutnya

```bash
# Buat directory atau folder sebagai titik mounting external storage
sudo mkdir <MOUNT_PATH>

sudo mount <HARD_DRIVE_PATH> <MOUNT_PATH>
```

- #### Konfigurasi Samba

Untuk konfigurasi Samba, edit config file Samba menggunakan text editor seperti `nano`

```bash
sudo nano /etc/samba/smb.conf
```

Lalu tambahkan beberapa baris di bawah ini ke baris paling bawah pada config file Samba. Edit `<MOUNT_PATH>` sesuai yang dijalankan pada command `mount` di atas

```bash
[fileserver]
path = <MOUNT_PATH>
writeable = yes
browseable = yes
public = no
```

Buat user khusus untuk menggunakan Samba. Saya membuat user `user-nas`. Jika dirasa tidak perlu membuat user baru, command di bawah bisa dilewatkan

```bash
sudo adduser user-nas
```

Buat password yang akan digunakan untuk mengakses layanan Samba. Sesuaikan `<USER-SAMBA>` sesuai dengan user yang akan digunakan untuk mengakses layanan tersebut

```bash
sudo smbpasswd -a <USER-SAMA>
```

- #### Install Docker

Instalasi Docker pada Raspberry Pi (OS Raspbian) sama dengan instalasi pada OS Debian, hal pertama yang dilakukan yaitu meng-uninstall package unofficial yang sudah disediakan oleh OS tersebut

```bash
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove $pkg; done
```

Ada beberapa cara untuk instalasi Docker, cara yang saya gunakan dengan memanfaatkan `apt` repository. Cara ini memerlukan untuk terlebih dahulu menyiapkan Docker `apt` repository.

```bash
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Menambahkan repository ke source Apt:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
```

versi Docker yang digunakan pada server rumah ini menggunakan versi terbaru

```bash
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

Informasi lengkap untuk instalasi Docker dapat mengakses website [Dokumentasi Instalasi Docker](https://docs.docker.com/engine/install/debian/)

- #### Konfigurasi Docker (disarankan)

Langkah ini bertujuan untuk memindahkan lokasi konfigurasi, container, serta image Docker ke external storage yang sudah di-mount pada tahap `Mounting` di atas. Sesuai catatan pada tahap tersebut, langkah ini opsional namun disarankan.

Hentikan terlebih dahulu layanan Docker yang sudah berjalan,

```bash
sudo service docker stop

# Memeriksa layanan Docker sudah berhenti
sudo systemctl status docker
```

Edit file konfigurasi daemon Docker menggunakan text editor seperti `nano`. Ubah value `data root` dengan alamat directory Docker baru yang anda inginkan.

```bash
{
  "data-root": "/lokasi/directory/docker/baru/pada/external/storage"
}

# Contoh (Jangan ikut di-copy ke file konfigurasi daemon Docker)
{
  "data-root": "/media/extStorage/docker"
}
```

Backup terlebih dahulu directory Docker

```bash
rsync -aP /var/lib/docker /var/lib/docker.old
```

Copy directory Docker ke lokasi baru. Ubah `<NEW_DOCKER_DIR_PATH>` sesuai dengan value `data-root` pada file konfigurasi daemon Docker di atas

```bash
rsync -aP /var/lib/docker <NEW_DOCKER_DIR_PATH>
```

Informasi lengkap untuk pemindahan directory Docker dapat mengakses website [Dokumentasi Daemon Docker](https://docs.docker.com/engine/daemon/) dan [How to move docker data to another location](https://mrkandreev.name/snippets/how_to_move_docker_data_to_another_location/)

- #### Akses Docker tanpa Sudo

Akses docker melalui user selain `root` perlu menggunakan `sudo`. Untuk memungkinkan user selain `root` untuk mengakses docker, bisa menambahkan user tersebut ke group `docker`. Ubah `<USER>` dengan user yang sedang digunakan

```bash
sudo usermod -aG docker <USER>
```

Untuk memastikan penambahan user ke dalam group `docker`, restart Raspberry Pi atau perangkat yang digunakan dengan command di bawah ini, atau dengan cara lain. Tapi

```bash
sudo reboot
```

- #### Docker App

Untuk menjalankan Docker app, saya senang menggunakan `docker compose` karena dapat dengan mudah meng-update konfigurasi dari docker app seperti perubahan port, hak akses directory, lokasi volume directory untuk beberapa docker app yang perlu dimodifikasi, dll. 

Pada server rumah ini, saya menggunakan 5 Docker app: CUPS, Jellyfin, Pi-Hole, NGINX, dan Portainer. Ke 5 Docker app ini saya mengikuti tahapan pada website [Docker Hub](https://hub.docker.com/). Berikut link website untuk masing-masing Docker app yang saya gunakan:

* [CUPS](https://hub.docker.com/r/anujdatar/cups)
* [Jellyfin](https://hub.docker.com/r/linuxserver/jellyfin)
* [Pi-Hole](https://hub.docker.com/r/pihole/pihole)
* [NGINX](https://hub.docker.com/r/linuxserver/nginx)
* [Portainer](https://docs.portainer.io/start/install-ce/server/docker/linux), untuk Portainer saya tidak menemukan cara menjalankan Docker app tersebut dengan menggunakan `docker compose`

**Catatan:** NGINX dan Portainer menggunakan port yang sama, yaitu `80:TCP`. Ubah port salah satu Docker app menjadi port lain. Saya mengubah port Portainer menjadi `8088:80` 

Dalam set-up nya, saya menaruh `docker-compose.yml` untuk masing-masing Docker app pada folder yang berbeda. Hal ini mengakibatkan masing-masing Docker app akan membuat jaringan lokal nya masing-masing dan tidak dapat saling berkomunikasi. Alasan saya ingin masing-masing dari Docker app berkomunikasi, karena untuk mengakses Docker app tersebut mengharuskan menggunakan alamat website berupa IP:port (co. `192.168.1.50:631` untuk CUPS), sedangkan saya ingin supaya anggota keluarga saya ingin mengakses layanan yang disediakan oleh masing-masing Docker app, tidak perlu menggunakan IP:port, tapi menggunakan domain name (co. `jellyfin.server.rumah`), sehingga memerlukan Pi-Hole (DNS Server) dan NGINX (Reverse Proxy) saling berkomunikasi dengan masing-masing Docker app.

Ada 2 cara yang saya temukan supaya masing-masing Docker app dapat berkomunikasi:

1. Menaruh konfigurasi `docker compose` masing-masing Docker app pada 1 file `docker-compose.yml`, hal ini memungkinkan semua Docker app yang dijalankan dengan menggunakan 1 file yml tersebut berada dalam 1 jaringan docker local
2. Menaruh konfigurasi `docker compose` pada masing-masing folder, kemudian membuat jaringan docker local dan mengupdate file `docker-compose.yml` masing-masing untuk menggunakan jaringan docker local yang sudah dibuat tersebut.

Saya menggunakan cara kedua, karena cara tersebut memungkinkan saya hanya perlu meng-update 1 Docker app saja saat di masa depan saya me-modifikasi konfigurasi `docker compose` pada Docker app tersebut. Karena jika menggunakan cara pertama, saat hanya ada 1 konfigurasi `docker compose` yang dimodifikasi, maka perangkat server rumah harus menjalani proses restart untuk ke-5 Docker app tersebut. Saya rasa hal ini tidak diperlukan karena ketika hanya ada 1 layanan yang diupdate tidak perlu me-restart seluruh layanan dan membebani load perangkat server rumah.

Untuk membuat jaringan docker local baru, menggunakan command,

```bash
docker network create <NETRWORK_NAME>
```

Kemudian pada masing-masing file `docker-compose.yml`, tambahkan beberapa baris di bawah ini,

```bash
# Masukkan dalam variabel service
networks:
  - network

# Di luar variabel service
networks:
  network:
    name: <NETWORK_NAME>
    external: true
```

Berikut contoh dari file `docker-compose.yml` saya,

https://github.com/farishafidh/Raspberry-4B-Home-Server/blob/8f1808572e83259800f706264b88a9cd1fe99fdf/docker_compose_template/jellyfin/docker-compose.yml#L1-L32

<!-- ```bash
services:
  cups:
    image: anujdatar/cups
    container_name: cups
    environment:
      - CUPSADMIN=user-cups
      - CUPSPASSWORD=password_cups
      - TZ="Asia/Jakarta"
    volumes:
      - /media/extStorage/docker-configs/cups:/etc/cups
    ports:
      - 631:631
    devices:
      - /dev/bus/usb:/dev/bus/usb
    networks:
      - network
    restart: unless-stopped

networks:
  network:
    name: serverrumah
    external: true
``` -->

- #### Running Docker App

Setelah pembuatan file `docker-compose.yml` selesai, langkah terakhir hanya perlu menjalankan command di bawah ini pada masing-masing folder `docker compose`

```bash
docker compose up -d
```

Untuk memastika Docker app sudah berjalan, bisa me-running

- #### Konfigurasi Pi-Hole

DNS Server Pi-Hole akan mengarahkan lalu lintas/traffic yang mengarah ke domain name yang kita ketik pada bar alamat website pada web browser, menuju ke alamat IP yang sudah tersimpan pada database Pi-Hole (co. `printer.server.rumah -> 192.168.1.50`).

Akses Pi-Hole dengan menggunakan browser dengan alamat website `<IP_ADDRESS_SERVER>:8088/admin/` (port sesuaikan dengan konfigurasi pada file docker-compose.yml). Input password sesuai dengan nilai variabel konfigurasi `FTLCONF_webserver_api_password` pada file `docker-compose.yml` Pi-Hole.

Atur Upstream DNS Server untuk perangkat-perangkat yang menggunakan alamat IP server sebagai DNS address supaya dapat berselancar di internet. Pada dashboard Pi-Hole, di bar kiri, buka menu Settings > DNS. Di bagian `Upstream DNS Servers`, pilih salah satu dari beberapa DNS server yang disediakan oleh Pi-Hole, atau mengisi Custom DNS Server sendiri.

<img src=screenshot/pi-hole_konfig_dns.png alt="Pi-Hole Konfig Upstream DNS Servers"/>
<div style="font-style: italic; text-align: center;">Pi-Hole: Konfigurasi Upstream DNS Server</div><br>

Buat domain name untuk masing-masing layanan (printer server, dll.). Pada dashboard Pi-Hole, di bar kiri, buka menu Settings > Local DNS Record. Di bagian `List of Local DNS records`, isi domain name untuk masing-masing layanan sesuai keinginan dengan alamat IP sesuai dengan alamat IP server.

<img src=screenshot/pi-hole_konfig_dns_record.png alt="Pi-Hole Konfig Upstream DNS Servers"/>
<div style="font-style: italic; text-align: center;">Pi-Hole: Konfigurasi Local DNS Record</div>

- #### Konfigurasi NGINX

Reverse proxy akan mengarahkan traffic domain name yang diarahkan oleh Pi-Hole ke server (Raspberry Pi) menuju alamat port yang sesuai (co. `printer.server.rumah -> 192.168.1.50:631`).

Untuk konfigurasi, akses kembali server menggunakan SSH atau cara yang lain, kemudian pergi ke directory `site-confs` pada directory config NGINX. Alamat directory config NGINX sesuai dengan alamat yang sudah dikonfigurasi pada variabel `volumes` file `docker-compose.yml` NGINX.

```bash
# Contoh
cd /media/extStorage/docker-configs/nginx/nginx/site-confs
```

Buat file `server.rumah.conf` atau sesuai dengan keinginan pada directory tersebut

```bash
sudo nano server.rumah.conf
```

Isi file `.conf` tersebut seperti di bawah ini,

```bash
#Block server untuk CUPS
server {
  listen 80;
  server_name printer.server.rumah;

  location / {
    #baris ini meneruskan semua request yang mengarah ke $server_name ke IP:631>
    proxy_pass http://192.168.1.50:631;

    # Mereka mengirimkan informasi header asli CUPS
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
  }
}
.
.
.
# Buat lagi untuk masing-masing layanan
```

Restart NGINX setelah selesai membuat dan mengisi file `.conf` di atas

```bash
# pergi ke directory file docker-compose.yml NGINX
docker compose up -d
```

- #### Konfigurasi Jellyfin (khusus Raspberry Pi)

Opsi *Hardware acceleration* pada Jellyfin dapat dinyalakan untuk Raspberry Pi, namun perlu menambahkan variabel service `device` pada file `docker-compose.yml` Jellyfin.

```bash
devices:
  - /dev/video10:/dev/video10
  - /dev/video11:/dev/video11
  - /dev/video12:/dev/video12
```

Berikut contoh file `docker-compose.yml` Jellyfin saya,

https://github.com/farishafidh/Raspberry-4B-Home-Server/blob/a966fe3b7e897a65c871815f6e17aa286ce01ad9/docker_compose_template/jellyfin/docker-compose.yml#L1-L32

---

Instalasi Selesai

---

## 📸 Screenshot Server Rumah

<img src=screenshot/cups_printer_server.png alt="CUPS Printer Server Screenshot"/>
<div style="font-style: italic; text-align: center;">CUPS Printer: Server</div><br>

<img src=screenshot/cups_printer_server_result.jpg alt="CUPS Printer Server Hasil Printing"/>
<div style="font-style: italic; text-align: center;">CUPS Printer Server: Hasil Printing</div><br>

<img src=screenshot/jellyfin_media_server.png alt="Jellyfin Media Server Screenshot"/>
<div style="font-style: italic; text-align: center;">Jellyfin Media Server: Screenshot</div><br>

<img src=screenshot/pi-hole_dns_server.png alt="Pi-Hole DNS Server: Screenshot"/>
<div style="font-style: italic; text-align: center;">Pi-Hole DNS Server: Screenshot</div><br>

<img src=screenshot/portainer_management_docker.png alt="Portainer Manajemen Docker: Screenshot"/>
<div style="font-style: italic; text-align: center;">Portainer Manajemen Docker: Screenshot</div><br>
