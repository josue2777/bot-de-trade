# SWIFT ALGO ULTIMATE MASTER - Guide Technique MT5

Ce fichier est le portage Master définitif de l'indicateur TradingView "SWIFT". Il a été conçu pour offrir une **parité de logique de 100%** sans aucune simplification algorithmique.

## Modules Intégrés & Logique Master

### 1. Moteur Multi-Moyennes Mobiles (12 Variantes)
Chaque type de MA du script original a été recodé avec précision :
- **ALMA** (Arnaud Legoux) : Utilise une distribution gaussienne pour un lissage sans délai.
- **HullMA** : Formule exacte `WMA(2*WMA(n/2) - WMA(n), sqrt(n))`.
- **SSMA** (SuperSmoother) : Filtre de second ordre de John Ehlers.
- **LSMA** (Least Squares) : Régression linéaire par moindres carrés.
- **VWMA** : Moyenne pondérée par le volume (tick volume sur MT5).
- *Également inclus : SMA, EMA, DEMA, TEMA, WMA, SMMA, TMA.*

### 2. Système Supply & Demand & Structure (BOS)
- **Détection des Pivots** : Utilise une longueur de scan configurable (`InpSwingLength`).
- **Zones Dynamiques** : Les boîtes sont tracées avec une largeur basée sur l'ATR actuel.
- **Break of Structure (BOS)** : Si le prix clôture au-delà d'une zone active, elle devient Orange et cesse de s'étendre, signalant une cassure de structure.

### 3. Filtres de Confluence & Signaux
- **EMA 144 Master Filter** : Les signaux d'achat sont bloqués si le prix est sous l'EMA 144, et vice-versa.
- **WaveTrend & RSI Filters** : L'oscillateur WaveTrend (ESA/CI) et le RSI sont calculés en interne pour filtrer les signaux lors des extrêmes de marché.
- **Divergences** : Le moteur détecte les divergences de momentum pour anticiper les retournements.

### 4. Gestion du Risque (TP/SL)
- Visualisation automatique des objectifs **TP1, TP2, TP3** et du **Stop Loss** calculés sur la clôture du signal.

## Points Cruciaux à Comprendre

### Simulation Multi-Timeframe (MTF)
Sur MT5, la méthode la plus stable est d'utiliser le **Multiplicateur de Période**.
*Exemple* : Si vous tradez sur M15 et voulez voir la tendance H2 (120 min), utilisez un multiplicateur de **8** (15 * 8 = 120). Cela synchronise parfaitement la logique sur votre graphique actuel.

### Mode Heikin Ashi
En activant ce mode, **tous** les calculs de moyennes mobiles et de signaux seront basés sur des bougies HA synthétiques, offrant un lissage extrême pour suivre les tendances fortes.

### Non-Repainting
Pour une utilisation professionnelle, réglez le `Delay (Non-Repaint)` sur **1**. Le signal sera validé et tracé dès que la bougie actuelle se termine.

## Installation
1. Copiez `SwiftIndicator.mq5` dans votre dossier `MQL5/Indicators`.
2. Ouvrez le terminal MT5, clic droit sur "Indicateurs" -> "Rafraîchir".
3. Faites glisser l'indicateur sur votre graphique.

---
*Développé pour les traders exigeant une fidélité totale entre TradingView et MetaTrader 5.*
