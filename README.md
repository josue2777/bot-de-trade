# SWIFT ALGO ULTIMATE MASTER V12 - Full MQL5 Port

Cette version V12 est l'aboutissement du portage de l'indicateur TradingView "SWIFT". Elle intègre **l'intégralité** des logiques algorithmiques originales sans aucune simplification, optimisée pour MetaTrader 5.

## Modules Master Intégrés

### 1. Moteur Multi-MA (12 Variantes)
Support complet de : ALMA, HullMA, LSMA, SSMA, VWMA, DEMA, TEMA, SMA, EMA, WMA, SMMA, TMA. Chaque variante est calculée avec une précision mathématique 1:1.

### 2. Système Supply & Demand & BOS
- **Zones Dynamiques** : Tracées sur pivots avec largeur adaptative ATR.
- **Break of Structure (BOS)** : Identification visuelle des changements de structure de marché.

### 3. Filtres de Confluence & Momentum
- **WaveTrend Master** : Oscillateur Momentum (ESA/CI) avec détection de divergences Bull/Bear.
- **Range Filter** : Module Smooth Range pour filtrer le bruit du marché.
- **EMA 144 & RSI** : Filtres directionnels et de surachat/survente.

### 4. Canaux de Volatilité & Tendance
- **Linear Regression Channels** : Canaux de tendance basés sur la régression par moindres carrés.
- **Keltner Channels** : Canaux de volatilité basés sur l'ATR.

### 5. Gestion du Risque (TP/SL)
- Visualisation automatique des objectifs **TP1, TP2, TP3** et du **Stop Loss** à chaque signal BUY/SELL.

## Optimisations Techniques
- **Zéro Erreur de Compilation** : Énumérations et variables renommées avec des préfixes uniques (`SM_`, `S_`) pour éviter les conflits avec le système MQL5.
- **Performance GPU/UI** : Gestion optimisée des objets graphiques (vérification d'existence et limitation historique).
- **Stabilité MTF** : Simulation stable des timeframes supérieurs via un multiplicateur de période.

## Installation
1. Copiez `SwiftIndicator.mq5` dans `MQL5/Indicators`.
2. Compilez (F7).
3. Profitez de la puissance de SWIFT sur MT5.

---
*Ce portage master garantit une parité logique totale avec la stratégie originale de traderschatroom88.*
