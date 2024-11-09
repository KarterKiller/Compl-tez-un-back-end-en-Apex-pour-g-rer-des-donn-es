public with sharing class OrderService {

    // Méthode pour valider une commande avant le lancement de la livraison
    @AuraEnabled
    public static Boolean validateOrder(Id orderId) {
        try {
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

            // Vérifier si la date effective est dans le futur
            if (orderRecord.EffectiveDate == null || orderRecord.EffectiveDate < Date.today()) {
                throw new AuraHandledException('La date effective de la commande doit être définie et ne peut pas être dans le passé.');
            }

            // Vérifier si la commande est liée à un compte
            if (orderRecord.AccountId == null) {
                throw new AuraHandledException('La commande doit être associée à un compte.');
            }

            return true;
        } catch (Exception e) {
            throw new AuraHandledException('Erreur lors de la validation de la commande : ' + e.getMessage());
        }
    }

    // Méthode pour lancer la livraison d'une commande
    @AuraEnabled
    public static void launchDelivery(Id orderId) {
        System.debug('Début de la méthode launchDelivery pour la commande : ' + orderId);
        
        try {
            // Valider la commande avant de lancer la livraison
            if (!validateOrder(orderId)) {
                System.debug('Validation échouée pour la commande : ' + orderId);
                throw new AuraHandledException('La commande n\'est pas valide pour le lancement de la livraison.');
            }
            
            // Vérifier les autorisations de mise à jour sur l'objet Order
            if (!Schema.sObjectType.Order.isUpdateable()) {
                System.debug('Erreur : Permissions insuffisantes pour mettre à jour les commandes');
                throw new AuraHandledException('Vous n\'avez pas les autorisations nécessaires pour mettre à jour les commandes.');
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
            
        } catch (Exception e) {
            System.debug('Erreur dans launchDelivery : ' + e.getMessage());
            throw new AuraHandledException('Erreur lors du lancement de la livraison : ' + e.getMessage());
        }
    }

    // Méthode pour récupérer les commandes prêtes pour la livraison
    @AuraEnabled(cacheable=true)
    public static List<Order> getReadyOrders() {
        try {
            // Vérifier les autorisations de lecture sur l'objet Order
            if (!Schema.sObjectType.Order.isAccessible()) {
                throw new AuraHandledException('Vous n\'avez pas les autorisations nécessaires pour accéder aux commandes.');
            }

            return [
                SELECT Id, OrderNumber, Name, Status, AccountId, TotalAmount
                FROM Order
                WHERE Status = 'Activated'
                ORDER BY CreatedDate DESC
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Erreur lors de la récupération des commandes prêtes : ' + e.getMessage());
        }
    }

    // Méthode pour récupérer les détails du compte associé à une commande
    @AuraEnabled(cacheable=true)
    public static Account getAccountDetails(Id orderId) {
        try {
            // Vérifier les autorisations de lecture pour l'objet Order
            if (!Schema.sObjectType.Order.isAccessible()) {
                throw new AuraHandledException('Vous n\'avez pas les autorisations nécessaires pour accéder à la commande.');
            }

            Order orderRecord = [
                SELECT AccountId
                FROM Order
                WHERE Id = :orderId
                LIMIT 1
            ];

            if (orderRecord != null && orderRecord.AccountId != null) {
                // Vérifier les autorisations de lecture pour l'objet Account
                if (!Schema.sObjectType.Account.isAccessible()) {
                    throw new AuraHandledException('Vous n\'avez pas les autorisations nécessaires pour accéder aux détails du compte.');
                }

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
        } catch (Exception e) {
            throw new AuraHandledException('Erreur lors de la récupération des détails du compte : ' + e.getMessage());
        }
    }
}
