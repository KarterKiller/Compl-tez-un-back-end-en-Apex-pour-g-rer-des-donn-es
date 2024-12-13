public class OrderTriggerHandler { //GESTIONNAIRE DE TRIGGERS SUR ORDER. GESTION DES STATUS DE COMMANDES et SYNCHRONISATION LES STATUT DES LIVRAISONS
    public static void handleAfterUpdate(List<Order> newOrders, Map<Id, Order> oldOrderMap) { //newOrders : Liste des commandes modifiées, oldOrderMap : Map des commandes précédentes
        // Liste pour stocker les IDs des commandes ayant changé de statut
        Set<Id> orderIdsWithStatusChange = new Set<Id>(); // Set pour stocker les IDs des commandes ayant changé de statut

        // Déterminer les commandes dont le statut a changé
        for (Order ord : newOrders) {
            Order oldOrder = oldOrderMap.get(ord.Id); // Commande précédente
            if (ord.Status != oldOrder.Status) {
                orderIdsWithStatusChange.add(ord.Id); // Si le status a changé,  l'ID de la commande est ajouté à l'ensemble orderIdsWithStatusChange.
            }
        }

        // Si aucune commande n'a changé de statut, arrêter ici
        if (orderIdsWithStatusChange.isEmpty()) { 
            return;
        }

        // Récupérer toutes les livraisons associées aux commandes ayant changé de statut
        List<Delivery__c> relatedDeliveries = [
            SELECT Id, Status__c, Order__c
            FROM Delivery__c
            WHERE Order__c IN :orderIdsWithStatusChange // Sélectionner uniquement les livraisons associées aux commandes ayant changé de statut
        ];

        // Préparer la liste des livraisons à mettre à jour
        List<Delivery__c> deliveriesToUpdate = new List<Delivery__c>();

        // Parcourir les livraisons et les associer au nouveau statut de leur commande
        Map<Id, String> orderStatusMap = new Map<Id, String>();
        for (Order ord : newOrders) {
            orderStatusMap.put(ord.Id, ord.Status);
        }

        for (Delivery__c del : relatedDeliveries) {
            String newStatus = orderStatusMap.get(del.Order__c);
            if (del.Status__c != newStatus) { // Mettre à jour uniquement si le statut est différent
                del.Status__c = newStatus;
                deliveriesToUpdate.add(del);
            }
        }

        // Appliquer les mises à jour en bloc si des livraisons doivent être mises à jour
        if (!deliveriesToUpdate.isEmpty()) {
            update deliveriesToUpdate;
        }
    }
}
