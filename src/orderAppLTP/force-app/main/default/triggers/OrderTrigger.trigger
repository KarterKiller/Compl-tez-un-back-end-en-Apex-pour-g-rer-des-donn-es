trigger OrderTrigger on Order (after update) { // Se déclenche après la mise à jour sur Order
    if (Trigger.isAfter && Trigger.isUpdate) { 
        OrderTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap); // Appeler le gestionnaire de trigger pour gérer les commandes
    }
}