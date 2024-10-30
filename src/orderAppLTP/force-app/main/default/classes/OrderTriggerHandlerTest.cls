@isTest
public class OrderTriggerHandlerTest {
    
    // Test pour la mise à jour du statut de Delivery__c lorsque le statut de Order change
    @isTest
    static void testHandleAfterUpdate() {
        // Créer des données de test avec TestDataFactory
        Account acc = TestDataFactory.createAccount('Test Account', 'France', 'Technology', 'Hot');
        
        // Création d'un contrat pour associer la commande
        Contract contract = TestDataFactory.createContract(acc, 12, 'Draft');
        
        // Création de la commande avec statut "Draft" et contrat associé
        Order ord = TestDataFactory.createOrder(acc, contract, 'Draft', Date.today().addDays(10), 'France', 'France');

        // Créer une livraison associée avec le statut "En cours"
        Delivery__c delivery = TestDataFactory.createDelivery(ord, 'En cours', Date.today().addDays(5));

        // Changer le statut de la commande pour déclencher le trigger
        ord.Status = 'Activated';
        
        Test.startTest();
        update ord; // Mise à jour de l'ordre, ce qui devrait déclencher le trigger et mettre à jour la livraison
        Test.stopTest();

        // Vérification que le statut de la livraison a été mis à jour pour correspondre à celui de la commande
        Delivery__c updatedDelivery = [SELECT Status__c FROM Delivery__c WHERE Id = :delivery.Id];
        System.assertEquals('Activated', updatedDelivery.Status__c, 'Le statut de la livraison devrait être mis à jour en "Activated".');
    }
}
