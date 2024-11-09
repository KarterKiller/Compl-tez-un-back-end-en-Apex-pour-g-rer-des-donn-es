@isTest
public class TransporterSelectorTest {
    
    // Test pour vérifier la récupération du transporteur le moins cher
    @isTest
    static void testGetCheapestTransporter() {
        System.debug('Début du test testGetCheapestTransporter');
        
        // Création du transporteur
        Transporter__c transporter = TestDataFactory.createTransporter('Transporteur 1', 'Particulier');
        System.debug('Transporteur créé avec ID : ' + transporter.Id + ' et nom : ' + transporter.Name);
        
        // Création du prix de livraison et association du transporteur
        Price__c price = TestDataFactory.createPrice(50, 3, 'France', transporter.Id);
        System.debug('Prix de livraison créé avec ID : ' + price.Id + ' pour le pays : ' + price.Country__c + ' avec Transporter__c : ' + price.Transporter__c);
        
        Test.startTest();
        System.debug('Appel de la méthode getCheapestTransporter pour le pays : France');
        TransporterSelector.TransporterDetailsWrapper transporterDetails = TransporterSelector.getCheapestTransporter('France');
        Test.stopTest();

        // Vérification que le transporteur le moins cher est bien récupéré
        System.debug('Vérification des résultats pour le transporteur le moins cher');
        System.assertNotEquals(null, transporterDetails, 'Le transporteur le moins cher devrait être retourné.');
        System.debug('Transporteur récupéré : ' + transporterDetails.transporterName);
        
        System.assertEquals('Transporteur 1', transporterDetails.transporterName, 'Le transporteur le moins cher devrait être "Transporteur 1".');
        System.assertEquals(50, transporterDetails.deliveryPrice, 'Le prix de livraison devrait être de 50.');
        
        System.debug('Fin du test testGetCheapestTransporter');
    }


    // Test pour vérifier la récupération du transporteur le plus rapide
    @isTest
    static void testGetFastestTransporter() {
    System.debug('Début du test testGetFastestTransporter');
    
    // Création du transporteur en premier
    Transporter__c transporter = TestDataFactory.createTransporter('Transporteur 2', 'Professionnel');
    System.debug('Transporteur "Transporteur 2" de type "Professionnel" créé avec ID : ' + transporter.Id);
    
    // Création du prix de livraison en associant le transporteur avec un délai court
    Price__c price = TestDataFactory.createPrice(60, 2, 'France', transporter.Id); // Délai de livraison de 2 jours pour la France
    System.debug('Prix de livraison de 60 pour la France avec délai de 2 jours créé avec ID : ' + price.Id + ' et Transporter__c : ' + price.Transporter__c);

    Test.startTest();
    System.debug('Appel de la méthode getFastestTransporter pour le pays : France');
    TransporterSelector.TransporterDetailsWrapper transporterDetails = TransporterSelector.getFastestTransporter('France');
    Test.stopTest();

    // Vérification que le transporteur le plus rapide est bien récupéré
    System.debug('Vérification des résultats pour le transporteur le plus rapide');
    System.assertNotEquals(null, transporterDetails, 'Le transporteur le plus rapide devrait être retourné.');
    System.debug('Transporteur récupéré : ' + transporterDetails.transporterName);
    
    System.assertEquals('Transporteur 2', transporterDetails.transporterName, 'Le transporteur le plus rapide devrait être "Transporteur 2".');
    System.assertEquals(2, transporterDetails.deliveryTime, 'Le délai de livraison devrait être de 2 jours.');
    
    System.debug('Fin du test testGetFastestTransporter');
    }

  
    
        // Test pour vérifier la création de la liste de transporteurs compatibles pour le type 'Particulier'
        @isTest
        static void testCompatibleTransportersMapCreation() {
            // Création de données de test pour les transporteurs
            Transporter__c transporter1 = new Transporter__c(Name = 'Transporteur Particulier', CustomerType__c = 'Particulier');
            Transporter__c transporter2 = new Transporter__c(Name = 'Transporteur Particulier et Professionnel', CustomerType__c = 'Particulier et Professionnel');
            Transporter__c transporter3 = new Transporter__c(Name = 'Transporteur Professionnel', CustomerType__c = 'Professionnel');
            
            insert new List<Transporter__c>{ transporter1, transporter2, transporter3 };
    
            Test.startTest();
            // Appeler la méthode de récupération des transporteurs compatibles pour un type particulier
            List<Map<String, String>> compatibleTransporters = TransporterSelector.getCompatibleTransporters('Particulier');
            Test.stopTest();
    
            // Vérifier que seuls les transporteurs 'Particulier' et 'Particulier et Professionnel' sont récupérés
            System.assertEquals(2, compatibleTransporters.size(), 'Le nombre de transporteurs compatibles devrait être 2.');
    
            // Vérifier le contenu du premier transporteur (Particulier)
            Map<String, String> transporterMap1 = compatibleTransporters[0];
            System.assertEquals('Transporteur Particulier', transporterMap1.get('label'), 'Le label devrait être "Transporteur Particulier".');
            System.assertEquals(transporter1.Id, transporterMap1.get('value'), 'Le value devrait être l\'ID du transporteur particulier.');
    
            // Vérifier le contenu du deuxième transporteur (Particulier et Professionnel)
            Map<String, String> transporterMap2 = compatibleTransporters[1];
            System.assertEquals('Transporteur Particulier et Professionnel', transporterMap2.get('label'), 'Le label devrait être "Transporteur Particulier et Professionnel".');
            System.assertEquals(transporter2.Id, transporterMap2.get('value'), 'Le value devrait être l\'ID du transporteur particulier et professionnel.');
        }
    }
    