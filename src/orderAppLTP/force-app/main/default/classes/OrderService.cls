public with sharing class OrderService {
    // VALIDER UNE COMMANDE AVANT DE PERMETTRE SON TRAITEMENT OU SA LIVRAISON

    @AuraEnabled
    public static Boolean validateOrder(Id orderId) {
        // Vérifier les autorisations de l'utilisateur actuel
        if (!Schema.sObjectType.Order.isAccessible()) {
            System.debug('Erreur : L\'utilisateur n\'a pas les autorisations nécessaires pour accéder aux commandes.');
            return false;
        }

        // Vérifier les autorisations de lecture sur l'objet Order ( sous requête )
        Order orderRecord = [
            SELECT Id, Status, EffectiveDate, AccountId, Transporter__c, 
                (SELECT Quantity FROM OrderItems)
            FROM Order
            WHERE Id = :orderId
            LIMIT 1
        ];

        // Vérifier si la commande est en statut "Draft" ou "Activated"
        if (orderRecord.Status != 'Draft' && orderRecord.Status != 'Activated') {
            System.debug('Erreur : La commande doit être en statut "Draft" ou "Activated".');
            return false;
        }

        // Vérifier si la commande est liée à un compte
        if (orderRecord.AccountId == null) {
            System.debug('Erreur : La commande doit être associée à un compte.');
            return false;
        }

        return true; // Retourne true si la commande est valide
    }

    @AuraEnabled
    public static void launchDelivery(Id orderId, Id transporterId) {
        // Vérifier les autorisations de mise à jour sur l'objet Order
        if (!Schema.sObjectType.Order.isUpdateable()) {
            System.debug('Erreur : L\'utilisateur n\'a pas les autorisations nécessaires pour mettre à jour les commandes.');
            return;
        }

        // Vérifier les autorisations de création sur l'objet Delivery__c
        if (!Schema.sObjectType.Delivery__c.isCreateable()) {
            System.debug('Erreur : L\'utilisateur n\'a pas les autorisations nécessaires pour créer des livraisons.');
            return;
        }

        // Valider la commande avant de lancer la livraison
        if (!validateOrder(orderId)) {
            System.debug('Erreur : La commande n\'est pas valide pour le lancement de la livraison.');
            return;
        }

        // Mettre à jour le statut de la commande à "En livraison"
        try {
            Order orderToUpdate = new Order(
                Id = orderId,
                Status = 'En livraison'
            );
            update orderToUpdate;
        } catch (Exception e) {
            System.debug('Erreur lors de la mise à jour de la commande : ' + e.getMessage());
        }

        // Créer l'enregistrement de livraison associé avec le transporteur
        try {
            Delivery__c newDelivery = new Delivery__c(
                Order__c = orderId,
                Status__c = 'En cours',
                DeliveryDate__c = Date.today().addDays(5),
                Transporter__c = transporterId
            );
            insert newDelivery;
        } catch (Exception e) {
            System.debug('Erreur lors de la création de la livraison : ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Order> getReadyOrders() {
        if (!Schema.sObjectType.Order.isAccessible()) {
            System.debug('Erreur : L\'utilisateur n\'a pas les autorisations nécessaires pour accéder aux commandes.');
            return new List<Order>();
        }

        return [
            SELECT Id, OrderNumber, Name, Status, AccountId, TotalAmount
            FROM Order
            WHERE Status = 'Activated'
            ORDER BY CreatedDate DESC
        ];
    }

    @AuraEnabled(cacheable=true)
    public static Account getAccountDetails(Id orderId) {
        if (!Schema.sObjectType.Account.isAccessible()) {
            System.debug('Erreur : L\'utilisateur n\'a pas les autorisations nécessaires pour accéder aux comptes.');
            return null;
        }

        List<Order> orders = [
            SELECT AccountId
            FROM Order
            WHERE Id = :orderId
        ];

        if (orders.isEmpty() || orders[0].AccountId == null) {
            System.debug('Erreur : Aucun compte associé à cette commande.');
            return null;
        }

        List<Account> accounts = [
            SELECT Id, CustomerType__c
            FROM Account
            WHERE Id = :orders[0].AccountId
        ];

        if (accounts.isEmpty()) {
            System.debug('Erreur : Le compte associé à cette commande n\'existe pas.');
            return null;
        }

        return accounts[0];
    }
}
