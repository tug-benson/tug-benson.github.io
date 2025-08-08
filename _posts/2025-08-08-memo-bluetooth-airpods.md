---
layout: post
title: "Memo : Connexion des AirPods en ligne de commande"
date: 2025-08-08
parent: Mac
---

# Memo : Connexion des AirPods en ligne de commande

Ce guide rapide explique comment connecter des AirPods (ou tout autre appareil Bluetooth) en utilisant l'outil `bluetoothctl`.

## Étape 1 : Mettre les AirPods en mode appairage

C'est l'étape la plus importante pour que l'appareil soit détectable par son nom et non juste par son adresse MAC.

1.  Placez les deux AirPods dans leur boîtier de charge.
2.  Ouvrez le couvercle.
3.  Appuyez et maintenez enfoncé le bouton de configuration à l'arrière du boîtier jusqu'à ce que le voyant d'état clignote en **blanc**.

## Étape 2 : Utiliser `bluetoothctl`

1.  Lancez l'outil de contrôle Bluetooth dans un terminal :
    ```bash
    bluetoothctl
    ```

2.  Activez la recherche d'appareils. Vos AirPods devraient apparaître avec leur nom.
    ```bash
    scan on
    ```

3.  Copiez l'adresse MAC de vos AirPods (`XX:XX:XX:XX:XX:XX`).

4.  Appairez, "truster" (pour la reconnexion automatique) et connectez l'appareil. Remplacez `[adresse_MAC]` par la vôtre.
    ```bash
    pair [adresse_MAC]
    trust [adresse_MAC]
    connect [adresse_MAC]
    ```

5.  Une fois la connexion réussie, vous pouvez quitter l'outil.
    ```bash
    scan off
    exit
    ```


## Dépannage

- Si la connexion échoue, essayez de redémarrer le service Bluetooth :
  ```bash
  sudo systemctl restart bluetooth.service
  ```
- Si l'appareil est déjà connu mais ne se connecte pas, retirez-le avant de recommencer le processus :
  ```bash
  remove [adresse_MAC]
  ```
- Assurez-vous que les AirPods sont suffisamment chargés.
- Vérifiez qu'aucun autre appareil (comme un téléphone) n'est activement connecté aux AirPods.