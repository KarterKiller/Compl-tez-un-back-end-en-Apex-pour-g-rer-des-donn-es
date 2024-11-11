public class OrderTriggerHandler {
    public static void handleAfterUpdate(List<Order> newOrders, Map<Id, Order> oldOrderMap) {

        List<Delivery__c> deliveriesToUpdate = new List<Delivery__c>();

        for (Order ord : newOrders) { // Liste des commandes mises à jour (newOrders)
            Order oldOrder = oldOrderMap.get(ord.Id); // Commande précédente enregistrée (oldOrderMap)

            // Vérifier si le statut de la commande a changé
            if (ord.Status != oldOrder.Status) { // vérification si la commande a changé
                // Récupérer les livraisons associées pour mettre à jour leur statut
                List<Delivery__c> relatedDeliveries = [
                    SELECT Id, Status__c
                    FROM Delivery__c
                    WHERE Order__c = :ord.Id
                ];

                for (Delivery__c del : relatedDeliveries) {
                    del.Status__c = ord.Status;
                    deliveriesToUpdate.add(del);
                }
            }
        }

        // Appliquer les mises à jour en bloc si des livraisons doivent être mises à jour
        if (!deliveriesToUpdate.isEmpty()) {
            update deliveriesToUpdate;
        }
    }
}
