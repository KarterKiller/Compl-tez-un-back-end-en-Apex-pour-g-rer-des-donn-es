@isTest
public class OrderServiceTest {
    
    // Test pour la méthode validateOrder sans exceptions
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

        Test.startTest(); // lancer une nouvelle transaction et de reset les gorvernor limits
        Boolean isValid = OrderService.validateOrder(ord.Id);
        Test.stopTest();

        System.assertEquals(true, isValid, 'La commande devrait être valide.');
    }

    // Test pour la validation de la méthode launchDelivery
@isTest
static void testLaunchDelivery() { 
    Account acc = TestDataFactory.createAccount('Test Account', 'France', 'Technology', 'Hot');
    
    // Créer un contrat en statut 'Draft'
    Contract contract = TestDataFactory.createContract(acc, 12, 'Draft', Date.today());

    // Associer le contrat et un Price Book standard à la commande
    Id standardPricebookId = Test.getStandardPricebookId();
    Order ord = TestDataFactory.createOrder(acc, contract, 'Draft', Date.today(), 'France', 'France');
    ord.Pricebook2Id = standardPricebookId;
    update ord;

    // Activer le contrat après la création de l'ordre
    contract.Status = 'Activated';
    update contract;

    // Création d'un produit associé pour activer la commande
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
        PricebookEntryId = pricebookEntry.Id
    );
    insert orderItem;

    // Création d'un transporteur
    Transporter__c transporter = new Transporter__c(
        Name = 'Test Transporter',
        CustomerType__c = 'Particulier'
    );
    insert transporter;

    // Lancer la livraison
    Test.startTest();
    OrderService.launchDelivery(ord.Id, transporter.Id); // Appel corrigé
    Test.stopTest();

    // Vérifications après lancement de la livraison
    Order updatedOrder = [SELECT Status FROM Order WHERE Id = :ord.Id];
    System.assertEquals('En livraison', updatedOrder.Status, 'Le statut de la commande devrait être "En livraison".');

    Delivery__c delivery = [SELECT Status__c FROM Delivery__c WHERE Order__c = :ord.Id];
    System.assertEquals('En cours', delivery.Status__c, 'Le statut de la livraison devrait être "En cours".');
}




    // Test pour vérifier la création d'un enregistrement de livraison lors du lancement de la livraison
    @isTest
    static void testLaunchDelivery_CreatesDeliveryRecord() {
        // Étape 1 : Création d'un compte et d'un contrat pour l'ordre
        Account acc = TestDataFactory.createAccount('Test Account', 'France', 'Technology', 'Hot');
        Contract contract = TestDataFactory.createContract(acc, 12, 'Draft', Date.today());

        // Étape 2 : Création d'une commande associée
        Id standardPricebookId = Test.getStandardPricebookId();
        Order ord = TestDataFactory.createOrder(acc, contract, 'Draft', Date.today(), 'France', 'France');
        ord.Pricebook2Id = standardPricebookId;
        update ord;

        // Étape 3 : Mise à jour du statut du contrat en 'Activated'
        contract.Status = 'Activated';
        update contract;

        // Étape 4 : Création d'un produit et ajout d'un OrderItem pour activer la commande
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
            PricebookEntryId = pricebookEntry.Id
        );
        insert orderItem;

        // Création d'un transporteur
        Transporter__c transporter = new Transporter__c(
        Name = 'Test Transporter',
        CustomerType__c = 'Particulier'
        );
        insert transporter;

        // Étape 5 : Lancer la livraison
        Test.startTest();
        OrderService.launchDelivery(ord.Id, transporter.Id);
        Test.stopTest();

        // Étape 6 : Vérifier que l'enregistrement de livraison a bien été créé
        List<Delivery__c> deliveries = [SELECT Status__c, DeliveryDate__c, Order__c FROM Delivery__c WHERE Order__c = :ord.Id];
        System.assertEquals(1, deliveries.size(), 'Un enregistrement de livraison devrait être créé pour la commande.');
        System.assertEquals('En cours', deliveries[0].Status__c, 'Le statut de la livraison devrait être "En cours".');
        System.assertEquals(Date.today().addDays(5), deliveries[0].DeliveryDate__c, 'La date de livraison devrait être fixée à 5 jours dans le futur.');


    }
            // Test pour une commande valide
            @isTest
            static void testValidateOrder_ValidOrder() {
                Account acc = TestDataFactory.createAccount('Test Account', 'France', 'Technology', 'Hot');
                Contract contract = TestDataFactory.createContract(acc, 12, 'Draft', Date.today());
        
                Order ord = TestDataFactory.createOrder(
                    acc, 
                    contract, 
                    'Draft', 
                    Date.today().addDays(10), 
                    'France', 
                    'France'
                );
        
                Test.startTest(); // Utilisé pour garantir que le code fonctionne comme prévu meme avec les limites salesforce. Permet de tester le code dans des conditions proche de la production.
                Boolean isValid = OrderService.validateOrder(ord.Id);
                Test.stopTest();
        
                System.assertEquals(true, isValid, 'La commande devrait être valide.');
            }
        
            
        
            @isTest
            static void testValidateOrder_PastEffectiveDate() {
                Account acc = TestDataFactory.createAccount('Test Account', 'France', 'Technology', 'Hot');
                // Création d'un contrat avec une date de début dans le passé pour forcer l'erreur sur l'EffectiveDate
                Contract contract = TestDataFactory.createContract(acc, 12, 'Draft', Date.today());
            
                // Création de la commande avec une date effective dans le passé
                Order ord = new Order(
                    AccountId = acc.Id,
                    ContractId = contract.Id,
                    Status = 'Draft',
                    EffectiveDate = Date.today().addDays(-5), // Date effective antérieure
                    ShippingCountry = 'France',
                    BillingCountry = 'France'
                );
            
                Boolean exceptionThrown = false;
            
                Test.startTest();
                try {
                    insert ord; // Cette ligne devrait lancer l'exception en raison de l'erreur d'intégrité de champ
                } catch (DmlException e) {
                    exceptionThrown = true;
                    // Vérifie que le message d'erreur contient bien le texte attendu
                    System.assert(e.getMessage().contains('FIELD_INTEGRITY_EXCEPTION, Order Start Date can\'t be earlier than the contract\'s start date'), 
                                  'Message d\'erreur inattendu : ' + e.getMessage());
                }
                Test.stopTest();
            
                System.assertEquals(true, exceptionThrown, 'Une exception aurait dû être levée pour une date effective passée.');
            }
            
       
            
                // Test pour vérifier que la validation échoue pour une commande activée sans produits
                @isTest
                static void testValidateOrder_ActivatedOrderWithoutProducts() {
                    // Création d'un compte et d'un contrat pour l'ordre
                    Account acc = TestDataFactory.createAccount('Test Account', 'France', 'Technology', 'Hot');
                    Contract contract = TestDataFactory.createContract(acc, 12, 'Draft', Date.today());
            
                    // Création de la commande initialement en statut "Draft"
                    Order ord = TestDataFactory.createOrder(
                        acc, 
                        contract, 
                        'Draft', 
                        Date.today(), 
                        'France', 
                        'France'
                    );
            
                    // Changer le statut de la commande de "Draft" à "Activated" et capturer l'exception
                    Test.startTest();
                    Boolean exceptionThrown = false;
                    try {
                        ord.Status = 'Activated';
                        update ord;
                    } catch (DmlException e) {
                        exceptionThrown = true;
                        System.assert(
                            e.getMessage().contains('La commande doit avoir au moins un produit associé'),
                            'Le message d\'erreur devrait contenir la phrase "La commande doit avoir au moins un produit associé".'
                        );
                    }
                    Test.stopTest();
            
                    System.assert(exceptionThrown, 'Une exception aurait dû être levée en raison de l\'absence de produits associés à la commande activée.');
                }
            


    // Test pour récupérer les détails du compte associé avec succès
    @isTest
    static void testGetAccountDetails_Success() {
        System.debug('Début du test testGetAccountDetails_Success');

        // Créer un compte sans définir d'ID
        Account acc = new Account(
            Name = 'Test Account',
            BillingCountry = 'France',
            Industry = 'Technology',
            Rating = 'Hot',
            CustomerType__c = 'Particulier' // Définir le type de client
        );
        System.debug('Compte créé sans ID spécifié : ' + acc);
        
        // Insérer le compte et afficher l'ID après l'insertion
        insert acc;
        System.debug('Compte inséré avec ID généré par Salesforce : ' + acc.Id);

        // Créer un contrat en statut Draft pour associer à la commande
        Contract contract = new Contract(
            AccountId = acc.Id,
            ContractTerm = 12,
            Status = 'Draft',
            StartDate = Date.today()
        );
        System.debug('Contrat créé avec ID : ' + contract.Id + ', lié au compte : ' + acc.Id);
        insert contract;

        // Créer une commande associée au contrat et au compte
        Order ord = new Order(
            AccountId = acc.Id,
            ContractId = contract.Id,
            Status = 'Draft',
            EffectiveDate = Date.today(),
            ShippingCountry = 'France',
            BillingCountry = 'France'
        );
        System.debug('Commande créée sans ID spécifié : ' + ord);
        insert ord;
        System.debug('Commande insérée avec ID généré par Salesforce : ' + ord.Id);

        Test.startTest();
        System.debug('Appel de la méthode OrderService.getAccountDetails avec orderId : ' + ord.Id);
        Account result = OrderService.getAccountDetails(ord.Id);
        Test.stopTest();

        System.debug('Résultat retourné par getAccountDetails : ' + result);

        // Assertions
        System.assertNotEquals(null, result, 'Le compte associé devrait être retourné.');
        System.assertEquals(acc.Id, result.Id, 'L\'ID du compte retourné devrait correspondre à l\'ID du compte associé.');
        System.assertEquals('Particulier', result.CustomerType__c, 'Le type de client devrait être "Particulier".');

        System.debug('Fin du test testGetAccountDetails_Success');


    }

    
  // Test pour récupérer les commandes prêtes avec succès
@isTest
static void testGetReadyOrders_Success() {
    System.debug('--- Début du testGetReadyOrders_Success ---');

    // Créer un compte pour lier les commandes
    Account acc = TestDataFactory.createAccount('Test Account', 'France', 'Technology', 'Hot');
    System.debug('Compte créé avec ID : ' + acc.Id);

    // Créer un contrat en statut 'Draft' pour associer la commande
    Contract contract = TestDataFactory.createContract(acc, 12, 'Draft', Date.today());
    System.debug('Contrat créé avec ID : ' + contract.Id + ' et statut : ' + contract.Status);

    // Récupérer le Pricebook standard
    Id standardPricebookId = Test.getStandardPricebookId();

    // Créer l'Order en statut 'Draft' avec le Pricebook associé
    Order ord = new Order(
        AccountId = acc.Id,
        ContractId = contract.Id,
        Status = 'Draft',
        EffectiveDate = Date.today(),
        ShippingCountry = 'France',
        BillingCountry = 'France',
        Pricebook2Id = standardPricebookId
    );
    insert ord;
    System.debug('Commande insérée avec statut initial : ' + ord.Status);

    // Associer un produit à l'Order
    Product2 product = new Product2(Name = 'Test Product', IsActive = true);
    insert product;
    System.debug('Produit créé avec ID : ' + product.Id);

    PricebookEntry pricebookEntry = new PricebookEntry(
        Product2Id = product.Id,
        Pricebook2Id = standardPricebookId,
        UnitPrice = 100,
        IsActive = true
    );
    insert pricebookEntry;
    System.debug('PricebookEntry créé avec ID : ' + pricebookEntry.Id);

    OrderItem orderItem = new OrderItem(
        OrderId = ord.Id,
        Quantity = 1,
        UnitPrice = 100,
        PricebookEntryId = pricebookEntry.Id
    );
    insert orderItem;
    System.debug('OrderItem associé à la commande avec ID : ' + orderItem.Id);

    contract.Status = 'Activated';
    update contract;
    System.debug('Statut du contrat mis à jour à "Activated" pour le contrat ID : ' + contract.Id);


    // Mettre à jour le statut de la commande en 'Activated'
    ord.Status = 'Activated';
    update ord;
    System.debug('Commande mise à jour avec statut : ' + ord.Status);

    Test.startTest();
    List<Order> readyOrders = OrderService.getReadyOrders();
    Test.stopTest();
    System.debug('Commandes prêtes récupérées : ' + readyOrders);

    // Vérifier que la liste contient une commande prête
    System.assertEquals(1, readyOrders.size(), 'Il devrait y avoir une commande prête dans la liste.');
    System.assertEquals('Activated', readyOrders[0].Status, 'Le statut de la commande devrait être "Activated".');
    System.assertEquals(acc.Id, readyOrders[0].AccountId, 'La commande devrait être liée au compte.');
    
    System.debug('--- Fin du testGetReadyOrders_Success ---');
    }


    @isTest
static void testGetReadyOrders_NoProducts() {
    System.debug('--- Début du testGetReadyOrders_NoProducts ---');

    // Créer un compte pour lier les commandes
    Account acc = TestDataFactory.createAccount('Test Account', 'France', 'Technology', 'Hot');
    System.debug('Compte créé avec ID : ' + acc.Id);

    // Créer un contrat en statut 'Draft' pour associer la commande
    Contract contract = TestDataFactory.createContract(acc, 12, 'Draft', Date.today());
    System.debug('Contrat créé avec ID : ' + contract.Id + ' et statut : ' + contract.Status);

    // Créer l'Order en statut 'Activated' sans produits associés
    Order ord = new Order(
        AccountId = acc.Id,
        ContractId = contract.Id,
        Status = 'Draft',
        EffectiveDate = Date.today(),
        ShippingCountry = 'France',
        BillingCountry = 'France'
    );
    insert ord;
    System.debug('Commande insérée avec statut : ' + ord.Status);

    Test.startTest();
    List<Order> readyOrders = OrderService.getReadyOrders();
    Test.stopTest();
    System.debug('Commandes prêtes récupérées : ' + readyOrders);

    // Vérifier que la liste ne contient aucune commande prête
    System.assertEquals(0, readyOrders.size(), 'Il ne devrait y avoir aucune commande prête dans la liste.');
    
    System.debug('--- Fin du testGetReadyOrders_NoProducts ---');

    }

@isTest
static void testGetReadyOrders_NotActivatedStatus() {
    System.debug('--- Début du testGetReadyOrders_NotActivatedStatus ---');

    // Créer un compte pour lier les commandes
    Account acc = TestDataFactory.createAccount('Test Account', 'France', 'Technology', 'Hot');
    System.debug('Compte créé avec ID : ' + acc.Id);

    // Créer un contrat en statut 'Activated' pour associer la commande
    Contract contract = TestDataFactory.createContract(acc, 12, 'Draft', Date.today());
    System.debug('Contrat créé avec ID : ' + contract.Id + ' et statut : ' + contract.Status);

    // Créer l'Order en statut 'Draft' (non activé)
    Order ord = new Order(
        AccountId = acc.Id,
        ContractId = contract.Id,
        Status = 'Draft',
        EffectiveDate = Date.today(),
        ShippingCountry = 'France',
        BillingCountry = 'France'
    );
    insert ord;
    System.debug('Commande insérée avec statut : ' + ord.Status);

    Test.startTest();
    List<Order> readyOrders = OrderService.getReadyOrders();
    Test.stopTest();
    System.debug('Commandes prêtes récupérées : ' + readyOrders);

    // Vérifier que la liste ne contient aucune commande prête
    System.assertEquals(0, readyOrders.size(), 'Il ne devrait y avoir aucune commande prête dans la liste.');
    
    System.debug('--- Fin du testGetReadyOrders_NotActivatedStatus ---');

    }

 // Test pour vérifier les autorisations CRUD sur l'objet Order
 @isTest
 static void testValidateOrderCRUD() {
     // Création d'un compte et d'une commande
     Account acc = new Account(Name = 'Test Account');
     insert acc;

     Order ord = new Order(
         Name = 'Test Order',
         AccountId = acc.Id,
         Status = 'Draft',
         EffectiveDate = Date.today(),
         ShippingCountry = 'France',
         BillingCountry = 'France'
     );
     insert ord;

     // Simulation de validation CRUD pour lecture
     Test.startTest();
     try {
         Boolean isValid = OrderService.validateOrder(ord.Id);
         System.assertEquals(true, isValid, 'La commande doit être valide avec les autorisations.');
     } catch (AuraHandledException e) {
         System.assert(e.getMessage().contains('Vous n\'avez pas les autorisations nécessaires pour accéder aux commandes.'));
     }
     Test.stopTest();
 }

 

 // Test pour vérifier les autorisations CRUD sur l'objet Account
 @isTest
 static void testGetAccountDetailsCRUD() {
     // Création d'un compte
     Account acc = new Account(Name = 'Test Account', CustomerType__c = 'Particulier');
     insert acc;

     // Création d'une commande associée au compte
     Order ord = new Order(
         Name = 'Test Order',
         AccountId = acc.Id,
         Status = 'Draft',
         EffectiveDate = Date.today(),
         ShippingCountry = 'France',
         BillingCountry = 'France'
     );
     insert ord;

     // Simulation de validation CRUD pour lecture
     Test.startTest();
     try {
         Account accountDetails = OrderService.getAccountDetails(ord.Id);
         System.assertEquals(acc.Id, accountDetails.Id, 'Les détails du compte doivent être récupérés avec succès.');
     } catch (AuraHandledException e) {
         System.assert(e.getMessage().contains('Vous n\'avez pas les autorisations nécessaires pour accéder aux comptes.'));
     }
     Test.stopTest();
 }
}





 
          
