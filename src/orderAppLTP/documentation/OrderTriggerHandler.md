# Documentation : Classe `OrderTriggerHandler`

## Introduction
La classe `OrderTriggerHandler` est un gestionnaire de triggers associé à l'objet `Order`. Elle est conçue pour synchroniser les statuts des commandes et des livraisons. Son objectif principal est de détecter les changements de statut des commandes et de mettre à jour les livraisons associées en conséquence.

---

## Méthode Principale : `handleAfterUpdate`

### **Description**
- Cette méthode est appelée par un trigger après une mise à jour sur l'objet `Order`.
- Elle synchronise les statuts des livraisons (`Delivery__c`) avec les commandes (`Order`).

#### **Signature**
```apex
public static void handleAfterUpdate(List<Order> newOrders, Map<Id, Order> oldOrderMap)
```
- **Paramètres** :
  - `newOrders` : Liste des commandes mises à jour après la modification.
  - `oldOrderMap` : Map contenant les commandes avant leur modification (clé : ID de commande, valeur : commande).

---

### **Étapes de Traitement**

#### 1. **Identifier les Changements de Statut**
```apex
Set<Id> orderIdsWithStatusChange = new Set<Id>();
for (Order ord : newOrders) {
    Order oldOrder = oldOrderMap.get(ord.Id);
    if (ord.Status != oldOrder.Status) {
        orderIdsWithStatusChange.add(ord.Id);
    }
}
```
- Parcourt les commandes mises à jour pour détecter les changements de statut.
- Si le statut d'une commande a changé, son ID est ajouté à l'ensemble `orderIdsWithStatusChange`.
- **Pourquoi ?** : Seules les commandes ayant un changement de statut nécessitent une synchronisation avec leurs livraisons associées.

#### 2. **Arrêter si Aucun Changement**
```apex
if (orderIdsWithStatusChange.isEmpty()) {
    return;
}
```
- Si aucune commande n'a changé de statut, la méthode s'arrête immédiatement.

#### 3. **Récupérer les Livraisons Associées**
```apex
List<Delivery__c> relatedDeliveries = [
    SELECT Id, Status__c, Order__c
    FROM Delivery__c
    WHERE Order__c IN :orderIdsWithStatusChange
];
```
- Exécute une requête SOQL pour récupérer toutes les livraisons (`Delivery__c`) associées aux commandes ayant changé de statut.
- **Champs récupérés** :
  - `Id` : Identifiant de la livraison.
  - `Status__c` : Statut actuel de la livraison.
  - `Order__c` : ID de la commande associée.

#### 4. **Préparer les Livraisons à Mettre à Jour**
- **Créer une Map pour Associer Commandes et Statuts** :
```apex
Map<Id, String> orderStatusMap = new Map<Id, String>();
for (Order ord : newOrders) {
    orderStatusMap.put(ord.Id, ord.Status);
}
```
- Associe chaque commande (`Order`) à son statut mis à jour.

- **Comparer et Identifier les Livraisons à Mettre à Jour** :
```apex
List<Delivery__c> deliveriesToUpdate = new List<Delivery__c>();
for (Delivery__c del : relatedDeliveries) {
    String newStatus = orderStatusMap.get(del.Order__c);
    if (del.Status__c != newStatus) {
        del.Status__c = newStatus;
        deliveriesToUpdate.add(del);
    }
}
```
- Parcourt les livraisons récupérées.
- Met à jour le statut des livraisons uniquement si leur statut actuel diffère de celui de la commande associée.
- Ajoute les livraisons modifiées à la liste `deliveriesToUpdate`.

#### 5. **Appliquer les Mises à Jour**
```apex
if (!deliveriesToUpdate.isEmpty()) {
    update deliveriesToUpdate;
}
```
- Si des livraisons doivent être mises à jour, elles sont mises à jour en bloc pour respecter les limites de gouvernance Salesforce.

---

## Exemple de Fonctionnement

### **Scénario**
#### Commandes (`Order`) :
| **Id**    | **Statut Avant** | **Statut Après** |
|-----------|-------------------|------------------|
| Order1    | Draft             | Activated        |
| Order2    | Activated         | Completed        |

#### Livraisons (`Delivery__c`) Associées :
| **Id**    | **Order__c** | **Statut Avant** |
|-----------|--------------|------------------|
| Del1      | Order1       | Draft            |
| Del2      | Order2       | Activated        |

### **Étapes d'Exécution** :
1. Les commandes ayant un changement de statut sont identifiées : `Order1`, `Order2`.
2. Les livraisons associées sont récupérées : `Del1`, `Del2`.
3. Les livraisons sont mises à jour avec les nouveaux statuts :
   - `Del1.Status__c` → `Activated`.
   - `Del2.Status__c` → `Completed`.

---

## Points Clés et Bonnes Pratiques

### **1. Utilisation d'un `Set` pour les IDs**
- Évite les doublons lors de la collecte des commandes ayant changé de statut.
- Optimise la requête SOQL pour récupérer les livraisons associées.

### **2. Vérification de la Nécessité d'une Mise à Jour**
- Compare le statut actuel de chaque livraison avec le nouveau statut avant de le modifier, minimisant les mises à jour inutiles.

### **3. Respect des Limites de Gouvernance**
- Les mises à jour sont regroupées en bloc avec `update deliveriesToUpdate`.
- Utilisation de SOQL consolidé pour minimiser les appels.

---

## Limitations et Améliorations Proposées

### **Limitations**
1. Ce code suppose que toutes les livraisons doivent toujours être synchronisées avec leurs commandes associées. Cela peut ne pas être souhaité dans certains scénarios métiers complexes.

### **Améliorations**
1. **Gestion des erreurs** : Ajouter des blocs `try-catch` pour gérer les erreurs au cas où une livraison échoue lors de la mise à jour.
2. **Tests Unitaires** : Créer des tests pour vérifier les scénarios suivants :
   - Pas de commandes ayant changé de statut.
   - Une seule commande change de statut.
   - Plusieurs commandes changent de statut.

---

## Conclusion
La classe `OrderTriggerHandler` offre une solution robuste et modulaire pour synchroniser les statuts des livraisons avec ceux des commandes. Elle respecte les bonnes pratiques Salesforce en termes de gouvernance, de performance et de lisibilité du code.
