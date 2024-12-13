public with sharing class OrderValidationHandler {
    public static void validateOrders(List<Order> orders) { // prendre en paramètre une liste d'objets de type Order
        // Définir le nombre minimum de produits requis pour les différents types de clients
        Integer minProductsForParticulier = 3;
        Integer minProductsForProfessionnel = 5;

        // Liste des erreurs à collecter pour chaque commande avec une clé associée à l'ID de la commande pour chaque message d'erreur. 
        Map<Id, String> validationErrors = new Map<Id, String>();

        // Initialisation des sets pour stocker les IDs des commandes et des comptes associés. Les Set évitent les doublons et optimise les requêtes SOQL en limitant le nb d'enregistrement à récupérer.
        Set<Id> orderIds = new Set<Id>(); // Vide au départ. Ex après : {'Order1', 'Order3', 'Order4'}
        Set<Id> accountIds = new Set<Id>();// Vide au départ. Ex après : {'A001', 'A002'}

        for (Order orderRecord : orders) { // Itération sur chaque commande. et va appliquer les cdts.  Si Active, ajoute 'l'ID' au Set OrderIds
            if (orderRecord.Status == 'Activated') {
                orderIds.add(orderRecord.Id);
            }
            if (orderRecord.AccountId != null) {
                accountIds.add(orderRecord.AccountId);
            }
        }

        //Récupère tous les articles (OrderItem ) associés aux commandes activées et les stock dans une map. Toujours placer les queries SOQL en dehors de la boucle. 
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

        // Itération sur toutes les clés (orderId ) de la Map validationErrors. Retourne un ensemble (Set) de tous les IDs des commandes Order.Id avec des erreurs de validation
        for (Id orderId : validationErrors.keySet()) {
            Trigger.newMap.get(orderId).addError(validationErrors.get(orderId)); // contient les enregistrements d'objet Order en cours de traitement. 
        }
    }
}
