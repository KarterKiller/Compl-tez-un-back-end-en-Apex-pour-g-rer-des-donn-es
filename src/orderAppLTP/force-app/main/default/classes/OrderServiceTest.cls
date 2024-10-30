@isTest
public class OrderServiceTest {
    
    // Test pour la méthode validateOrder
    @isTest
    static void testValidateOrder() {
        // Création d'un compte et d'un contrat associé
        Account acc = TestDataFactory.createAccount('Test Account', 'France', 'Technology', 'Hot');
        Contract contract = new Contract(
            AccountId = acc.Id,
            ContractTerm = 12,
            Status = 'Draft'
        );
        insert contract;

        // Création de la commande 
        Order ord = new Order(
            AccountId = acc.Id,
            ContractId = contract.Id,
            Status = 'Draft', 
            EffectiveDate = Date.today(), // Date de début de la commande ( Order start date)
            ShippingCountry = 'France', // Pays d'expédition
            BillingCountry = 'France' // Pays de facturation


            
        );
        insert ord;

        Test.startTest();
        Boolean isValid = OrderService.validateOrder(ord.Id);
        Test.stopTest();

        System.assertEquals(true, isValid, 'La commande devrait être valide.');
    }

    // Test pour le lancement de la livraison
    @isTest
    static void testLaunchDelivery() {
        // Création d'un compte, d'un contrat et d'une commande associés
        Account acc = TestDataFactory.createAccount('Test Account', 'France', 'Technology', 'Hot');
        Contract contract = new Contract(
            AccountId = acc.Id,
            ContractTerm = 12,
            Status = 'Draft'
        );
        insert contract;

        // Création de la commande avec des champs supplémentaires
        Order ord = new Order(
            AccountId = acc.Id,
            ContractId = contract.Id,
            Status = 'Activated',
            EffectiveDate = Date.today(), // Date de début de la commande
            ShippingCountry = 'France', // Pays d'expédition
            BillingCountry = 'France' // Pays de facturation
        
        );
        insert ord;

        Test.startTest();
        OrderService.launchDelivery(ord.Id);
        Test.stopTest();

        // Vérification du statut de la commande après le lancement de la livraison
        Order updatedOrder = [SELECT Status, EffectiveDate, ShippingCountry, BillingCountry FROM Order WHERE Id = :ord.Id];
        System.assertEquals('En livraison', updatedOrder.Status, 'Le statut de la commande devrait être "En livraison".');
        System.assertEquals('France', updatedOrder.ShippingCountry, 'Le pays d\'expédition devrait être "France".');
        

        // Vérification de la création de la livraison associée
        Delivery__c delivery = [SELECT Status__c, Order__c FROM Delivery__c WHERE Order__c = :ord.Id];
        System.assertEquals('En cours', delivery.Status__c, 'Le statut de la livraison devrait être "En cours".');
    }
}
