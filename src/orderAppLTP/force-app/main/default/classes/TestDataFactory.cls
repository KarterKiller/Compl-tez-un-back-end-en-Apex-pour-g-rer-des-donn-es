@isTest
public class TestDataFactory {
    
    // Méthode pour créer un compte de test
    public static Account createAccount(String name, String country, String industry, String rating) {
        Account acc = new Account(
            Name = name,
            BillingCountry = country,
            Industry = industry,
            Rating = rating
        );
        insert acc;
        return acc;
    }
    
    // Méthode pour créer un contrat de test
    public static Contract createContract(Account account, Integer contractTerm, String status, Date startDate) {
        Contract contract = new Contract(
            AccountId = account.Id,
            ContractTerm = contractTerm,
            Status = status != null ? status : 'Activated', // Définit 'Activated' par défaut
            StartDate = startDate                   
        );
        insert contract;
        return contract;
    }

    // Méthode pour créer une commande de test
    public static Order createOrder(Account account, Contract contract, String status, Date effectiveDate, String shippingCountry, String billingCountry) {
        Order ord = new Order(
            AccountId = account.Id,
            ContractId = contract.Id,
            Status = status,
            EffectiveDate = effectiveDate,
            ShippingCountry = shippingCountry,
            BillingCountry = billingCountry
        );
        insert ord;
        return ord;
    }
    
    // Méthode pour créer un article de commande de test
    public static OrderItem createOrderItem(Order order, Integer quantity, Decimal price) {
        OrderItem orderItem = new OrderItem(
            OrderId = order.Id,
            Quantity = quantity,
            UnitPrice = price
        );
        insert orderItem;
        return orderItem;
    }

    // Méthode pour créer une livraison de test
    public static Delivery__c createDelivery(Order order, String status, Date deliveryDate) {
        Delivery__c delivery = new Delivery__c(
            Order__c = order.Id,
            Status__c = status,
            DeliveryDate__c = deliveryDate
        );
        insert delivery;
        return delivery;
    }
    
    // Méthode pour créer un enregistrement de prix de livraison de test
    public static Price__c createPrice(Decimal deliveryPrice, Integer deliveryTime, String country, Id transporterId) {
        Price__c price = new Price__c(
            DeliveryPrice__c = deliveryPrice,
            DeliveryTime__c = deliveryTime,
            Country__c = country,
            Transporter__c = transporterId // Association du transporteur au prix de livraison
        );
        insert price;
        System.debug('Prix créé avec ID : ' + price.Id + ', pour le pays : ' + country + ', et Transporter__c : ' + transporterId);
        return price;
    }

    // Méthode pour créer un transporteur de test
    public static Transporter__c createTransporter(String name, String customerType) {
        Transporter__c transporter = new Transporter__c(
            Name = name,
            CustomerType__c = customerType
        );
        insert transporter;
        System.debug('Transporteur créé avec ID : ' + transporter.Id);
        return transporter;
    }
    
    // Méthode pour insérer des données de test complètes pour un flux de commande et livraison
    public static void setupTestData() {
        Account acc = createAccount('Test Account', 'France', 'Technology', 'Hot');
        
        // Créer un contrat de test pour l'utiliser dans l'Order
        Contract contract = createContract(acc, 12, 'Draft', Date.today());
        
        // Ajouter les valeurs manquantes pour ShippingCountry, BillingCountry, et StartDate
        Order ord = createOrder(
            acc, 
            contract, 
            'Draft', 
            Date.today().addDays(10), // EffectiveDate
            'France', // ShippingCountry
            'France' // BillingCountry
        );
        
        // Création d'un article de commande et d'un transporteur pour le test
        OrderItem orderItem = createOrderItem(ord, 1, 100.00);
        Delivery__c delivery = createDelivery(ord, 'En cours', Date.today().addDays(5));
        
        // Créer le transporteur et le lier au prix de livraison
        Transporter__c transporter = createTransporter('Transporter 1', 'Particulier');
        createPrice(50, 3, 'France', transporter.Id); // Lien entre le prix et le transporteur
    }
}
