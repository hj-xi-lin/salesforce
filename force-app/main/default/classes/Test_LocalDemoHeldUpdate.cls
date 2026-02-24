@isTest
public class Test_LocalDemoHeldUpdate {
    @isTest
    static void testUpdateDemoFields() {
        // Create test data - account and opportunity and task records
        Account testAccount = new Account(
            Name = 'Test Account',
            Service_Country__c = 'DE'
        );
        insert testAccount;
        Id sfAdminUserId = [SELECT Id FROM User WHERE Name = 'Salesforce Admin' LIMIT 1].Id;
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Closed Lost',
            dateTimestampClosedWonLost__c = Date.today(),
            Timestamp_Demo_Held__c = null,
            CloseDate = Date.today(),
            AccountId = testAccount.Id,
            OwnerId = sfAdminUserId
        );
        insert testOpportunity;

        Task testTask = new Task(
            Subject = 'Test Call',
            CallType = 'Inbound',
            CallDurationInSeconds = 130,
            WhatId = testOpportunity.Id,
            CreatedDate = DateTime.now().addMinutes(-10),
            OwnerId = sfAdminUserId
        );
        insert testTask;

        // Execute the method being tested
        Test.startTest();
        List<Opportunity> oppListToUpdate = new List<Opportunity>{ testOpportunity };
        LocalDemoHeldUpdate.UpdateDemoFields(oppListToUpdate);
        Test.stopTest();

        // Retrieve the updated Opportunity record and verify the fields
        Opportunity updatedOpportunity = [SELECT Id, Demo_Date__c, Hunter__c, Timestamp_Demo_Held__c, Timestamp_Demo_Held_Time__c FROM Opportunity WHERE Id = :testOpportunity.Id];

        // Assert that the fields have been updated correctly
        System.assertEquals(testTask.CreatedDate.date(), updatedOpportunity.Demo_Date__c, 'Demo_Date__c field not updated correctly.');
        System.assertEquals(testTask.OwnerId, updatedOpportunity.Hunter__c, 'Hunter__c field not updated correctly.');
        System.assertEquals(testTask.CreatedDate.date(), updatedOpportunity.Timestamp_Demo_Held__c, 'Timestamp_Demo_Held__c field not updated correctly.');
        System.assertEquals(testTask.CreatedDate, updatedOpportunity.Timestamp_Demo_Held_Time__c, 'Timestamp_Demo_Held_Time__c field not updated correctly.');
    }

    @isTest
    static void testUpdateDemoFields_NoRelatedCall() {
        // Create test data - account and opportunity without any related calls
        Account testAccount = new Account(
            Name = 'Test Account',
            Service_Country__c = 'DE'
        );
        insert testAccount;
        Id sfAdminUserId = [SELECT Id FROM User WHERE Name = 'Salesforce Admin' LIMIT 1].Id;
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Closed Lost',
            dateTimestampClosedWonLost__c = Date.today(),
            Timestamp_Demo_Held__c = null,
            CloseDate = Date.today(),
            AccountId = testAccount.Id,
            OwnerId = sfAdminUserId
        );
        insert testOpportunity;

        // Execute the method being tested
        Test.startTest();
        List<Opportunity> oppListToUpdate = new List<Opportunity>{ testOpportunity };
        LocalDemoHeldUpdate.UpdateDemoFields(oppListToUpdate);
        Test.stopTest();

        // Retrieve the updated Opportunity record and verify the fields remain unchanged
        Opportunity updatedOpportunity = [SELECT Id, Demo_Date__c, Hunter__c, Timestamp_Demo_Held__c, Timestamp_Demo_Held_Time__c FROM Opportunity WHERE Id = :testOpportunity.Id];

        // Assert that the fields have not been updated
        System.assertEquals(null, updatedOpportunity.Demo_Date__c, 'Demo_Date__c field should remain null.');
        System.assertEquals(null, updatedOpportunity.Hunter__c, 'Hunter__c field should remain null.');
        System.assertEquals(null, updatedOpportunity.Timestamp_Demo_Held__c, 'Timestamp_Demo_Held__c field should remain null.');
        System.assertEquals(null, updatedOpportunity.Timestamp_Demo_Held_Time__c, 'Timestamp_Demo_Held_Time__c field should remain null.');
    }

}