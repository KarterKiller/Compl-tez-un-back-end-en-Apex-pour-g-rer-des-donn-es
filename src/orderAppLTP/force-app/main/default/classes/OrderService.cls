public with sharing class OrderService {

    // Méthode pour valider une commande avant le lancement de la livraison
    @AuraEnabled
    public static Boolean validateOrder(Id orderId) {
        // Vérifier les autorisations de lecture sur l'objet Order
        if (!Schema.sObjectType.Order.isAccessible()) {
            throw new AuraHandledException('Vous n\'avez pas les autorisations nécessaires pour accéder aux commandes.');
        }

        // Récupérer l'enregistrement Order avec sous-requête
        Order orderRecord = [
            SELECT Id, Status, EffectiveDate, AccountId, Transporter__c, 
                (SELECT Quantity FROM OrderItems)
            FROM Order
            WHERE Id = :orderId
            LIMIT 1
        ];
        
        // Vérifier si la commande est en statut "Draft" ou "Activated"
        if (orderRecord.Status != 'Draft' && orderRecord.Status != 'Activated') {
            throw new AuraHandledException('La commande doit être en statut "Draft" ou "Activated" pour être validée.');
        }


        // Vérifier si la commande est liée à un compte
        if (orderRecord.AccountId == null) {
            throw new AuraHandledException('La commande doit être associée à un compte.');
        }

        return true;
    }

   // Méthode pour lancer la livraison d'une commande
   @AuraEnabled
   public static void launchDelivery(Id orderId, Id transporterId) {
       System.debug('--- Début de la méthode launchDelivery ---');
       System.debug('Commande ID : ' + orderId);
       System.debug('Transporteur ID : ' + transporterId);
   
       // Valider la commande avant de lancer la livraison
       if (!validateOrder(orderId)) {
           System.debug('Validation échouée pour la commande ID : ' + orderId);
           throw new AuraHandledException('La commande n\'est pas valide pour le lancement de la livraison.');
       }
   
       // Mettre à jour le statut de la commande à "En livraison"
       try {
           Order orderToUpdate = new Order(
               Id = orderId,
               Status = 'En livraison'
           );
           update orderToUpdate;
           System.debug('Commande mise à jour avec le statut "En livraison".');
       } catch (Exception e) {
           System.debug('Erreur lors de la mise à jour de la commande : ' + e.getMessage());
           throw new AuraHandledException('Erreur lors de la mise à jour de la commande : ' + e.getMessage());
       }
   
       // Créer l'enregistrement de livraison associé avec le transporteur
       try {
           Delivery__c newDelivery = new Delivery__c(
               Order__c = orderId,
               Status__c = 'En cours',
               DeliveryDate__c = Date.today().addDays(5),
               Transporter__c = transporterId // Associer le transporteur sélectionné
           );
           insert newDelivery;
           System.debug('Livraison créée avec transporteur ID : ' + transporterId);
       } catch (Exception e) {
           System.debug('Erreur lors de la création de la livraison : ' + e.getMessage());
           throw new AuraHandledException('Erreur lors de la création de la livraison : ' + e.getMessage());
       }
   
       System.debug('--- Fin de la méthode launchDelivery ---');
   }
   



    // Méthode pour récupérer les commandes prêtes pour la livraison
@AuraEnabled(cacheable=true)
public static List<Order> getReadyOrders() {
    return [
        SELECT Id, OrderNumber, Name, Status, AccountId, TotalAmount
        FROM Order
        WHERE Status = 'Activated'
        ORDER BY CreatedDate DESC
    ];
}

    
@AuraEnabled(cacheable=true)
public static Account getAccountDetails(Id orderId) {
    // Récupérer l'enregistrement de commande avec l'ID de compte associé
    Order orderRecord = [
        SELECT AccountId
        FROM Order
        WHERE Id = :orderId
        LIMIT 1
    ];

    if (orderRecord != null && orderRecord.AccountId != null) {
        // Récupérer les détails du compte associé
        Account accountRecord = [
            SELECT Id, CustomerType__c
            FROM Account
            WHERE Id = :orderRecord.AccountId
            LIMIT 1
        ];
        return accountRecord;
    } else {
        throw new AuraHandledException('Aucun compte associé à cette commande.');
    }
 }
}