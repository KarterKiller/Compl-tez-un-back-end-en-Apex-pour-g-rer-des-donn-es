public with sharing class OrderValidationHandler {
    public static void validateOrders(List<Order> orders) {
        // Définir le nombre minimum de produits requis pour les différents types de clients
        Integer minProductsForParticulier = 3;
        Integer minProductsForProfessionnel = 5;

        // Liste des erreurs à collecter pour chaque commande
        Map<Id, String> validationErrors = new Map<Id, String>();

        for (Order orderRecord : orders) {
            // Vérifier si la commande est associée à un compte
            if (orderRecord.AccountId == null) {
                validationErrors.put(orderRecord.Id, 'La commande doit être associée à un compte.');
                continue;
            }

            // Vérifier si le pays de livraison est renseigné
            if (orderRecord.ShippingCountry == null) {
                validationErrors.put(orderRecord.Id, 'Le pays de livraison est requis pour cette commande.');
                continue;
            }

            // Vérifier si la commande a au moins un produit associé uniquement si la commande est en cours d'activation
            if (orderRecord.Status == 'Activated') {
                List<OrderItem> orderItems = [
                    SELECT Id, Quantity FROM OrderItem WHERE OrderId = :orderRecord.Id
                ];
                if (orderItems.isEmpty()) {
                    validationErrors.put(orderRecord.Id, 'La commande doit avoir au moins un produit associé.');
                    continue;
                }

                // Récupérer le type de client à partir du compte
                Account accountRecord = [
                    SELECT Id, CustomerType__c
                    FROM Account
                    WHERE Id = :orderRecord.AccountId
                    LIMIT 1
                ];

                // Définir le nombre minimum de produits requis en fonction du type de client
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

        // Lever les erreurs de validation pour les enregistrements non conformes
        for (Id orderId : validationErrors.keySet()) {
            Trigger.newMap.get(orderId).addError(validationErrors.get(orderId));
        }
    }
}
