public with sharing class TransporterSelector {
    // Classe Wrapper pour encapsuler les informations du transporteur
    public class TransporterDetailsWrapper {
        @AuraEnabled public String transporterName;
        @AuraEnabled public Decimal deliveryPrice;
        @AuraEnabled public Decimal deliveryTime;

        // Constructeur
        public TransporterDetailsWrapper(String transporterName, Decimal deliveryPrice, Decimal deliveryTime) {
            this.transporterName = transporterName;
            this.deliveryPrice = deliveryPrice;
            this.deliveryTime = deliveryTime;
        }
    }

    // Méthode pour récupérer le transporteur avec le prix le plus bas pour un pays donné
    @AuraEnabled(cacheable=true)
    public static TransporterDetailsWrapper getCheapestTransporter(String country) {
        //System.debug('Début de la méthode getCheapestTransporter pour le pays : ' + country);

        // Requête pour obtenir le transporteur associé avec le prix de livraison le moins cher dans l'objet Price__c 
        List<Price__c> priceRecords = [
            SELECT Id, DeliveryPrice__c, DeliveryTime__c, Transporter__c
            FROM Price__c
            WHERE Country__c = :country
            ORDER BY DeliveryPrice__c ASC
            LIMIT 1
        ];

        System.debug('Résultats de la requête Price__c : ' + priceRecords);

        if (!priceRecords.isEmpty() && priceRecords[0].Transporter__c != null) {
            //System.debug('ID du transporteur trouvé : ' + priceRecords[0].Transporter__c);

            // Charger le transporteur correspondant via le champ Lookup Transporter__c
            Transporter__c transporter = [
                SELECT Id, Name
                FROM Transporter__c
                WHERE Id = :priceRecords[0].Transporter__c
                LIMIT 1
            ];

            System.debug('Transporter récupéré : ' + transporter);

            // Créer un objet Wrapper contenant les informations à renvoyer
            return new TransporterDetailsWrapper(
                transporter.Name,
                priceRecords[0].DeliveryPrice__c,
                priceRecords[0].DeliveryTime__c
            );
        } else {
            //System.debug('Aucun enregistrement trouvé dans Price__c pour le pays : ' + country);
            return null;
        }
    }

    // Méthode pour récupérer les transporteurs compatibles avec le type de client
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getCompatibleTransporters(String customerType) {
        //System.debug('Valeur de customerType : ' + customerType);
    
        // Initialiser la liste de transporteurs compatibles
        List<Transporter__c> transporters = new List<Transporter__c>();
    
        // Filtrer les transporteurs selon le type de client
        if (customerType != null && customerType.trim().equalsIgnoreCase('Particulier')) {
            //System.debug('Filtrage pour client de type Particulier');
            transporters = [
                SELECT Id, Name, CustomerType__c
                FROM Transporter__c
                WHERE CustomerType__c = 'Particulier' 
                OR CustomerType__c = 'Particulier et Professionnel'
                ORDER BY Name ASC 
            ];
        } else if (customerType != null && customerType.trim().equalsIgnoreCase('Professionnel')) {
            //System.debug('Filtrage pour client de type Professionnel');
            transporters = [
                SELECT Id, Name, CustomerType__c
                FROM Transporter__c
                WHERE CustomerType__c = 'Professionnel' 
                OR CustomerType__c = 'Particulier et Professionnel'
                ORDER BY Name ASC
            ];
        } else {
            //System.debug('Erreur : Type de client non reconnu');
            return new List<Map<String, String>>();
        }
    
        System.debug('Nombre de transporteurs compatibles trouvés : ' + transporters.size());

        // Créer une liste de maps (label-value pairs) pour la barre déroulante
        List<Map<String, String>> compatibleTransporters = new List<Map<String, String>>();
        for (Transporter__c transporter : transporters) {
            Map<String, String> transporterMap = new Map<String, String>{
                'label' => transporter.Name,
                'value' => transporter.Id
            };
            //System.debug('Ajout de transporteur dans la liste : ' + transporterMap);
            compatibleTransporters.add(transporterMap);
        }

        //System.debug('Liste finale de transporteurs compatibles : ' + compatibleTransporters);
        return compatibleTransporters;
    }

    // Méthode pour récupérer le transporteur le plus rapide pour un pays donné
    @AuraEnabled(cacheable=true)
    public static TransporterDetailsWrapper getFastestTransporter(String country) {
        //System.debug('Début de la méthode getFastestTransporter pour le pays : ' + country);

        // Requête pour obtenir le transporteur associé avec le délai de livraison le plus court dans l'objet Price__c
        List<Price__c> priceRecords = [
            SELECT Id, DeliveryPrice__c, DeliveryTime__c, Transporter__c
            FROM Price__c
            WHERE Country__c = :country
            ORDER BY DeliveryTime__c ASC
            LIMIT 1
        ];

        //System.debug('Résultats de la requête Price__c : ' + priceRecords);

        if (!priceRecords.isEmpty() && priceRecords[0].Transporter__c != null) {
            //System.debug('ID du transporteur le plus rapide trouvé : ' + priceRecords[0].Transporter__c);

            // Charger le transporteur correspondant via le champ Lookup Transporter__c
            Transporter__c transporter = [
                SELECT Id, Name
                FROM Transporter__c
                WHERE Id = :priceRecords[0].Transporter__c
                LIMIT 1
            ];

            //System.debug('Transporter récupéré : ' + transporter);

            // Créer un objet Wrapper contenant les informations à renvoyer
            return new TransporterDetailsWrapper(
                transporter.Name,
                priceRecords[0].DeliveryPrice__c,
                priceRecords[0].DeliveryTime__c
            );
        } else {
            //System.debug('Aucun enregistrement trouvé dans Price__c pour le pays : ' + country);
            return null;
        }
    }
}
