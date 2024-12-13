# Documentation : Classe `OrderService`

## Introduction
La classe `OrderService` est une classe Apex avec partage activé (**`with sharing`**) utilisée pour gérer la validation des commandes et leur livraison. Elle contient des méthodes permettant de vérifier les autorisations utilisateur, valider une commande, lancer une livraison, récupérer les commandes prêtes et obtenir les détails d'un compte associé.

---

## Méthodes Principales

### 1. `validateOrder`
**Description** : Valide une commande pour s'assurer qu'elle est prête pour le traitement ou la livraison.

#### Signature :
```apex
public static Boolean validateOrder(Id orderId)
```

#### Étapes de Validation :
1. **Vérification des autorisations de lecture** :
   - Vérifie si l'utilisateur a accès à l'objet `Order` et aux produits associés (`OrderItem`).

2. **Récupération de la commande** :
   - Utilise une requête SOQL pour obtenir les détails de la commande, y compris ses articles associés.

3. **Validation du statut** :
   - Vérifie que le statut de la commande est soit "Draft" soit "Activated".

4. **Validation du compte** :
   - Vérifie que la commande est associée à un compte valide.

#### Extrait de Code :
```apex
if (!Schema.sObjectType.Order.isAccessible()) {
    throw new AuraHandledException('Vous n\'avez pas les autorisations nécessaires pour accéder aux commandes.');
}
if (orderRecord.Status != 'Draft' && orderRecord.Status != 'Activated') {
    throw new AuraHandledException('La commande doit être en statut "Draft" ou "Activated" pour être validée.');
}
```

---

### 2. `launchDelivery`
**Description** : Lance la livraison d'une commande après validation.

#### Signature :
```apex
public static void launchDelivery(Id orderId, Id transporterId)
```

#### Étapes :
1. **Validation des autorisations** :
   - Vérifie les autorisations utilisateur pour mettre à jour l'objet `Order` et créer un enregistrement `Delivery__c`.

2. **Validation de la commande** :
   - Appelle la méthode `validateOrder` pour vérifier que la commande est valide.

3. **Mise à jour du statut de la commande** :
   - Met à jour la commande avec le statut "En livraison".

4. **Création de l'enregistrement de livraison** :
   - Insère un nouvel enregistrement `Delivery__c` avec les détails de livraison.

#### Extrait de Code :
```apex
Delivery__c newDelivery = new Delivery__c(
    Order__c = orderId,
    Status__c = 'En cours',
    DeliveryDate__c = Date.today().addDays(5),
    Transporter__c = transporterId
);
insert newDelivery;
```

---

### 3. `getReadyOrders`
**Description** : Récupère toutes les commandes prêtes pour la livraison.

#### Signature :
```apex
public static List<Order> getReadyOrders()
```

#### Fonctionnalités :
- Retourne une liste de commandes dont le statut est "Activated".
- Trie les commandes par date de création (les plus récentes en premier).

#### Extrait de Code :
```apex
return [
    SELECT Id, OrderNumber, Name, Status, AccountId, TotalAmount
    FROM Order
    WHERE Status = 'Activated'
    ORDER BY CreatedDate DESC
];
```

---

### 4. `getAccountDetails`
**Description** : Récupère les détails du compte associé à une commande spécifique.

#### Signature :
```apex
public static Account getAccountDetails(Id orderId)
```

#### Étapes :
1. **Validation des autorisations** :
   - Vérifie que l'utilisateur a accès à l'objet `Account`.

2. **Récupération de l'ID du compte** :
   - Effectue une requête pour obtenir l'ID du compte associé à la commande.

3. **Vérification de l'existence du compte** :
   - Vérifie que le compte existe et qu'il est valide.

#### Extrait de Code :
```apex
List<Account> accounts = [
    SELECT Id, CustomerType__c
    FROM Account
    WHERE Id = :orders[0].AccountId
];
if (accounts.isEmpty()) {
    throw new AuraHandledException('Le compte associé à cette commande n\'existe pas.');
}
```

---

## Gestion des Autorisations
- **Lecture (`isAccessible`)** : Vérifie si l'utilisateur peut accéder aux objets `Order`, `OrderItem`, et `Account`.
- **Mise à jour (`isUpdateable`)** : Vérifie si l'utilisateur peut modifier les enregistrements de commandes.
- **Création (`isCreateable`)** : Vérifie si l'utilisateur peut insérer de nouveaux enregistrements `Delivery__c`.

---

## Bonnes Pratiques Respectées
1. **Vérification des autorisations CRUD** :
   - Garantit que les actions respectent les permissions utilisateur.

2. **Modularité** :
   - Chaque méthode a une responsabilité claire.

3. **Gestion des erreurs** :
   - Utilisation d'`AuraHandledException` pour fournir des messages explicites à l'utilisateur.

4. **Optimisation des Requêtes SOQL** :
   - Consolidation des requêtes pour respecter les limites de gouvernance Salesforce.

---

## Scénarios d'Utilisation
1. **Validation des Commandes** :
   - Vérifier que les commandes sont prêtes pour traitement ou livraison.

2. **Lancement de Livraisons** :
   - Automatiser la création de livraisons associées aux commandes validées.

3. **Rapports et Tableaux de Bord** :
   - Récupérer les commandes prêtes ou les détails des comptes pour affichage ou analyse.

---

## Limitations et Améliorations
### **Limitations**
- Les autorisations CRUD et FLS (Field-Level Security) sont vérifiées uniquement pour les objets principaux, pas pour chaque champ.

### **Améliorations Proposées**
1. Ajouter des tests unitaires pour couvrir tous les scénarios possibles.
2. Gérer les erreurs de manière plus granulaire pour différents types d'exceptions.

---

## Conclusion
La classe `OrderService` offre des fonctionnalités robustes pour la gestion des commandes et des livraisons dans Salesforce. Elle respecte les bonnes pratiques de développement tout en garantissant la sécurité des données et des autorisations utilisateur.
