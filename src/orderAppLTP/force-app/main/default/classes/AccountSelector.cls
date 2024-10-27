public with sharing class AccountSelector {
    // Méthode pour récupérer les comptes par pays
    @AuraEnabled(cacheable=true)
    public static List<Account> getAccountsByCountry(String country) {
        try {
            // Requête pour obtenir les comptes qui ont une adresse correspondant au pays spécifié
            List<Account> accounts = [
                SELECT Id, Name, BillingCountry, Industry, Rating
                FROM Account
                WHERE BillingCountry = :country
                ORDER BY Name ASC
            ];
            return accounts;
        } catch (Exception e) {
            throw new AuraHandledException('Erreur lors de la récupération des comptes : ' + e.getMessage());
        }
    }

    // Méthode pour récupérer les comptes par secteur d'activité
    @AuraEnabled(cacheable=true)
    public static List<Account> getAccountsByIndustry(String industry) {
        try {
            // Requête pour obtenir les comptes qui appartiennent à un secteur d'activité spécifique
            List<Account> accounts = [
                SELECT Id, Name, BillingCountry, Industry, Rating
                FROM Account
                WHERE Industry = :industry
                ORDER BY Name ASC
            ];
            return accounts;
        } catch (Exception e) {
            throw new AuraHandledException('Erreur lors de la récupération des comptes : ' + e.getMessage());
        }
    }

    // Méthode pour récupérer les comptes avec une bonne note (Rating)
    @AuraEnabled(cacheable=true)
    public static List<Account> getHighRatedAccounts() {
        try {
            // Requête pour obtenir les comptes qui ont une bonne note (par exemple, "Hot" ou "Warm")
            List<Account> accounts = [
                SELECT Id, Name, BillingCountry, Industry, Rating
                FROM Account
                WHERE Rating IN ('Hot', 'Warm')
                ORDER BY Name ASC
            ];
            return accounts;
        } catch (Exception e) {
            throw new AuraHandledException('Erreur lors de la récupération des comptes avec une bonne note : ' + e.getMessage());
        }
    }
}
