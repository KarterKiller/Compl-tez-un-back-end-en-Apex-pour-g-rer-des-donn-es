# Documentation : Classe `OrderValidationHandler`

## Introduction
La classe `OrderValidationHandler` est conçue pour valider les commandes (`Order`) dans Salesforce. Elle vérifie diverses conditions métier, comme le statut des commandes, les comptes associés, les articles associés, et le respect des règles métier spécifiques pour différents types de clients. Les commandes invalides génèrent des erreurs de validation.

---

## Méthode Principale : `validateOrders`

### **Description**
Cette méthode prend en entrée une liste de commandes à valider. Elle applique des règles métier et lève des erreurs pour les commandes qui ne respectent pas ces règles.

#### **Signature**
```apex
public static void validateOrders(List<Order> orders)
```
- **Paramètres** :
  - `orders` : Liste des commandes (`Order`) à valider.

---

### **Étapes de Validation**

#### 1. **Définir les Paramètres de Validation**
- Nombre minimum de produits requis selon le type de client :
```apex
Integer minProductsForParticulier = 3;
Integer minProductsForProfessionnel = 5;
```

#### 2. **Initialisation des Structures de Données**
- **`validationErrors`** :
  - Map associant l'ID des commandes à des messages d'erreur.
  ```apex
  Map<Id, String> validationErrors = new Map<Id, String>();
  ```
- **`orderIds`** et **`accountIds`** :
  - Sets pour stocker les IDs des commandes activées et des comptes associés afin d'éviter les doublons.

#### 3. **Collecte des IDs Pertinents**
```apex
for (Order orderRecord : orders) {
    if (orderRecord.Status == 'Activated') {
        orderIds.add(orderRecord.Id);
    }
    if (orderRecord.AccountId != null) {
        accountIds.add(orderRecord.AccountId);
    }
}
```
- Collecte les **IDs des commandes activées** et des **comptes associés** pour optimiser les requêtes SOQL.

#### 4. **Récupérer les Articles de Commande**
- Requête SOQL pour récupérer les articles (`OrderItem`) des commandes activées :
```apex
Map<Id, List<OrderItem>> orderItemsMap = new Map<Id, List<OrderItem>>();
for (OrderItem orderItem : [
    SELECT Id, Quantity, OrderId 
    FROM OrderItem 
    WHERE OrderId IN :orderIds
]) {
    if (!orderItemsMap.containsKey(orderItem.OrderId)) {
        orderItemsMap.put(orderItem.OrderId, new List<OrderItem>());
    }
    orderItemsMap.get(orderItem.OrderId).add(orderItem);
}
```
- Regroupe les articles par commande dans une `Map`.

#### 5. **Récupérer les Comptes Associés**
- Requête SOQL pour récupérer les comptes :
```apex
Map<Id, Account> accountMap = new Map<Id, Account>([
    SELECT Id, CustomerType__c 
    FROM Account 
    WHERE Id IN :accountIds
]);
```

#### 6. **Validation des Commandes**
- Parcourt les commandes et applique les règles métier :

1. **Pays de Livraison** :
   ```apex
   if (orderRecord.ShippingCountry == null) {
       validationErrors.put(orderRecord.Id, 'Le pays de livraison est requis pour cette commande.');
       continue;
   }
   ```

2. **Produits Associés** :
   ```apex
   if (orderItems == null || orderItems.isEmpty()) {
       validationErrors.put(orderRecord.Id, 'La commande doit avoir au moins un produit associé.');
       continue;
   }
   ```

3. **Compte Associé** :
   ```apex
   if (accountRecord == null) {
       validationErrors.put(orderRecord.Id, 'La commande doit être associée à un compte valide.');
       continue;
   }
   ```

4. **Nombre Minimum de Produits** :
   ```apex
   if (totalQuantity < minProductsRequired) {
       validationErrors.put(orderRecord.Id, 'Le nombre minimum de produits requis pour valider cette commande est de ' + minProductsRequired + '.');
   }
   ```

#### 7. **Lever les Erreurs**
- Applique les erreurs de validation aux enregistrements concernés :
```apex
for (Id orderId : validationErrors.keySet()) {
    Trigger.newMap.get(orderId).addError(validationErrors.get(orderId));
}
```

---

## Exemple de Fonctionnement

### **Scénario**
#### Commandes :
| **Id**    | **Status**  | **ShippingCountry** | **AccountId** |
|-----------|-------------|---------------------|---------------|
| Order1    | Activated   | France              | A001          |
| Order2    | Draft       | null                | A002          |

#### Articles (`OrderItem`) :
| **Id**    | **Quantity** | **OrderId** |
|-----------|--------------|-------------|
| Item1     | 2            | Order1      |
| Item2     | 1            | Order1      |

#### Comptes (`Account`) :
| **Id**    | **CustomerType__c** |
|-----------|----------------------|
| A001      | Particulier          |
| A002      | Professionnel        |

### **Étapes d'Exécution**
1. Récupération des articles associés :
   - `Order1` a deux articles, totalisant une quantité de 3.
2. Récupération des comptes associés :
   - `Order1` est associé à `A001` (Particulier).
3. Validation :
   - `Order1` passe la validation (quantité = 3, minimum requis = 3).
   - `Order2` échoue (pas de pays de livraison renseigné).

---

## Bonnes Pratiques Respectées
1. **Optimisation des Requêtes SOQL** :
   - Les requêtes sont placées en dehors des boucles pour minimiser leur nombre.

2. **Utilisation des `Set` et `Map`** :
   - Évite les doublons et facilite l'accès rapide aux données.

3. **Validation Détaillée** :
   - Les erreurs sont collectées et appliquées en bloc pour une meilleure traçabilité.

4. **Gestion Modulaire** :
   - La logique métier est centralisée, ce qui améliore la lisibilité et la maintenabilité.

---

## Limitations et Améliorations

### **Limitations**
1. Les erreurs sont levées au niveau de la commande entière, sans précision sur les champs spécifiques à corriger.

### **Améliorations Proposées**
1. Ajouter des tests unitaires couvrant les cas limites (ex. aucune commande, commandes avec des produits invalides).
2. Gérer les exceptions éventuelles lors des requêtes SOQL.
3. Ajouter une validation au niveau des champs spécifiques.

---

## Conclusion
La classe `OrderValidationHandler` fournit un mécanisme robuste pour valider les commandes en respectant les règles métier. Elle s'intègre facilement avec les triggers Salesforce et respecte les bonnes pratiques en matière de gouvernance et de lisibilité du code.
