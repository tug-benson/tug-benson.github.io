---
layout: post
title: "Configuration Audio, Thunar et Waybar sur Arch Linux"
date: 2025-08-07
category: Linux
---

# Résumé de la configuration du 2025-08-07

## Sujet : Thunar, Waybar, et configuration audio PipeWire

### 1. Thunar : "Open Terminal Here" avec Alacritty

- **Problème :** L'action "Ouvrir un terminal ici" dans Thunar ne fonctionnait pas.
- **Solution :** Modification du fichier `~/.config/Thunar/uca.xml` pour utiliser Alacritty directement.
- **Commande remplacée :** La commande `exo-open --working-directory %f --launch TerminalEmulator` a été remplacée par `alacritty --working-directory %f`.

### 2. Waybar : Affichage du contrôle du son

- **Problème :** L'icône du volume n'apparaissait pas dans Waybar.
- **Solutions :**
  1.  Remplacement du module `pulseaudio` par `wireplumber` dans `~/.config/waybar/config`.
  2.  Correction de la configuration du module `wireplumber` en retirant les options invalides (comme `tooltip-format`).
  3.  Résolution de l'erreur `colorpicker.sh: Aucun fichier ou dossier de ce nom` en créant un script placeholder exécutable.

### 3. PipeWire : Gestion des périphériques audio

- **Problème :** Impossible de changer la sortie audio vers le casque USB-C, et `pavucontrol` restait bloqué sur "Connexion...".
- **Diagnostic :** Le paquet `pipewire-pulse`, nécessaire pour la compatibilité avec `pavucontrol`, n'était pas installé.
- **Solutions :**
  1.  Installation du paquet manquant : `sudo pacman -S pipewire-pulse`
  2.  Redémarrage des services audio : `systemctl --user restart pipewire.service pipewire-pulse.service wireplumber.service`
  3.  Utilisation de `pavucontrol` pour basculer le flux de Firefox vers le casque.

### 4. PipeWire : Basculement automatique vers le casque

- **Problème :** Le son ne basculait pas automatiquement vers le casque lorsqu'il était branché.
- **Solution :** Création d'une règle de priorité pour WirePlumber.
- **Fichier créé :** `~/.config/wireplumber/main.lua.d/50-headset-priority.lua`
- **Contenu du fichier :**
  ```lua
  -- Give a high priority to the USB headset
  rule = {
    matches = {
      {
        { "node.name", "equals", "alsa_output.usb-Synaptics_HUAWEI_USB-C_HEADSET_0296B2922211617299309149313C3-00.analog-stereo" },
      },
    },
    apply_properties = {
      ["device.priority"] = 2000,
    },
  }
  table.insert(wireplumber_config, rule)

  -- Give a lower priority to the internal speakers
  rule2 = {
    matches = {
      {
        { "node.name", "equals", "alsa_output.pci-0000_00_1f.3.analog-stereo" },
      },
    },
    apply_properties = {
      ["device.priority"] = 1000,
    },
  }
  table.insert(wireplumber_config, rule2)
  ```
- **Activation :** `systemctl --user restart wireplumber.service`