@isTest
public class test_Customer360Functions {
    
    @testSetup
    static void setupTestData() {
        // Create Accounts
        Account acc1 = new Account(Name = 'Acc 1', AI_Summary_Helper__c = null); 
        Account acc2 = new Account(Name = 'Acc 2', AI_Summary_Helper__c = null); 
        Account acc3 = new Account(Name = 'Acc 3', AI_Summary_Helper__c = null, Service_Country__c = 'DE'); 
        insert new List<Account>{acc1, acc2, acc3};

         // Create related data for Acc 1
        Contact contactForAcc1 = new Contact(
            LastName = 'Test Contact',
            Email = 'test.accountsummary@test.com',
            AccountId = acc1.Id
        );
        insert contactForAcc1;
        
        Event eventForAcc1 = new Event(
            WhatId = acc1.Id,
            WhoId = contactForAcc1.Id,
            Subject = 'Test Event',
            ActivityDateTime = DateTime.now().addDays(-10),
            DurationInMinutes = 60,
            Description = 'Test'
        );
        insert eventForAcc1;
        
        Customer_360__c c360ForAcc1 = new Customer_360__c(
            Account__c = acc1.Id,
            Type__c = 'Events',
            Content_max_limit__c = '2000-11-08 10:45:00 | Outreach | Assigned User | Related Contacts | Event Duration'
        );
        insert c360ForAcc1;
        
        // Create related data for Acc 2
        Task taskForAcc2 = new Task(
            WhatId = acc2.Id,
            Subject = 'Test Call',
            Status = 'Completed',
            CallType = 'Inbound',
            Description = 'Test',
            ActivityDate = Date.today() 
        );
        insert taskForAcc2;
		
        Customer_360__c c360ForAcc2 = new Customer_360__c(
            Account__c = acc2.Id,
            Type__c = 'Calls',
            Content_max_limit__c = '2024-09-16 15:17:52 | Outbound Call - Answered - aircall - 2024-09-16 15:17:52Z | Assigned User | Related Contact | Call Duration | Description: null'
        );
        insert c360ForAcc2;

        // Create related data for Acc 3
        Opportunity oppForAcc3 = new Opportunity(
            AccountId = acc3.Id,
            Name = 'Test Opp',
            StageName = 'In Discussion',
            RecordTypeId = '0120Y000000Ay9JQAS',
            Amount = 1,
            CloseDate = Date.today().addMonths(1) 
        );
        insert oppForAcc3;

        Customer_360__c c360ForAcc3 = new Customer_360__c(
            Account__c = acc3.Id,
            Type__c = 'Calls',
            Content_max_limit__c = ''
        );
        insert c360ForAcc3;
    }

    @isTest
    static void testCreateHelperRecords() {
        // Fetch Accounts and simulate the update
        List<Account> newAccounts = [SELECT Id, Name, AI_Summary_Helper__c FROM Account WHERE Name IN ('Acc 1', 'Acc 2', 'Acc 3')];
        for (Account acc : newAccounts) {
            acc.AI_Summary_Helper__c = 'Create Helper Records'; // Simulate the update
        }

        List<Account> oldAccounts = [SELECT Id, Name, AI_Summary_Helper__c FROM Account WHERE Name IN ('Acc 1', 'Acc 2', 'Acc 3')];
        for (Account acc : oldAccounts) {
            acc.AI_Summary_Helper__c = null;
        }
        
        // Call the method
        Test.startTest();
        Customer360Functions.createHelperRecords(newAccounts, oldAccounts);
        Test.stopTest();

        // Verify Acc 1
        List<Customer_360__c> acc1C360Records = [SELECT Type__c, Content_max_limit__c FROM Customer_360__c WHERE Account__c = :newAccounts[0].Id];
        System.assertEquals(3, acc1C360Records.size(), 'Acc 1 should have 3 related Customer 360 records.');
        for (Customer_360__c record : acc1C360Records) {
            if (record.Type__c == 'Events') {
                System.assert(String.isNotBlank(record.Content_max_limit__c) && record.Content_max_limit__c != 'none', 'Acc 1 Events record should not be empty or "none".');
            }
        }

        // Verify Acc 2
        /*List<Customer_360__c> acc2C360Records = [SELECT Type__c, Content_max_limit__c FROM Customer_360__c WHERE Account__c = :newAccounts[1].Id];
        System.assertEquals(4, acc2C360Records.size(), 'Acc 2 should have 4 related Customer 360 records.');
        for (Customer_360__c record : acc2C360Records) {
            if (record.Type__c == 'Tasks') {
                System.assert(String.isNotBlank(record.Content_max_limit__c) && record.Content_max_limit__c != 'none', 'Acc 2 Tasks record should not be empty or "none".');
            }
        }
		*/

        // Verify Acc 3
        List<Customer_360__c> acc3C360Records = [SELECT Type__c, Content_max_limit__c FROM Customer_360__c WHERE Account__c = :newAccounts[2].Id];
        System.assertEquals(3, acc3C360Records.size(), 'Acc 3 should have 3 related Customer 360 records.');
        for (Customer_360__c record : acc3C360Records) {
            if (record.Type__c == 'Deals') {
                System.assert(String.isNotBlank(record.Content_max_limit__c) || record.Content_max_limit__c == 'none', 'Acc 3 Deals record should not be empty unless it is "none".');
            }
        }
    }
}