@isTest
public class Test_batchMigrateOnboardingDocumentation {
    
    @testSetup
    static void setupTestData() {
        // Create test accounts with A_B_Test_Marker_Account__c set to 'Pending'
        Account acc1 = new Account(
            Name = 'Test Account 1',
            A_B_Test_Marker_Account__c = 'Pending'
        );
        insert acc1;
        Account acc2 = new Account(
            Name = 'Test Account 2',
            A_B_Test_Marker_Account__c = 'Pending'
        );
        insert acc2;
               
        // Create test ContentNotes and ContentDocumentLinks
        List<ContentNote> notes = new List<ContentNote>();
        List<ContentDocumentLink> links = new List<ContentDocumentLink>();
        
        ContentNote note1 = new ContentNote(
            Title = 'Onboarding Notes DJR',
            Content = Blob.valueOf('This is a test note for Test Account 1')
            );
        insert note1;
        
        ContentDocumentLink link1 = new ContentDocumentLink(
                LinkedEntityId = acc1.Id,
                ContentDocumentId = note1.Id,
                ShareType = 'V' // View access
            );
        insert link1;
        
        ContentNote note2 = new ContentNote(
            Title = 'Test Note',
            Content = Blob.valueOf('This is a non-onboarding note for Test Account 2')
            );
        insert note2;
        ContentDocumentLink link2 = new ContentDocumentLink(
                LinkedEntityId = acc2.Id,
                ContentDocumentId = note2.Id,
                ShareType = 'V' // View access
            );
        insert link2;
    }

    @isTest
    static void testBatchExecution() {
        // Execute the batch
        Test.startTest();
        batchMigrateOnboardingDocumentation batch = new batchMigrateOnboardingDocumentation();
        Database.executeBatch(batch, 2);
        Test.stopTest();
        
        // Verify that Customer_360__c records were created
        List<Customer_360__c> docs = [SELECT Id, Account__c FROM Customer_360__c];
        System.assertEquals(1, docs.size(), 'One documentation records should have been created.');
        
        // Verify that accounts have been updated
        List<Account> updatedAccounts = [SELECT Id, A_B_Test_Marker_Account__c FROM Account WHERE A_B_Test_Marker_Account__c = 'Done'];
        System.assertEquals(1, updatedAccounts.size(), 'One account should have been marked as Done.');
        List<Account> updatedAccounts2 = [SELECT Id, A_B_Test_Marker_Account__c FROM Account WHERE A_B_Test_Marker_Account__c = 'Done (no Note)'];
        System.assertEquals(1, updatedAccounts2.size(), 'One account should have been marked as Done (no Note).');
    }
}