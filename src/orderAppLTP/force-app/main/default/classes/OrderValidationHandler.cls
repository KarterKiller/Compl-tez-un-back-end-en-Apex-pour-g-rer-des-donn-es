public with sharing class OrderValidationHandler {
    public static void validateOrders(List<Order> orders) {
        // Définir le nombre minimum de produits requis pour les différents types de clients
        Integer minProductsForParticulier = 3;
        Integer minProductsForProfessionnel = 5;

        // Liste des erreurs à collecter pour chaque commande
        Map<Id, String> validationErrors = new Map<Id, String>();

        // Collecter tous les Order.Id et Account.Id nécessaires
        Set<Id> orderIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();

        for (Order orderRecord : orders) {
            if (orderRecord.Status == 'Activated') {
                orderIds.add(orderRecord.Id);
            }
            if (orderRecord.AccountId != null) {
                accountIds.add(orderRecord.AccountId);
            }
        }

        
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

        Map<Id, Account> accountMap = new Map<Id, Account>([
            SELECT Id, CustomerType__c 
            FROM Account 
            WHERE Id IN :accountIds
        ]);

        // Validation des commandes
        for (Order orderRecord : orders) {
            // Vérifier si le pays de livraison est renseigné
            if (orderRecord.ShippingCountry == null) {
                validationErrors.put(orderRecord.Id, 'Le pays de livraison est requis pour cette commande.');
                continue;
            }

            // Vérifier si la commande est en cours d'activation
            if (orderRecord.Status == 'Activated') {
                List<OrderItem> orderItems = orderItemsMap.get(orderRecord.Id);

                // Vérifier s'il y a des produits associés
                if (orderItems == null || orderItems.isEmpty()) {
                    validationErrors.put(orderRecord.Id, 'La commande doit avoir au moins un produit associé.');
                    continue;
                }

                // Récupérer le compte associé
                Account accountRecord = accountMap.get(orderRecord.AccountId);
                if (accountRecord == null) {
                    validationErrors.put(orderRecord.Id, 'La commande doit être associée à un compte valide.');
                    continue;
                }

                // Définir le nombre minimum de produits requis
                Integer minProductsRequired = 0;
                if (accountRecord.CustomerType__c == 'Particulier') {
                    minProductsRequired = minProductsForParticulier;
                } else if (accountRecord.CustomerType__c == 'Professionnel') {
                    minProductsRequired = minProductsForProfessionnel;
                }

                // Calculer le nombre total de produits associés à la commande
                Decimal totalQuantity = 0;
                for (OrderItem item : orderItems) {
                    totalQuantity += item.Quantity;
                }

                // Vérifier si le nombre total de produits est suffisant
                if (totalQuantity < minProductsRequired) {
                    validationErrors.put(orderRecord.Id, 'Le nombre minimum de produits requis pour valider cette commande est de ' + minProductsRequired + '.');
                }
            }
        }

        // Relever les erreurs de validation pour les enregistrements non conformes
        for (Id orderId : validationErrors.keySet()) {
            Trigger.newMap.get(orderId).addError(validationErrors.get(orderId));
        }
    }
}
