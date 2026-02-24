@isTest
public class Test_batchAccountHistory {
    
    @testSetup
    static void setupTestData() {
        // Create test accounts with A_B_Test_Marker_Account__c set to 'Pending'
        List<Account> testAccounts = new List<Account>();
        for (Integer i = 0; i < 2; i++) { // Adjust the number of accounts to match the batch size
            Account acc = new Account(
                Name = 'Test Account ' + i,
                A_B_Test_Marker_Account__c = 'Pending'
            );
            testAccounts.add(acc);
        }
        insert testAccounts;
        
        // Create test ContentNotes and ContentDocumentLinks
        List<ContentNote> notes = new List<ContentNote>();
        List<ContentDocumentLink> links = new List<ContentDocumentLink>();
        for (Account acc : testAccounts) {
            ContentNote note = new ContentNote(
                Title = 'Test Note ' + acc.Name,
                Content = Blob.valueOf('This is a test note for ' + acc.Name)
                // LastModifiedDate will be set automatically by Salesforce
            );
            insert note;
            
            ContentDocumentLink link = new ContentDocumentLink(
                LinkedEntityId = acc.Id,
                ContentDocumentId = note.Id,
                ShareType = 'V' // View access
            );
            links.add(link);
        }
        insert links;
    }

    @isTest
    static void testBatchExecution() {
        // Execute the batch
        Test.startTest();
        batchAccountHistory batch = new batchAccountHistory();
        Database.executeBatch(batch, 2); // Set the batch size to match the number of test records
        Test.stopTest();
        
        // Verify that Customer_360__c records were created
        List<Customer_360__c> docs = [SELECT Id, Account__c FROM Customer_360__c];
        System.assertEquals(2, docs.size(), 'Two documentation records should have been created.');
        
        // Verify that accounts have been updated
        List<Account> updatedAccounts = [SELECT Id, A_B_Test_Marker_Account__c FROM Account WHERE A_B_Test_Marker_Account__c = 'Done'];
        System.assertEquals(2, updatedAccounts.size(), 'All accounts should have been marked as Done.');
    }
}