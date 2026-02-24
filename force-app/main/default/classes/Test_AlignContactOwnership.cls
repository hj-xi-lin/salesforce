@isTest
public class Test_AlignContactOwnership {
    @isTest
    static void testAlignContactOwnership(){
        
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
               
        // Create test contacts
        List<Contact> testContacts = new List<Contact> {
            new Contact(LastName = 'Test 1', AccountId = testAccount.Id, OwnerId = existingUsers[0].Id),
            new Contact(LastName = 'Test 2', AccountId = testAccount.Id, OwnerId = existingUsers[1].Id)
        };
        insert testContacts;
        
        Test.startTest();
        Database.executeBatch(new AlignContactOwnership());
        Test.stopTest();
        
        // Query test contacts
        testContacts = [SELECT OwnerId, Account.OwnerId FROM Contact WHERE Id IN :testContacts];
        
        // Check if contact owner has been updated
        for (Contact contact : testContacts){
            System.assertEquals(contact.OwnerId, contact.Account.OwnerId, 'Owner should have been updated to the account owner');
        }
        
        
    }

}