@isTest
public class TransporterSelectorTest {
    
    // Test pour vérifier la récupération du transporteur le moins cher
    @isTest
    static void testGetCheapestTransporter() {
        // Création de données de test pour un prix de livraison et un transporteur
        TestDataFactory.createPrice(50, 3, 'France'); // Prix de livraison de 50 pour la France
        TestDataFactory.createTransporter('Transporteur 1', 'Particulier');

        Test.startTest();
        TransporterSelector.TransporterDetailsWrapper transporter = TransporterSelector.getCheapestTransporter('France');
        Test.stopTest();

        // Vérification que le transporteur le moins cher est bien récupéré
        System.assertNotEquals(null, transporter, 'Le transporteur le moins cher devrait être retourné.');
        System.assertEquals('Transporteur 1', transporter.transporterName, 'Le transporteur le moins cher devrait être "Transporteur 1".');
        System.assertEquals(50, transporter.deliveryPrice, 'Le prix de livraison devrait être de 50.');
    }

    // Test pour vérifier la récupération du transporteur le plus rapide
    @isTest
    static void testGetFastestTransporter() {
        // Création de données de test pour un prix de livraison et un transporteur avec un délai de livraison court
        TestDataFactory.createPrice(60, 2, 'France'); // Délai de livraison de 2 jours pour la France
        TestDataFactory.createTransporter('Transporteur 2', 'Professionnel');

        Test.startTest();
        TransporterSelector.TransporterDetailsWrapper transporter = TransporterSelector.getFastestTransporter('France');
        Test.stopTest();

        // Vérification que le transporteur le plus rapide est bien récupéré
        System.assertNotEquals(null, transporter, 'Le transporteur le plus rapide devrait être retourné.');
        System.assertEquals('Transporteur 2', transporter.transporterName, 'Le transporteur le plus rapide devrait être "Transporteur 2".');
        System.assertEquals(2, transporter.deliveryTime, 'Le délai de livraison devrait être de 2 jours.');
    }
}
