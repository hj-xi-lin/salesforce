@isTest
public class Test_AlignOppOwnership {
    @isTest
    static void testAlignOppOwnership(){
        
        // Get two active Admin users
        List<User> existingUsers = [SELECT Id from User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 2];
        if (existingUsers.size() < 2) {
            System.assert(false, 'Need at least two users with the \'System Administrator\' profile to run this test.');
            return;
        }
        
        // Create test account
        Account testAccount = new Account(
            Name = 'Test Account',
            Service_Country__c = 'DE',
            OwnerId = existingUsers[0].Id
        );
        insert testAccount;
        
        // Create test opps
        List<Opportunity> testOpps = new List<Opportunity> {
            new Opportunity(Name = 'Test 1', StageName = 'Not reached yet',  CloseDate = Date.today(), AccountId = testAccount.Id, OwnerId = existingUsers[0].Id),
            new Opportunity(Name = 'Test 2', StageName = 'Not reached yet', CloseDate = Date.today(), AccountId = testAccount.Id, OwnerId = existingUsers[1].Id),
            new Opportunity(Name = 'Test 3', StageName = 'Closed Lost', CloseDate = Date.today(), AccountId = testAccount.Id, OwnerId = existingUsers[1].Id)    
        };
        insert testOpps;
        
        Test.startTest();
        Database.executeBatch(new AlignOppOwnership());
        Test.stopTest();
        
        // Query test opps that should have same owners
        testOpps = [SELECT OwnerId, Account.OwnerId FROM Opportunity WHERE Id IN :testOpps AND Name != 'Test 3'];
        
        // Check if opp owner has been updated
        for (Opportunity opp : testOpps){
            System.assertEquals(opp.OwnerId, opp.Account.OwnerId, 'Owner should have been updated to the account owner');
        }
        
        // Query test opps that should not have same owners
        testOpps = [SELECT OwnerId, Account.OwnerId FROM Opportunity WHERE Id IN :testOpps AND Name = 'Test 3'];
        
        // Check if opp owner has been updated
        for (Opportunity opp : testOpps){
            System.assertNotEquals(opp.OwnerId, opp.Account.OwnerId, 'Owner should not have been updated to the account owner');
        }
        
        
    }

}