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
    public static void launchDelivery(Id orderId) {
        System.debug('Début de la méthode launchDelivery pour la commande : ' + orderId);

        // Valider la commande avant de lancer la livraison
        if (!validateOrder(orderId)) {
            System.debug('Validation échouée pour la commande : ' + orderId);
            throw new AuraHandledException('La commande n\'est pas valide pour le lancement de la livraison.');
        }
        

        // Mettre à jour le statut de la commande à "En livraison"
        Order orderToUpdate = new Order(
            Id = orderId,
            Status = 'En livraison'
        );
        update orderToUpdate;
        System.debug('Statut de la commande mis à jour à "En livraison" pour : ' + orderId);

        // Vérifier les autorisations de création sur l'objet Delivery__c
        if (!Schema.sObjectType.Delivery__c.isCreateable()) {
            System.debug('Erreur : Permissions insuffisantes pour créer un enregistrement de livraison');
            throw new AuraHandledException('Vous n\'avez pas les autorisations nécessaires pour créer des enregistrements de livraison.');
        }

        // Créer l'enregistrement de livraison associé
        Delivery__c newDelivery = new Delivery__c(
            Order__c = orderId,
            Status__c = 'En cours',
            DeliveryDate__c = Date.today().addDays(5)
        );
        insert newDelivery;
        System.debug('Enregistrement de livraison créé et inséré pour la commande : ' + orderId);

        System.debug('Fin de launchDelivery - livraison lancée avec succès pour la commande : ' + orderId);
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