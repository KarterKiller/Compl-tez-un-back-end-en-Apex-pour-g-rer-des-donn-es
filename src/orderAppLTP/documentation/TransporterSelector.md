# Documentation : Classe `TransporterSelector`

## Introduction
La classe `TransporterSelector` est une classe Apex qui fournit des méthodes pour interagir avec les données des transporteurs et des tarifs de livraison. Elle permet de récupérer les transporteurs compatibles en fonction du type de client, ainsi que les transporteurs les moins chers ou les plus rapides pour un pays donné.

---

## Structure de la Classe

### **Classe Wrapper : `TransporterDetailsWrapper`**

#### **Description**
- Classe interne utilisée pour encapsuler les informations sur un transporteur, comme son nom, son prix de livraison et son délai de livraison.

#### **Propriétés**
```apex
@AuraEnabled public String transporterName;
@AuraEnabled public Decimal deliveryPrice;
@AuraEnabled public Decimal deliveryTime;
```
- **`transporterName`** : Nom du transporteur.
- **`deliveryPrice`** : Prix de livraison.
- **`deliveryTime`** : Délai de livraison (en jours).

#### **Constructeur**
```apex
public TransporterDetailsWrapper(String transporterName, Decimal deliveryPrice, Decimal deliveryTime)
```
- Initialise un objet `TransporterDetailsWrapper` avec les informations fournies.

---

## Méthodes Principales

### 1. `getCheapestTransporter`

#### **Description**
- Récupère le transporteur avec le prix de livraison le plus bas pour un pays donné.

#### **Signature**
```apex
@AuraEnabled(cacheable=true)
public static TransporterDetailsWrapper getCheapestTransporter(String country)
```

#### **Étapes de Traitement**
1. Requête SOQL pour récupérer l’enregistrement `Price__c` avec le prix le plus bas pour le pays fourni.
   ```apex
   SELECT Id, DeliveryPrice__c, DeliveryTime__c, Transporter__c
   FROM Price__c
   WHERE Country__c = :country
   ORDER BY DeliveryPrice__c ASC
   LIMIT 1;
   ```
2. Si un transporteur est trouvé, récupère ses détails via une requête Lookup (`Transporter__c`).
3. Retourne un objet `TransporterDetailsWrapper` contenant les informations du transporteur.

#### **Extrait de Code**
```apex
if (!priceRecords.isEmpty() && priceRecords[0].Transporter__c != null) {
    Transporter__c transporter = [
        SELECT Id, Name
        FROM Transporter__c
        WHERE Id = :priceRecords[0].Transporter__c
        LIMIT 1
    ];
    return new TransporterDetailsWrapper(
        transporter.Name,
        priceRecords[0].DeliveryPrice__c,
        priceRecords[0].DeliveryTime__c
    );
} else {
    return null;
}
```

---

### 2. `getCompatibleTransporters`

#### **Description**
- Récupère les transporteurs compatibles avec un type de client spécifique (Particulier ou Professionnel).

#### **Signature**
```apex
@AuraEnabled(cacheable=true)
public static List<Map<String, String>> getCompatibleTransporters(String customerType)
```

#### **Étapes de Traitement**
1. Vérifie si le type de client est "Particulier" ou "Professionnel".
2. Requête SOQL pour récupérer les transporteurs compatibles selon le type de client.
3. Crée une liste de maps contenant des paires clé-valeur (`label` et `value`) pour chaque transporteur.

#### **Extrait de Code**
```apex
if (customerType.trim().equalsIgnoreCase('Particulier')) {
    transporters = [
        SELECT Id, Name, CustomerType__c
        FROM Transporter__c
        WHERE CustomerType__c = 'Particulier' 
        OR CustomerType__c = 'Particulier et Professionnel'
        ORDER BY Name ASC
    ];
}
```

#### **Retour**
- Une liste contenant des objets Map pour remplir une barre déroulante (dropdown).

---

### 3. `getFastestTransporter`

#### **Description**
- Récupère le transporteur avec le délai de livraison le plus court pour un pays donné.

#### **Signature**
```apex
@AuraEnabled(cacheable=true)
public static TransporterDetailsWrapper getFastestTransporter(String country)
```

#### **Étapes de Traitement**
1. Requête SOQL pour récupérer l’enregistrement `Price__c` avec le délai de livraison le plus court pour le pays fourni.
   ```apex
   SELECT Id, DeliveryPrice__c, DeliveryTime__c, Transporter__c
   FROM Price__c
   WHERE Country__c = :country
   ORDER BY DeliveryTime__c ASC
   LIMIT 1;
   ```
2. Si un transporteur est trouvé, récupère ses détails via une requête Lookup (`Transporter__c`).
3. Retourne un objet `TransporterDetailsWrapper` contenant les informations du transporteur.

---

## Bonnes Pratiques Respectées
1. **Séparation des Responsabilités** :
   - Utilisation d'une classe wrapper (`TransporterDetailsWrapper`) pour encapsuler les données.
2. **Optimisation des Requêtes** :
   - Requêtes SOQL ordonnées pour minimiser les enregistrements récupérés.
3. **Utilisation de Cache** :
   - Les méthodes sont marquées comme cacheables pour améliorer les performances dans les composants Lightning.
4. **Validation des Entrées** :
   - Vérifie la validité du type de client avant d'exécuter des requêtes.

---

## Limitations et Améliorations

### **Limitations**
1. Si aucun transporteur n’est trouvé pour un pays donné, la méthode retourne `null`, ce qui pourrait poser problème dans certains composants.
2. Les champs utilisés dans les requêtes SOQL doivent être disponibles pour l'utilisateur courant.

### **Améliorations Proposées**
1. Ajouter une gestion des exceptions pour éviter des erreurs en cas d'échec des requêtes SOQL.
2. Permettre la configuration des filtres sur les transporteurs via des métadonnées personnalisées.

---

## Scénarios d'Utilisation
1. **Barre Déroulante** :
   - `getCompatibleTransporters` peut être utilisée pour remplir une liste déroulante de transporteurs dans un formulaire.
2. **Analyse des Tarifs** :
   - `getCheapestTransporter` aide à identifier le transporteur le moins cher pour un pays.
3. **Optimisation des Délais** :
   - `getFastestTransporter` permet de sélectionner le transporteur avec le délai de livraison le plus court.

---

## Conclusion
La classe `TransporterSelector` fournit une interface robuste et flexible pour gérer les transporteurs et leurs tarifs dans Salesforce. Elle respecte les bonnes pratiques de développement et s'intègre facilement avec les composants Lightning.
