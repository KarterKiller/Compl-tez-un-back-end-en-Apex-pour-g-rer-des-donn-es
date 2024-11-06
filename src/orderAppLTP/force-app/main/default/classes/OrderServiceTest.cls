@isTest
public class OrderServiceTest {
    
    // Test pour la méthode validateOrder
    @isTest
    static void testValidateOrder() {
        Account acc = TestDataFactory.createAccount('Test Account', 'France', 'Technology', 'Hot');
        Contract contract = TestDataFactory.createContract(acc, 12, 'Draft', Date.today());

        Order ord = TestDataFactory.createOrder(
            acc, 
            contract, 
            'Draft', 
            Date.today(), 
            'France', 
            'France'
        );

        Test.startTest();
        Boolean isValid = OrderService.validateOrder(ord.Id);
        Test.stopTest();

        System.assertEquals(true, isValid, 'La commande devrait être valide.');
    }


 
    
     // Test pour le lancement de la livraison
     @isTest
     static void testLaunchDelivery() { 
         // Création d'un compte pour les tests
         Account acc = TestDataFactory.createAccount('Test Account', 'France', 'Technology', 'Hot');
         
         // Étape 1 : Créer un contrat en statut 'Draft'
         Contract contract = TestDataFactory.createContract(acc, 12, 'Draft', Date.today());
 
         // Récupérer le Price Book standard et créer la commande associée au contrat
         Id standardPricebookId = Test.getStandardPricebookId();
         Order ord = TestDataFactory.createOrder(acc, contract, 'Draft', Date.today(), 'France', 'France');
         ord.Pricebook2Id = standardPricebookId;
         update ord;
 
         // Étape 2 : Mise à jour du contrat en 'Activated' après association avec l'ordre
         contract.Status = 'Activated';
         update contract;
 
         // Création d'un produit et association de l'OrderItem
         Product2 product = new Product2(Name = 'Test Product', IsActive = true);
         insert product;
 
         PricebookEntry pricebookEntry = new PricebookEntry(
             Product2Id = product.Id,
             Pricebook2Id = standardPricebookId,
             UnitPrice = 100,
             IsActive = true
         );
         insert pricebookEntry;
 
         OrderItem orderItem = new OrderItem(
             OrderId = ord.Id,
             Quantity = 1,
             UnitPrice = 100,
             PricebookEntryId = pricebookEntry.Id,
             ActivationStatus__c = 'Activated' // Nouveau champ pour activer l'OrderItem
         );
         insert orderItem;
 
         // Lancement de la livraison
         Test.startTest();
         OrderService.launchDelivery(ord.Id);
         Test.stopTest();
 
         // Vérifications après lancement de la livraison
         Order updatedOrder = [SELECT Status, ShippingCountry, BillingCountry FROM Order WHERE Id = :ord.Id];
         System.assertEquals('En livraison', updatedOrder.Status, 'Le statut de la commande devrait être "En livraison".');
 
         Delivery__c delivery = [SELECT Status__c FROM Delivery__c WHERE Order__c = :ord.Id];
         System.assertEquals('En cours', delivery.Status__c, 'Le statut de la livraison devrait être "En cours".');
     }
 }