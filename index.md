# Tutoriel : Installer Arch Linux en Dual Boot sur un MacBook Pro 2017

Ce guide résume les étapes nécessaires pour installer Arch Linux en dual boot avec macOS sur un MacBook Pro 15,4 de 2017 (chipset Intel), en utilisant rEFInd comme gestionnaire de démarrage. Il est basé sur un processus d'installation réel et se concentre sur la méthode qui a fonctionné.

## Étape 1 : Préparation dans macOS

La première étape consiste à faire de la place pour Arch Linux depuis macOS.

1.  **Ouvrir l'Utilitaire de disque** : Lancez l'Utilitaire de disque sur macOS.
2.  **Réduire le conteneur APFS** :
    *   Sélectionnez votre disque principal (le conteneur APFS, pas seulement le volume "Macintosh HD").
    *   Cliquez sur "Partitionner".
    *   Réduisez la taille du conteneur APFS pour libérer l'espace souhaité pour Arch Linux (par exemple, 150 Go).
3.  **Gérer le nouvel espace** : macOS va probablement créer un nouveau volume APFS dans l'espace libéré.
    *   Sélectionnez ce nouveau volume APFS vide.
    *   Cliquez sur le bouton "—" (moins) pour le supprimer.
    *   L'objectif est d'avoir de l'**espace libre** non alloué. Ne vous inquiétez pas si macOS le nomme "volume APFS sans titre", les outils Linux sauront le gérer.

## Étape 2 : Création de la clé USB bootable Arch Linux

1.  **Télécharger l'ISO** : Récupérez la dernière image ISO d'Arch Linux depuis le [site officiel](https://archlinux.org/download/).
2.  **Créer la clé USB** : Utilisez un outil comme `dd`, Etcher ou Rufus pour flasher l'image ISO sur une clé USB.

## Étape 3 : Démarrage et configuration initiale

1.  **Démarrer sur la clé USB** : Redémarrez votre Mac en maintenant la touche **Option (⌥)** enfoncée. Sélectionnez la clé USB (généralement affichée comme "EFI Boot") dans le menu de démarrage.
2.  **Choisir le mode de démarrage** : Dans le menu d'Arch Linux, sélectionnez l'option `Arch Linux install medium (x86_64, UEFI)`.
3.  **Configurer le clavier en AZERTY** : Pour faciliter la saisie, passez le clavier en AZERTY.
    ```bash
    loadkeys fr
    ```
4.  **Connexion Internet** : Assurez-vous d'avoir une connexion Internet. Pour ce MacBook, un adaptateur USB-C vers Ethernet a été utilisé et a fonctionné sans configuration supplémentaire.

## Étape 4 : Partitionnement du disque

1.  **Identifier le disque** : Listez les disques pour trouver l'identifiant de votre SSD interne.
    ```bash
    lsblk
    ```
    *(Le disque était `/dev/nvme0n1` dans ce cas)*.

2.  **Lancer l'outil de partitionnement** :
    ```bash
    cfdisk /dev/nvme0n1
    ```
3.  **Partitionner** :
    *   Naviguez jusqu'à la partition de 150 Go (identifiée comme "Apple APFS") et sélectionnez `Delete`. Cela la transformera en `Free space`.
    *   Sur cet espace libre, créez vos partitions Linux :
        *   **Partition Racine (`/`)** : Sélectionnez `New`, choisissez la taille (ex: `130G`), et laissez le type par défaut `Linux filesystem`.
        *   **Partition Swap** : Sur l'espace libre restant, sélectionnez `New`, choisissez la taille (ex: `20G`), puis changez le `Type` en `Linux swap`.
    *   **Ne touchez pas** à la petite partition `EFI System` existante (ex: `/dev/nvme0n1p1`).
    *   Sélectionnez `Write`, tapez `yes`, puis `Quit`.

## Étape 5 : Formatage et montage des partitions

1.  **Formater les partitions** :
    ```bash
    # Formater la partition racine en ext4 (adaptez p3 si besoin)
    mkfs.ext4 /dev/nvme0n1p3

    # Initialiser la partition swap (adaptez p4 si besoin)
    mkswap /dev/nvme0n1p4
    ```
2.  **Monter les partitions** :
    ```bash
    # Monter la partition racine
    mount /dev/nvme0n1p3 /mnt

    # Activer le swap
    swapon /dev/nvme0n1p4

    # Créer le point de montage pour l'EFI et la monter
    mkdir -p /mnt/boot
    mount /dev/nvme0n1p1 /mnt/boot
    ```

## Étape 6 : Installation du système de base

1.  **Installer les paquets de base** : `linux-firmware` est crucial pour le support matériel, notamment le Wi-Fi Broadcom.
    ```bash
    pacstrap /mnt base linux linux-firmware
    ```
2.  **Générer le fstab** : Ce fichier définit comment les partitions sont montées au démarrage.
    ```bash
    genfstab -U /mnt >> /mnt/etc/fstab
    ```

## Étape 7 : Configuration du système (chroot)

1.  **Entrer dans le nouveau système** :
    ```bash
    arch-chroot /mnt
    ```
2.  **Configurer le fuseau horaire** :
    ```bash
    ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
    hwclock --systohc
    ```
3.  **Configurer la langue** :
    ```bash
    # Décommenter fr_FR.UTF-8 UTF-8
    sed -i 's/^#fr_FR.UTF-8 UTF-8/fr_FR.UTF-8 UTF-8/' /etc/locale.gen
    locale-gen
    echo "LANG=fr_FR.UTF-8" > /etc/locale.conf
    ```
4.  **Configurer le clavier pour la console** :
    ```bash
    echo "KEYMAP=fr" > /etc/vconsole.conf
    ```
5.  **Définir le nom de la machine** :
    ```bash
    echo "monmacarch" > /etc/hostname
    ```
6.  **Définir le mot de passe root** :
    ```bash
    passwd
    ```
7.  **Installer les paquets essentiels** pour la post-installation (réseau, sudo, éditeur).
    ```bash
    pacman -S networkmanager sudo nano
    ```
8.  **Activer le gestionnaire de réseau** pour qu'il se lance au démarrage.
    ```bash
    systemctl enable NetworkManager
    ```
9.  **Créer un utilisateur** :
    ```bash
    useradd -m -G wheel votre_nom_utilisateur
    passwd votre_nom_utilisateur
    ```
10. **Configurer sudo** :
    ```bash
    EDITOR=nano visudo
    ```
    Décommentez la ligne `%wheel ALL=(ALL:ALL) ALL` pour autoriser les utilisateurs du groupe `wheel` à utiliser `sudo`.

## Étape 8 : Installation et correction du bootloader (rEFInd)

C'est l'étape la plus critique qui a causé des erreurs lors de l'installation initiale.

1.  **Installer rEFInd** :
    ```bash
    pacman -S refind
    refind-install
    ```
2.  **Corriger la configuration de rEFInd** : `refind-install` peut créer un fichier de configuration erroné basé sur l'environnement de la clé USB. Il faut le remplacer par une configuration pointant vers votre installation réelle.

    *Remplacez `1c8b680a-3267-484c-9f4c-76b945e9611a` par l'UUID de votre partition racine (`/`), que vous pouvez vérifier avec `blkid`.*

    ```bash
    # Crée et écrase le fichier avec la bonne configuration pour l'entrée de démarrage principale
    echo '"Arch Linux" "root=UUID=1c8b680a-3267-484c-9f4c-76b945e9611a rw initrd=\initramfs-linux.img"' > /boot/refind_linux.conf

    # Ajoute l'entrée de démarrage de secours
    echo '"Arch Linux (fallback)" "root=UUID=1c8b680a-3267-484c-9f4c-76b945e9611a rw initrd=\initramfs-linux-fallback.img"' >> /boot/refind_linux.conf
    ```

## Étape 9 : Finalisation

1.  **Quitter le chroot** :
    ```bash
    exit
    ```
2.  **Démonter les partitions** :
    ```bash
    umount -R /mnt
    ```
3.  **Redémarrer** :
    ```bash
    reboot
    ```
    Retirez la clé USB dès que l'ordinateur redémarre.

## Post-installation

Au redémarrage, le menu de rEFInd devrait apparaître. Choisissez "Arch Linux" (l'icône avec le manchot Tux). Vous devriez arriver à l'écran de connexion en mode console.

*   **Réseau** : Connectez-vous et utilisez `nmtui` pour configurer facilement votre connexion Wi-Fi ou Ethernet.
*   **Environnement graphique** : Vous êtes maintenant prêt à installer Hyprland, un serveur d'affichage (Xorg ou Wayland), des pilotes graphiques, etc.

Ce tutoriel devrait vous fournir un chemin clair pour reproduire l'installation avec succès.
