@isTest
public class test_AccountSummaryHelper {

    @isTest
    static void testUpdateAccounts() {
        // Create test data
        List<Account> testAccounts = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            testAccounts.add(new Account(Name = 'Test Account ' + i));
        }
        insert testAccounts;

        // Collect the IDs of the inserted accounts
        Set<Id> accountIds = new Set<Id>();
        for (Account acc : testAccounts) {
            accountIds.add(acc.Id);
        }

        // Call the @future method
        Test.startTest();
        AccountSummaryHelper.updateAccounts(accountIds);
        Test.stopTest(); 

        // Verify the results
        List<Account> updatedAccounts = [SELECT Id, AI_Summary_Helper__c FROM Account WHERE Id IN :accountIds];
        for (Account acc : updatedAccounts) {
            System.assertEquals('Generate Summary', acc.AI_Summary_Helper__c, 'AI_Summary_Helper__c should be updated to "Generate Summary".');
        }
    }
}