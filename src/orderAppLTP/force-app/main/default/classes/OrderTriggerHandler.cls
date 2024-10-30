public class OrderTriggerHandler {
    public static void handleAfterUpdate(List<Order> newOrders, Map<Id, Order> oldOrderMap) {
        // Vérifier les autorisations CRUD pour Delivery__c et le champ Status__c
        if (!Schema.sObjectType.Delivery__c.isAccessible() || !Schema.sObjectType.Delivery__c.fields.Status__c.isUpdateable()) {
            throw new AuraHandledException('Vous n\'avez pas les autorisations nécessaires pour mettre à jour le statut des livraisons.');
        }

        List<Delivery__c> deliveriesToUpdate = new List<Delivery__c>();

        for (Order ord : newOrders) {
            Order oldOrder = oldOrderMap.get(ord.Id);

            // Vérifier si le statut de la commande a changé
            if (ord.Status != oldOrder.Status) {
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
