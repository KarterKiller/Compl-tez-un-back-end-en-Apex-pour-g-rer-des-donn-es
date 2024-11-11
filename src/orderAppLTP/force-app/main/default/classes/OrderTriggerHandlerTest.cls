@isTest
public class OrderTriggerHandlerTest {
    
    // Test pour la mise à jour du statut de Delivery__c lorsque le statut de Order change
    @isTest
    static void testHandleAfterUpdate() {
        System.debug('Début du test testHandleAfterUpdate');
        
        // Créer des données de test avec TestDataFactory
        Account acc = TestDataFactory.createAccount('Test Account', 'France', 'Technology', 'Hot');
        System.debug('Compte créé avec ID : ' + acc.Id);
        
        // Création d'un contrat pour associer la commande
        Contract contract = TestDataFactory.createContract(acc, 12, 'Draft', Date.today());
        System.debug('Contrat créé avec ID : ' + contract.Id + ' et statut : ' + contract.Status);
        
        // Création de la commande avec statut "Draft" et contrat associé
        Id standardPricebookId = Test.getStandardPricebookId();
        Order ord = TestDataFactory.createOrder(acc, contract, 'Draft', Date.today().addDays(10), 'France', 'France');
        ord.Pricebook2Id = standardPricebookId;
        update ord;
        System.debug('Commande créée avec ID : ' + ord.Id + ' et statut initial : ' + ord.Status);
        
        // Création d'un produit pour l'associer à la commande
        Product2 product = new Product2(Name = 'Test Product', IsActive = true);
        insert product;
        System.debug('Produit créé avec ID : ' + product.Id + ' et statut actif : ' + product.IsActive);
        
        // Création d'une entrée de pricebook pour le produit dans le pricebook standard
        PricebookEntry pricebookEntry = new PricebookEntry(
            Product2Id = product.Id,
            Pricebook2Id = standardPricebookId,
            UnitPrice = 100,
            IsActive = true
        );
        insert pricebookEntry;
        System.debug('Entrée de pricebook créée avec ID : ' + pricebookEntry.Id + ' pour le produit : ' + product.Id);
        
        // Création d'un OrderItem pour associer le produit à la commande
        OrderItem orderItem = new OrderItem(
            OrderId = ord.Id,
            Quantity = 1,
            UnitPrice = 100,
            PricebookEntryId = pricebookEntry.Id
        );
        insert orderItem;
        System.debug('OrderItem créé avec ID : ' + orderItem.Id + ' pour la commande : ' + ord.Id);
        
        // Mise à jour du statut du contrat à "Activated" après ajout du produit
        contract.Status = 'Activated';
        update contract;
        System.debug('Statut du contrat mis à jour à "Activated" pour le contrat ID : ' + contract.Id);
        
        // Créer une livraison associée avec le statut "En cours"
        Delivery__c delivery = TestDataFactory.createDelivery(ord, 'En cours', Date.today().addDays(5));
        System.debug('Livraison créée avec ID : ' + delivery.Id + ' et statut initial : ' + delivery.Status__c);
        
        
        Test.startTest();
        update ord; // Mise à jour de la commande, ce qui devrait déclencher le trigger et mettre à jour la livraison
        Test.stopTest();
        System.debug('Mise à jour de la commande terminée pour le trigger');
        
        // Vérification que le statut de la livraison a été mis à jour pour correspondre à celui de la commande
        Delivery__c updatedDelivery = [SELECT Status__c FROM Delivery__c WHERE Id = :delivery.Id];
        System.debug('Statut de la livraison après mise à jour du trigger : ' + updatedDelivery.Status__c);
        
        System.assertEquals('En cours', updatedDelivery.Status__c, 'Le statut de la livraison devrait être mis à jour en "En cours".');
        System.debug('Fin du test testHandleAfterUpdate');
    }
}