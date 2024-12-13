public with sharing class OrderService { 
    // VALIDER UNE COMMANDE AVANT DE PERMETTRE SON TRAITEMENT OU SA LIVRAISON

    // Méthode pour valider une commande avant le lancement de la livraison
    @AuraEnabled
    public static Boolean validateOrder(Id orderId) {
        // Vérifier les autorisations de l'utilisateur actuel
        if (!Schema.sObjectType.Order.isAccessible()) {
            throw new AuraHandledException('Vous n\'avez pas les autorisations nécessaires pour accéder aux commandes.');
        }
        if (!Schema.sObjectType.OrderItem.isAccessible()) {
            throw new AuraHandledException('Vous n\'avez pas les autorisations nécessaires pour accéder aux produits associés.');
        }

        // Vérifier les autorisations de lecture sur l'objet Order
        Order orderRecord = [
            SELECT Id, Status, EffectiveDate, AccountId, Transporter__c, 
                (SELECT Quantity FROM OrderItems) // // Cette requête ramène à la fois les champs de la commande (Order) et les produits associés (OrderItems). Optimisation des performances et Meilleur respect des limites de Salesforce (SOQL Limits)
            FROM Order
            WHERE Id = :orderId
            LIMIT 1
        ];
        
        // Vérifier si la commande est en statut "Draft" ou "Activated"
        if (orderRecord.Status != 'Draft' && orderRecord.Status != 'Activated') {
            throw new AuraHandledException('La commande doit être en statut "Draft" ou "Activated" pour être validée.');
        }

        // Vérifier si la commande est liée à un compte
        if (orderRecord.AccountId == null) { // Si l'objet Order n'a pas de champ AccountId, la commande est invalide
            throw new AuraHandledException('La commande doit être associée à un compte.');
        }

        return true; // Retourne true si la commande est valide
    }

    // Méthode pour lancer la livraison d'une commande validée. Après sa vérification sous cdts avec validateOrder, on lance la méthode launchDelivery
    @AuraEnabled
    public static void launchDelivery(Id orderId, Id transporterId) {
        // Vérifier les autorisations de mise à jour sur l'objet Order
        if (!Schema.sObjectType.Order.isUpdateable()) {
            throw new AuraHandledException('Vous n\'avez pas les autorisations nécessaires pour mettre à jour les commandes.');
        }

        // Vérifier les autorisations de création sur l'objet Delivery__c
        if (!Schema.sObjectType.Delivery__c.isCreateable()) {
            throw new AuraHandledException('Vous n\'avez pas les autorisations nécessaires pour créer des livraisons.');
        }

        // Valider la commande avant de lancer la livraison
        if (!validateOrder(orderId)) {
            throw new AuraHandledException('La commande n\'est pas valide pour le lancement de la livraison.');
        }

        // Mettre à jour le statut de la commande à "En livraison"
        try {
            Order orderToUpdate = new Order(
                Id = orderId,
                Status = 'En livraison'
            );
            update orderToUpdate;
        } catch (Exception e) {
            throw new AuraHandledException('Erreur lors de la mise à jour de la commande : ' + e.getMessage());
        }

        // Créer l'enregistrement de livraison associé avec le transporteur.
        try {
            Delivery__c newDelivery = new Delivery__c(
                Order__c = orderId,
                Status__c = 'En cours',
                DeliveryDate__c = Date.today().addDays(5),
                Transporter__c = transporterId
            );
            insert newDelivery;
        } catch (Exception e) {
            throw new AuraHandledException('Erreur lors de la création de la livraison : ' + e.getMessage());
        }
    }

    // Méthode pour récupérer toutes les commandes prêtes pour la livraison
    @AuraEnabled(cacheable=true)
    public static List<Order> getReadyOrders() {
        if (!Schema.sObjectType.Order.isAccessible()) {
            throw new AuraHandledException('Vous n\'avez pas les autorisations nécessaires pour accéder aux commandes.');
        }

        return [
            SELECT Id, OrderNumber, Name, Status, AccountId, TotalAmount
            FROM Order
            WHERE Status = 'Activated'
            ORDER BY CreatedDate DESC
        ];
    }

    // Récupérer les détails du compte associé à une commande.
    @AuraEnabled(cacheable=true)
    public static Account getAccountDetails(Id orderId) {
        if (!Schema.sObjectType.Account.isAccessible()) {
            throw new AuraHandledException('Vous n\'avez pas les autorisations nécessaires pour accéder aux comptes.');
        }

        List<Order> orders = [
            SELECT AccountId
            FROM Order
            WHERE Id = :orderId
        ];

        if (orders.isEmpty() || orders[0].AccountId == null) {
            throw new AuraHandledException('Aucun compte associé à cette commande.');
        }

        List<Account> accounts = [
            SELECT Id, CustomerType__c
            FROM Account
            WHERE Id = :orders[0].AccountId
        ];

        if (accounts.isEmpty()) {
            throw new AuraHandledException('Le compte associé à cette commande n\'existe pas.');
        }

        return accounts[0];
    }
}
