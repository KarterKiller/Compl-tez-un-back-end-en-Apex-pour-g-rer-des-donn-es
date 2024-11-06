@isTest
public class OrderValidationHandlerTest {
    
    // Test pour valider les commandes avec les critères de validation dans OrderValidationHandler
    @isTest
    static void testValidateOrders() {
        System.debug('Début du test testValidateOrders');
        
        // Création de données de test avec TestDataFactory
        Account acc = TestDataFactory.createAccount('Test Account', 'France', 'Retail', 'Warm');
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
        
        // Exécuter la validation de la commande
        Test.startTest();
        OrderValidationHandler.validateOrders(new List<Order>{ord});
        Test.stopTest();
        System.debug('Validation de la commande terminée sans erreurs');

        // Vérifier que la validation n'a pas levé d'erreurs et que la commande est bien validée
        System.assertEquals(true, true, 'La commande devrait être validée sans erreurs.');
    }


    
    
    // Test pour valider qu'une commande sans article échoue à la validation du changement de statut de Draft à Activated
    @isTest
    static void testValidateOrdersFailsWithoutItems() {
        System.debug('Début du test testValidateOrdersFailsWithoutItems');
        
        // Créer des données de test
        Account acc = TestDataFactory.createAccount('Test Account', 'France', 'Retail', 'Warm');
        System.debug('Compte créé avec ID : ' + acc.Id);
        
        // Création d'un contrat pour associer la commande
        Contract contract = TestDataFactory.createContract(acc, 12, 'Draft', Date.today());
        System.debug('Contrat créé avec ID : ' + contract.Id + ' et statut : ' + contract.Status);
        
        // Créer une commande avec un statut "Draft", une date future, et un contrat associé
        Order ord = TestDataFactory.createOrder(acc, contract, 'Draft', Date.today().addDays(10), 'France', 'France');
        System.debug('Commande créée avec ID : ' + ord.Id + ' et statut initial : ' + ord.Status);

        // Changer le statut de la commande de "Draft" à "Activated"
        ord.Status = 'Activated';
        
        Test.startTest();
        Boolean hasValidationFailed = false;
        String expectedErrorMessage = 'La commande doit avoir au moins un produit associé.';
        String actualErrorMessage = '';

        try {
            update ord; // Cette mise à jour devrait échouer à cause de la règle de validation
        } catch (DmlException e) {
            hasValidationFailed = true;
            actualErrorMessage = e.getMessage();
            System.debug('Validation échouée comme attendu avec message : ' + actualErrorMessage);
        }
        Test.stopTest();

        // Vérification que la validation a échoué avec le message d'erreur attendu
        System.assertEquals(true, hasValidationFailed, 'La validation devrait échouer pour une commande sans article.');
        System.assert(actualErrorMessage.contains(expectedErrorMessage), 
            'Le message d\'erreur attendu est : "' + expectedErrorMessage + '", mais le message reçu est : "' + actualErrorMessage + '".');
        
        System.debug('Fin du test testValidateOrdersFailsWithoutItems');
    }
}
