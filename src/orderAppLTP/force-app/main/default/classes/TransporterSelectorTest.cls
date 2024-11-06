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
}

    