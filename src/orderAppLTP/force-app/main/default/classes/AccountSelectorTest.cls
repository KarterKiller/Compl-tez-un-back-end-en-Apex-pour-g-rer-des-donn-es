@isTest
public class AccountSelectorTest {
    @isTest
    static void testGetAccountsByCountry() {
        // Utilisation de TestDataFactory pour créer des données de test
        Account acc = TestDataFactory.createAccount('Test Account', 'France', 'Technology', 'Hot');
        
        Test.startTest();
        List<Account> accounts = AccountSelector.getAccountsByCountry('France');
        Test.stopTest();

        System.assertEquals(1, accounts.size(), 'Le nombre de comptes devrait être 1.');
    }

    @isTest
    static void testGetAccountsByIndustry() {
        Account acc = TestDataFactory.createAccount('Tech Account', 'USA', 'Technology', 'Hot');

        Test.startTest();
        List<Account> accounts = AccountSelector.getAccountsByIndustry('Technology');
        Test.stopTest();

        System.assertEquals(1, accounts.size(), 'Le nombre de comptes devrait être 1.');
    }

    @isTest
    static void testGetHighRatedAccounts() {
        Account acc = TestDataFactory.createAccount('Hot Account', 'USA', 'Finance', 'Hot');

        Test.startTest();
        List<Account> accounts = AccountSelector.getHighRatedAccounts();
        Test.stopTest();

        System.assertEquals(1, accounts.size(), 'Le nombre de comptes devrait être 1.');
    }
}
