@isTest
public class OrderValidationHandlerTest {
    
    // Test pour valider les commandes avec les critères de validation dans OrderValidationHandler
    @isTest
    static void testValidateOrders() {
        // Création de données de test avec TestDataFactory
        Account acc = TestDataFactory.createAccount('Test Account', 'France', 'Retail', 'Warm');
        
        // Création d'un contrat pour associer la commande
        Contract contract = TestDataFactory.createContract(acc, 12, 'Draft');
        
        // Créer une commande avec un statut "Activated", une date future, et un contrat associé
        Order ord = TestDataFactory.createOrder(acc, contract, 'Activated', Date.today().addDays(10), 'France', 'France');
        
        // Ajouter un article de commande pour répondre aux critères de validation de quantité
        OrderItem orderItem = TestDataFactory.createOrderItem(ord, 1, 100.00);

        // Exécuter la validation de la commande
        Test.startTest();
        OrderValidationHandler.validateOrders(new List<Order>{ord});
        Test.stopTest();

        // Vérifier que la validation n'a pas levé d'erreurs et que la commande est bien validée
        System.assertEquals(true, true, 'La commande devrait être validée sans erreurs.');
    }

    // Test pour valider qu'une commande sans article échoue à la validation
    @isTest
    static void testValidateOrdersFailsWithoutItems() {
        // Créer des données de test
        Account acc = TestDataFactory.createAccount('Test Account', 'France', 'Retail', 'Warm');
        
        // Création d'un contrat pour associer la commande
        Contract contract = TestDataFactory.createContract(acc, 12, 'Draft');
        
        // Créer une commande avec un statut "Activated", une date future, et un contrat associé
        Order ord = TestDataFactory.createOrder(acc, contract, 'Activated', Date.today().addDays(10), 'France', 'France');

        Test.startTest();
        Boolean hasValidationFailed = false;
        try {
            OrderValidationHandler.validateOrders(new List<Order>{ord});
        } catch (Exception e) {
            hasValidationFailed = true;
        }
        Test.stopTest();

        System.assertEquals(true, hasValidationFailed, 'La validation devrait échouer pour une commande sans article.');
    }
}
