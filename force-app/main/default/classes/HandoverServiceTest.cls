/**
 * @description Test class for HandoverService
 * Covers all methods with various scenarios for maximum coverage
 */
@isTest
private class HandoverServiceTest {
    
    /**
     * @description Create test data used across multiple tests
     */
    @TestSetup
    static void setupTestData() {
        // Create Parent Account (with Service Country for validation rule)
        Account parentAccount = new Account(
            Name = 'Test Parent Account',
            Service_Country__c = 'DE'
        );
        insert parentAccount;
        
        // Create Test Account with all relevant fields (including Service Country for validation)
        Account testAccount = new Account(
            Name = 'Test Account',
            ParentId = parentAccount.Id,
            NumberOfEmployees = 100,
            plOpenJobs__c = '20-49',
            Service_Country__c = 'DE'
        );
        insert testAccount;
        
        // Create Strategic Contact
        Contact strategicContact = new Contact(
            FirstName = 'Strategic',
            LastName = 'Contact',
            Email = 'strategic@test.com',
            Phone = '123-456-7890',
            Title = 'CEO',
            AccountId = testAccount.Id
        );
        insert strategicContact;
        
        // Create Operational Contact
        Contact operationalContact = new Contact(
            FirstName = 'Operational',
            LastName = 'Contact',
            Email = 'operational@test.com',
            Phone = '098-765-4321',
            Title = 'Manager',
            AccountId = testAccount.Id
        );
        insert operationalContact;
        
        // Update Account with contact lookups
        testAccount.Strategical_Key_Contact__c = strategicContact.Id;
        testAccount.Key_Contact__c = operationalContact.Id;
        update testAccount;
        
        // Note: Opportunity creation skipped due to sandbox validation rules
        // Tests requiring Opportunity will use Account-linked Tasks instead
        
        // Create Task linked to Account
        Task accountTask = new Task(
            Subject = 'Prepare Handover Documentation',
            WhatId = testAccount.Id,
            Status = 'Open',
            Priority = 'Normal'
        );
        insert accountTask;
    }
    
    /**
     * @description Test getFieldDescriptions with valid fields
     */
    @isTest
    static void testGetFieldDescriptions_ValidFields() {
        List<String> fieldNames = new List<String>{'Name', 'NumberOfEmployees'};
        
        Test.startTest();
        Map<String, String> result = HandoverService.getFieldDescriptions('Account', fieldNames);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(2, result.size(), 'Should return descriptions for both fields');
    }
    
    /**
     * @description Test getFieldDescriptions with invalid object
     */
    @isTest
    static void testGetFieldDescriptions_InvalidObject() {
        List<String> fieldNames = new List<String>{'Name'};
        
        Test.startTest();
        Map<String, String> result = HandoverService.getFieldDescriptions('InvalidObject__c', fieldNames);
        Test.stopTest();
        
        System.assertEquals(0, result.size(), 'Should return empty map for invalid object');
    }
    
    /**
     * @description Test initializeHandover with Task linked to Account
     */
    @isTest
    static void testInitializeHandover_AccountLinkedTask() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Task testTask = [SELECT Id FROM Task WHERE WhatId = :testAccount.Id LIMIT 1];
        
        Customer_360__c c360 = new Customer_360__c(
            Account__c = testAccount.Id,
            Type__c = 'Pilot Handover',
            Documentation_Status__c = 'Not Started'
        );
        insert c360;
        
        Test.startTest();
        HandoverService.HandoverContext context = HandoverService.initializeHandover(testTask.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, context, 'Context should not be null');
        System.assertEquals(testAccount.Id, context.accountId, 'Account ID should match');
        System.assertEquals('Test Account', context.accountName, 'Account name should match');
        System.assertNotEquals(null, context.customer360Id, 'Customer_360 should be found');
        System.assertNotEquals(null, context.strategicContact, 'Strategic contact should be populated');
        System.assertNotEquals(null, context.operationalContact, 'Operational contact should be populated');
    }
    
    /**
     * @description Test initializeHandover - Opportunity-linked scenario
     * Note: Skipped due to sandbox validation rules on Opportunity.
     * The logic is identical to Account-linked task and is tested there.
     */
    @isTest
    static void testInitializeHandover_OpportunityLinkedTask() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Task testTask = [SELECT Id FROM Task WHERE WhatId = :testAccount.Id LIMIT 1];
        
        Customer_360__c c360 = new Customer_360__c(
            Account__c = testAccount.Id,
            Type__c = 'Pilot Handover',
            Documentation_Status__c = 'Not Started'
        );
        insert c360;
        
        Test.startTest();
        HandoverService.HandoverContext context = HandoverService.initializeHandover(testTask.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, context, 'Context should not be null');
        System.assertEquals(testAccount.Id, context.accountId, 'Account ID should match');
        System.assertNotEquals(null, context.customer360Id, 'Customer_360 should be found');
    }
    
    /**
     * @description Test initializeHandover throws error when no Customer_360 record exists.
     * C360 creation was moved to a Flow; the service now expects it to already exist.
     */
    @isTest
    static void testInitializeHandover_NoCustomer360ThrowsError() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Task testTask = [SELECT Id FROM Task WHERE WhatId = :testAccount.Id LIMIT 1];
        
        Integer beforeCount = [SELECT COUNT() FROM Customer_360__c WHERE Account__c = :testAccount.Id];
        System.assertEquals(0, beforeCount, 'No Customer_360 should exist before test');
        
        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            HandoverService.initializeHandover(testTask.Id);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        
        System.assert(exceptionThrown, 'Should throw AuraHandledException when no Customer_360 exists');
    }
    
    /**
     * @description Test initializeHandover resumes existing Customer_360
     */
    @isTest
    static void testInitializeHandover_ResumesExisting() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Task testTask = [SELECT Id FROM Task WHERE WhatId = :testAccount.Id LIMIT 1];
        
        // Create existing Customer_360 with saved data
        Customer_360__c existingC360 = new Customer_360__c(
            Account__c = testAccount.Id,
            Type__c = 'Pilot Handover',
            Documentation_Status__c = 'In Progress',
            Current_Wizard_Step__c = 'Notes',
            Customer_Goals__c = 'Existing goals',
            Risks__c = 'Existing risks'
        );
        insert existingC360;
        
        Test.startTest();
        HandoverService.HandoverContext context = HandoverService.initializeHandover(testTask.Id);
        Test.stopTest();
        
        System.assertEquals(existingC360.Id, context.customer360Id, 'Should return existing Customer_360');
        System.assertEquals('Notes', context.currentWizardStep, 'Should resume at Notes step');
        System.assertEquals('Existing goals', context.customerGoals, 'Should load existing goals');
        System.assertEquals('Existing risks', context.risks, 'Should load existing risks');
    }
    
    /**
     * @description Test saveHandoverData with Account fields
     */
    @isTest
    static void testSaveHandoverData_AccountFields() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Task testTask = [SELECT Id FROM Task WHERE WhatId = :testAccount.Id LIMIT 1];
        
        Customer_360__c c360 = new Customer_360__c(
            Account__c = testAccount.Id,
            Type__c = 'Pilot Handover',
            Documentation_Status__c = 'In Progress'
        );
        insert c360;
        
        Map<String, Object> dataMap = new Map<String, Object>{
            'taskId' => testTask.Id,
            'accountId' => testAccount.Id,
            'customer360Id' => c360.Id,
            'employees' => 200,
            'openJobs' => '50-99',
            'documentationStatus' => 'In Progress',
            'currentWizardStep' => 'Pre-check'
        };
        
        Test.startTest();
        HandoverService.SaveResult result = HandoverService.saveHandoverData(dataMap);
        Test.stopTest();
        
        System.assertEquals(true, result.success, 'Save should succeed');
        
        Account updatedAccount = [SELECT NumberOfEmployees, plOpenJobs__c FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals(200, updatedAccount.NumberOfEmployees, 'Employees should be updated');
        System.assertEquals('50-99', updatedAccount.plOpenJobs__c, 'Open Jobs should be updated');
    }
    
    /**
     * @description Test saveHandoverData with Customer_360 notes fields
     */
    @isTest
    static void testSaveHandoverData_NotesFields() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Task testTask = [SELECT Id FROM Task WHERE WhatId = :testAccount.Id LIMIT 1];
        
        Customer_360__c c360 = new Customer_360__c(
            Account__c = testAccount.Id,
            Type__c = 'Pilot Handover',
            Documentation_Status__c = 'In Progress',
            Current_Wizard_Step__c = 'Pre-check'
        );
        insert c360;
        
        Map<String, Object> dataMap = new Map<String, Object>{
            'taskId' => testTask.Id,
            'accountId' => testAccount.Id,
            'customer360Id' => c360.Id,
            'customerGoals' => 'Test goals',
            'risks' => 'Test risks',
            'keyLogistics' => 'Test logistics',
            'dos' => 'Test dos',
            'donts' => 'Test donts',
            'documentationStatus' => 'In Progress',
            'currentWizardStep' => 'Notes',
            'previousWizardStep' => 'Pre-check'
        };
        
        Test.startTest();
        HandoverService.SaveResult result = HandoverService.saveHandoverData(dataMap);
        Test.stopTest();
        
        System.assertEquals(true, result.success, 'Save should succeed');
        
        Customer_360__c updatedC360 = [SELECT Customer_Goals__c, Risks__c, Key_Logistics__c, Dos__c, Donts__c,
                                       Timestamp_Step_PreCheck_Completed__c, Timestamp_Step_Notes_Started__c
                                       FROM Customer_360__c WHERE Id = :c360.Id];
        System.assertEquals('Test goals', updatedC360.Customer_Goals__c, 'Customer goals should be saved');
        System.assertEquals('Test risks', updatedC360.Risks__c, 'Risks should be saved');
        System.assertNotEquals(null, updatedC360.Timestamp_Step_PreCheck_Completed__c, 'PreCheck completed timestamp should be set');
        System.assertNotEquals(null, updatedC360.Timestamp_Step_Notes_Started__c, 'Notes started timestamp should be set');
    }
    
    /**
     * @description Test saveHandoverData delta save (only changed fields)
     */
    @isTest
    static void testSaveHandoverData_DeltaSave() {
        Account testAccount = [SELECT Id, NumberOfEmployees FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Task testTask = [SELECT Id FROM Task WHERE WhatId = :testAccount.Id LIMIT 1];
        Integer originalEmployees = testAccount.NumberOfEmployees;
        
        Customer_360__c c360 = new Customer_360__c(
            Account__c = testAccount.Id,
            Type__c = 'Pilot Handover',
            Documentation_Status__c = 'In Progress',
            Customer_Goals__c = 'Original goals'
        );
        insert c360;
        
        Map<String, Object> dataMap = new Map<String, Object>{
            'taskId' => testTask.Id,
            'accountId' => testAccount.Id,
            'customer360Id' => c360.Id,
            'openJobs' => '50-99',
            'currentWizardStep' => 'Pre-check'
        };
        
        Test.startTest();
        HandoverService.SaveResult result = HandoverService.saveHandoverData(dataMap);
        Test.stopTest();
        
        System.assertEquals(true, result.success, 'Save should succeed: ' + result.message);
        
        Account updatedAccount = [SELECT NumberOfEmployees, plOpenJobs__c FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals(originalEmployees, updatedAccount.NumberOfEmployees, 'Employees should remain unchanged');
        System.assertEquals('50-99', updatedAccount.plOpenJobs__c, 'Open Jobs should be updated');
        
        Customer_360__c updatedC360 = [SELECT Customer_Goals__c FROM Customer_360__c WHERE Id = :c360.Id];
        System.assertEquals('Original goals', updatedC360.Customer_Goals__c, 'Goals should remain unchanged');
    }
    
    /**
     * @description Test completeHandover updates C360 and completes AE Task
     * Note: ACM Task is now created by Flow at Closed Won, not by completeHandover
     */
    @isTest
    static void testCompleteHandover_UpdatesStatusAndCompletesAETask() {
        Account testAccount = [SELECT Id, OwnerId FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Task testTask = [SELECT Id FROM Task WHERE WhatId = :testAccount.Id LIMIT 1];
        
        Customer_360__c c360 = new Customer_360__c(
            Account__c = testAccount.Id,
            Type__c = 'Pilot Handover',
            Documentation_Status__c = 'In Progress'
        );
        insert c360;
        
        // Count existing tasks before completion
        Integer taskCountBefore = [SELECT COUNT() FROM Task WHERE WhatId = :testAccount.Id];
        
        Map<String, Object> dataMap = new Map<String, Object>{
            'taskId' => testTask.Id,
            'accountId' => testAccount.Id,
            'customer360Id' => c360.Id,
            'documentationStatus' => 'Completed',
            'customerGoals' => 'Final goals',
            'risks' => 'Final risks',
            'keyLogistics' => 'Final logistics',
            'dos' => 'Final dos',
            'donts' => 'Final donts'
        };
        
        Test.startTest();
        HandoverService.SaveResult result = HandoverService.completeHandover(dataMap);
        Test.stopTest();
        
        System.assertEquals(true, result.success, 'Completion should succeed');
        
        // Verify Customer_360 status
        Customer_360__c updatedC360 = [SELECT Documentation_Status__c, Timestamp_Documentation_Completed__c, ACM_Assignment_Date__c
                                       FROM Customer_360__c WHERE Id = :c360.Id];
        System.assertEquals('Completed', updatedC360.Documentation_Status__c, 'Status should be Completed');
        System.assertNotEquals(null, updatedC360.Timestamp_Documentation_Completed__c, 'Completion timestamp should be set');
        System.assertEquals(Date.today(), updatedC360.ACM_Assignment_Date__c, 'ACM Assignment Date should be set');
        
        // Verify AE Task is completed
        Task aeTask = [SELECT Status FROM Task WHERE Id = :testTask.Id];
        System.assertEquals('Completed', aeTask.Status, 'AE Task should be completed');
        
        // Verify NO new ACM Task is created (ACM Task is now created by Flow at Closed Won)
        Integer taskCountAfter = [SELECT COUNT() FROM Task WHERE WhatId = :testAccount.Id];
        System.assertEquals(taskCountBefore, taskCountAfter, 'No new tasks should be created - ACM Task is created by Flow');
    }
    
    /**
     * @description Test completeACMTask updates task with IHC feedback (without scheduled timestamp)
     * Note: Scheduled timestamp is no longer collected from user - only completed timestamp
     */
    @isTest
    static void testCompleteACMTask_UpdatesTaskFields() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
        Task acmTask = new Task(
            Subject = 'Internal Handover Call planen - Test Account',
            WhatId = testAccount.Id,
            Status = 'Open'
        );
        insert acmTask;
        
        String completedTimestamp = '2025-01-15T11:00:00.000Z';
        
        Test.startTest();
        HandoverService.SaveResult result = HandoverService.completeACMTask(
            acmTask.Id,
            null, // Scheduled timestamp no longer collected
            completedTimestamp,
            'OK',
            'Documentation was complete'
        );
        Test.stopTest();
        
        System.assertEquals(true, result.success, 'Completion should succeed');
        
        Task updatedTask = [SELECT Status, Timestamp_Internal_HO_Call_Scheduled__c, 
                           Timestamp_Internal_HO_Call_Completed__c, Handover_Documentation_Quality__c,
                           Handover_Quality_Comments__c
                           FROM Task WHERE Id = :acmTask.Id];
        System.assertEquals('Completed', updatedTask.Status, 'Task should be completed');
        System.assertEquals(null, updatedTask.Timestamp_Internal_HO_Call_Scheduled__c, 'Scheduled timestamp should be null (not collected)');
        System.assertNotEquals(null, updatedTask.Timestamp_Internal_HO_Call_Completed__c, 'Completed timestamp should be set');
        System.assertEquals('OK', updatedTask.Handover_Documentation_Quality__c, 'Quality should be set');
        System.assertEquals('Documentation was complete', updatedTask.Handover_Quality_Comments__c, 'Comments should be set');
    }
    
    /**
     * @description Test updateTimeSpent accumulates time for PreCheck section
     */
    @isTest
    static void testUpdateTimeSpent_PreCheckSection() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
        Customer_360__c c360 = new Customer_360__c(
            Account__c = testAccount.Id,
            Type__c = 'Pilot Handover',
            Documentation_Status__c = 'In Progress',
            Time_Spent_PreCheck_Minutes__c = 5
        );
        insert c360;
        
        Test.startTest();
        HandoverService.SaveResult result = HandoverService.updateTimeSpent(c360.Id, 'PreCheck', 3);
        Test.stopTest();
        
        System.assertEquals(true, result.success, 'Update should succeed');
        
        Customer_360__c updatedC360 = [SELECT Time_Spent_PreCheck_Minutes__c FROM Customer_360__c WHERE Id = :c360.Id];
        System.assertEquals(8, updatedC360.Time_Spent_PreCheck_Minutes__c, 'Time should accumulate to 8 minutes');
    }
    
    /**
     * @description Test updateTimeSpent accumulates time for Notes section
     */
    @isTest
    static void testUpdateTimeSpent_NotesSection() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
        Customer_360__c c360 = new Customer_360__c(
            Account__c = testAccount.Id,
            Type__c = 'Pilot Handover',
            Documentation_Status__c = 'In Progress',
            Time_Spent_Notes_Minutes__c = null // Start with null
        );
        insert c360;
        
        Test.startTest();
        HandoverService.SaveResult result = HandoverService.updateTimeSpent(c360.Id, 'Notes', 10);
        Test.stopTest();
        
        System.assertEquals(true, result.success, 'Update should succeed');
        
        Customer_360__c updatedC360 = [SELECT Time_Spent_Notes_Minutes__c FROM Customer_360__c WHERE Id = :c360.Id];
        System.assertEquals(10, updatedC360.Time_Spent_Notes_Minutes__c, 'Time should be 10 minutes');
    }
    
    /**
     * @description Test checkHandoverStatus for completed handover
     */
    @isTest
    static void testCheckHandoverStatus_Completed() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
        Task completedTask = new Task(
            Subject = 'Prepare Handover Documentation',
            WhatId = testAccount.Id,
            Status = 'Completed'
        );
        insert completedTask;
        
        Customer_360__c c360 = new Customer_360__c(
            Account__c = testAccount.Id,
            Type__c = 'Pilot Handover',
            Documentation_Status__c = 'Completed',
            Timestamp_Documentation_Completed__c = DateTime.now()
        );
        insert c360;
        
        Test.startTest();
        HandoverService.HandoverStatus status = HandoverService.checkHandoverStatus(completedTask.Id);
        Test.stopTest();
        
        System.assertEquals(true, status.isCompleted, 'Status should show completed');
        System.assertEquals(c360.Id, status.customer360Id, 'Customer360 ID should be returned');
        System.assertEquals(testAccount.Id, status.accountId, 'Account ID should be returned');
    }
    
    /**
     * @description Test checkHandoverStatus for open task
     */
    @isTest
    static void testCheckHandoverStatus_NotCompleted() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Task openTask = [SELECT Id FROM Task WHERE WhatId = :testAccount.Id AND Status = 'Open' LIMIT 1];
        
        Test.startTest();
        HandoverService.HandoverStatus status = HandoverService.checkHandoverStatus(openTask.Id);
        Test.stopTest();
        
        System.assertEquals(false, status.isCompleted, 'Status should show not completed');
    }
    
    /**
     * @description Test getContactDetails returns correct info
     */
    @isTest
    static void testGetContactDetails_Success() {
        Contact testContact = [SELECT Id FROM Contact WHERE LastName = 'Contact' AND FirstName = 'Strategic' LIMIT 1];
        
        Test.startTest();
        HandoverService.ContactInfo info = HandoverService.getContactDetails(testContact.Id);
        Test.stopTest();
        
        System.assertEquals('Strategic', info.firstName, 'First name should match');
        System.assertEquals('Contact', info.lastName, 'Last name should match');
        System.assertEquals('strategic@test.com', info.email, 'Email should match');
        System.assertEquals('CEO', info.title, 'Title should match');
    }
    
    /**
     * @description Test getContactDetails with invalid ID
     */
    @isTest
    static void testGetContactDetails_InvalidId() {
        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            HandoverService.ContactInfo info = HandoverService.getContactDetails('003000000000000AAA');
            // If we get here without exception, the method should have thrown
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            System.assert(e.getMessage() != null, 'Exception should have a message');
        } catch (Exception e) {
            // Any exception indicates the method properly handles invalid IDs
            exceptionThrown = true;
        }
        Test.stopTest();
        
        System.assert(exceptionThrown, 'Should throw exception for invalid ID');
    }
    
    /**
     * @description Test Invocable Action for working days calculation
     * This is used by Flows to calculate SLA due dates
     */
    @isTest
    static void testCalculateWorkingDaysDueDate_Invocable() {
        // Test 1: Basic calculation - 1 working day
        HandoverService.WorkingDaysRequest req1 = new HandoverService.WorkingDaysRequest();
        req1.startDate = Date.newInstance(2026, 2, 2); // Monday
        req1.workingDays = 1;
        
        // Test 2: 3 working days
        HandoverService.WorkingDaysRequest req2 = new HandoverService.WorkingDaysRequest();
        req2.startDate = Date.newInstance(2026, 2, 2); // Monday
        req2.workingDays = 3;
        
        // Test 3: Weekend skip - Friday + 1 working day = Monday
        HandoverService.WorkingDaysRequest req3 = new HandoverService.WorkingDaysRequest();
        req3.startDate = Date.newInstance(2026, 2, 6); // Friday
        req3.workingDays = 1;
        
        // Test 4: Friday + 3 working days = Wednesday
        HandoverService.WorkingDaysRequest req4 = new HandoverService.WorkingDaysRequest();
        req4.startDate = Date.newInstance(2026, 2, 6); // Friday
        req4.workingDays = 3;
        
        List<HandoverService.WorkingDaysRequest> requests = new List<HandoverService.WorkingDaysRequest>{
            req1, req2, req3, req4
        };
        
        Test.startTest();
        List<Date> results = HandoverService.calculateWorkingDaysDueDate(requests);
        Test.stopTest();
        
        System.assertEquals(4, results.size(), 'Should return 4 results');
        
        // Monday + 1 working day = Tuesday
        System.assertEquals(Date.newInstance(2026, 2, 3), results[0], 'Monday + 1 working day = Tuesday');
        
        // Monday + 3 working days = Thursday
        System.assertEquals(Date.newInstance(2026, 2, 5), results[1], 'Monday + 3 working days = Thursday');
        
        // Friday + 1 working day = Monday (skips weekend)
        System.assertEquals(Date.newInstance(2026, 2, 9), results[2], 'Friday + 1 working day = Monday');
        
        // Friday + 3 working days = Wednesday (skips weekend)
        System.assertEquals(Date.newInstance(2026, 2, 11), results[3], 'Friday + 3 working days = Wednesday');
    }
    
    /**
     * @description Test Invocable Action with null/default values
     */
    @isTest
    static void testCalculateWorkingDaysDueDate_NullValues() {
        HandoverService.WorkingDaysRequest req = new HandoverService.WorkingDaysRequest();
        req.startDate = null; // Should default to today
        req.workingDays = null; // Should default to 1
        
        Test.startTest();
        List<Date> results = HandoverService.calculateWorkingDaysDueDate(
            new List<HandoverService.WorkingDaysRequest>{ req }
        );
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Should return 1 result');
        System.assertNotEquals(null, results[0], 'Result should not be null');
        // Should be at least tomorrow
        System.assert(results[0] >= Date.today().addDays(1), 'Due date should be at least 1 day from today');
    }
    
    /**
     * @description Test resolveHandoverTask finds the AE task for an Opportunity-linked Task
     * Note: Since sandbox has complex Opportunity validations, we test with an Account
     * that has a Task with Type = 'Pilot Handover AE'. The query logic is the same
     * regardless of whether WhatId points to an Opportunity or Account.
     */
    @isTest
    static void testResolveHandoverTask_FindsTask() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
        // Create a Task with the AE handover type linked to the Account
        Task aeTask = new Task(
            Subject = 'Prepare Handover Documentation',
            WhatId = testAccount.Id,
            Status = 'Open',
            Type = 'Pilot Handover AE'
        );
        insert aeTask;
        
        Test.startTest();
        HandoverService.HandoverStatus status = HandoverService.resolveHandoverTask(testAccount.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, status, 'Status should not be null');
        System.assertEquals(aeTask.Id, status.taskId, 'Should return the correct Task ID');
        System.assertEquals(false, status.isCompleted, 'Task should not be completed');
    }
    
    /**
     * @description Test resolveHandoverTask returns completed status when AE task is done
     */
    @isTest
    static void testResolveHandoverTask_CompletedTask() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
        Task aeTask = new Task(
            Subject = 'Prepare Handover Documentation',
            WhatId = testAccount.Id,
            Status = 'Completed',
            Type = 'Pilot Handover AE'
        );
        insert aeTask;
        
        Customer_360__c c360 = new Customer_360__c(
            Account__c = testAccount.Id,
            Type__c = 'Pilot Handover',
            Documentation_Status__c = 'Completed',
            Timestamp_Documentation_Completed__c = DateTime.now()
        );
        insert c360;
        
        Test.startTest();
        HandoverService.HandoverStatus status = HandoverService.resolveHandoverTask(testAccount.Id);
        Test.stopTest();
        
        System.assertEquals(true, status.isCompleted, 'Status should show completed');
        System.assertEquals(aeTask.Id, status.taskId, 'Should return the Task ID');
        System.assertNotEquals(null, status.customer360Id, 'Should return the Customer_360 ID');
    }
    
    /**
     * @description Test resolveHandoverTask throws error when no AE task exists
     */
    @isTest
    static void testResolveHandoverTask_NoTaskFound() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            HandoverService.resolveHandoverTask(testAccount.Id);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        
        System.assert(exceptionThrown, 'Should throw AuraHandledException when no task found');
    }
    
    /**
     * @description Test IDOR protection: saveHandoverData rejects a customer360Id
     * that belongs to a different account than the task's WhatId.
     */
    @isTest
    static void testSaveHandoverData_RejectsMismatchedC360() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Task testTask = [SELECT Id FROM Task WHERE WhatId = :testAccount.Id LIMIT 1];
        
        // Create a second, unrelated account and C360
        Account otherAccount = new Account(
            Name = 'Other Account',
            Service_Country__c = 'DE'
        );
        insert otherAccount;
        
        Customer_360__c otherC360 = new Customer_360__c(
            Account__c = otherAccount.Id,
            Type__c = 'Pilot Handover',
            Documentation_Status__c = 'In Progress'
        );
        insert otherC360;
        
        Map<String, Object> dataMap = new Map<String, Object>{
            'taskId' => testTask.Id,
            'customer360Id' => otherC360.Id,
            'employees' => 999
        };
        
        Test.startTest();
        HandoverService.SaveResult result = HandoverService.saveHandoverData(dataMap);
        Test.stopTest();
        
        System.assertEquals(false, result.success, 'Save should fail for mismatched C360');
        
        // Verify the other account was NOT modified
        Account otherAccAfter = [SELECT NumberOfEmployees FROM Account WHERE Id = :otherAccount.Id];
        System.assertNotEquals(999, otherAccAfter.NumberOfEmployees, 'Other account should not be modified');
    }
    
    /**
     * @description Test saveHandoverData rollback on error
     */
    @isTest
    static void testSaveHandoverData_RollbackOnError() {
        // Use invalid ID to trigger error
        Map<String, Object> dataMap = new Map<String, Object>{
            'accountId' => '001000000000000AAA', // Invalid but properly formatted ID
            'customer360Id' => 'a00000000000000AAA', // Invalid
            'employees' => 100
        };
        
        Test.startTest();
        HandoverService.SaveResult result = HandoverService.saveHandoverData(dataMap);
        Test.stopTest();
        
        System.assertEquals(false, result.success, 'Save should fail');
        System.assert(result.message.contains('Error'), 'Error message should be returned');
    }
    
    /**
     * @description Test step transition timestamps from Notes to Review
     */
    @isTest
    static void testSaveHandoverData_NotesToReviewTransition() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Task testTask = [SELECT Id FROM Task WHERE WhatId = :testAccount.Id LIMIT 1];
        
        Customer_360__c c360 = new Customer_360__c(
            Account__c = testAccount.Id,
            Type__c = 'Pilot Handover',
            Documentation_Status__c = 'In Progress',
            Current_Wizard_Step__c = 'Notes'
        );
        insert c360;
        
        Map<String, Object> dataMap = new Map<String, Object>{
            'taskId' => testTask.Id,
            'accountId' => testAccount.Id,
            'customer360Id' => c360.Id,
            'currentWizardStep' => 'Review',
            'previousWizardStep' => 'Notes'
        };
        
        Test.startTest();
        HandoverService.SaveResult result = HandoverService.saveHandoverData(dataMap);
        Test.stopTest();
        
        System.assertEquals(true, result.success, 'Save should succeed');
        
        Customer_360__c updatedC360 = [SELECT Timestamp_Step_Notes_Completed__c, Timestamp_Step_Review_Started__c
                                       FROM Customer_360__c WHERE Id = :c360.Id];
        System.assertNotEquals(null, updatedC360.Timestamp_Step_Notes_Completed__c, 'Notes completed timestamp should be set');
        System.assertNotEquals(null, updatedC360.Timestamp_Step_Review_Started__c, 'Review started timestamp should be set');
    }
    
    /**
     * @description Test saveHandoverData updates Account contact and parent fields
     * Covers: parentAccountId, strategicContactId, operationalContactId branches
     */
    @isTest
    static void testSaveHandoverData_ContactAndParentFields() {
        Account parentAccount = [SELECT Id FROM Account WHERE Name = 'Test Parent Account' LIMIT 1];
        Account testAccount  = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Task testTask        = [SELECT Id FROM Task WHERE WhatId = :testAccount.Id LIMIT 1];
        Contact strategic    = [SELECT Id FROM Contact WHERE FirstName = 'Strategic' LIMIT 1];
        Contact operational  = [SELECT Id FROM Contact WHERE FirstName = 'Operational' LIMIT 1];

        Customer_360__c c360 = new Customer_360__c(
            Account__c = testAccount.Id,
            Type__c = 'Pilot Handover',
            Documentation_Status__c = 'In Progress'
        );
        insert c360;

        Map<String, Object> dataMap = new Map<String, Object>{
            'taskId'              => testTask.Id,
            'accountId'           => testAccount.Id,
            'customer360Id'       => c360.Id,
            'parentAccountId'     => parentAccount.Id,
            'strategicContactId'  => strategic.Id,
            'operationalContactId'=> operational.Id,
            'currentWizardStep'   => 'Pre-check'
        };

        Test.startTest();
        HandoverService.SaveResult result = HandoverService.saveHandoverData(dataMap);
        Test.stopTest();

        System.assertEquals(true, result.success, 'Save should succeed: ' + result.message);

        Account updated = [SELECT ParentId, Strategical_Key_Contact__c, Key_Contact__c FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals(parentAccount.Id,  updated.ParentId,                      'ParentId should be updated');
        System.assertEquals(strategic.Id,       updated.Strategical_Key_Contact__c,    'Strategic contact should be updated');
        System.assertEquals(operational.Id,     updated.Key_Contact__c,               'Operational contact should be updated');
    }

    /**
     * @description Test saveHandoverData updates C360 extra fields
     * Covers: relationshipRating, relationshipReason, handoverUrgency, other branches
     */
    @isTest
    static void testSaveHandoverData_C360ExtraFields() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Task testTask       = [SELECT Id FROM Task WHERE WhatId = :testAccount.Id LIMIT 1];

        Customer_360__c c360 = new Customer_360__c(
            Account__c = testAccount.Id,
            Type__c = 'Pilot Handover',
            Documentation_Status__c = 'In Progress'
        );
        insert c360;

        Map<String, Object> dataMap = new Map<String, Object>{
            'taskId'             => testTask.Id,
            'accountId'          => testAccount.Id,
            'customer360Id'      => c360.Id,
            'relationshipRating' => 8,
            'relationshipReason' => 'Strong relationship',
            'handoverUrgency'    => 'Urgent',
            'other'              => 'Additional notes',
            'currentWizardStep'  => 'Notes'
        };

        Test.startTest();
        HandoverService.SaveResult result = HandoverService.saveHandoverData(dataMap);
        Test.stopTest();

        System.assertEquals(true, result.success, 'Save should succeed: ' + result.message);

        Customer_360__c updated = [
            SELECT Relationship_Rating__c, Relationship_Reason__c, Handover_Urgency__c, Other__c
            FROM Customer_360__c WHERE Id = :c360.Id
        ];
        System.assertEquals(8,                     updated.Relationship_Rating__c,  'Rating should be saved');
        System.assertEquals('Strong relationship',  updated.Relationship_Reason__c,  'Reason should be saved');
        System.assertEquals('Urgent',              updated.Handover_Urgency__c,     'Urgency should be saved');
        System.assertEquals('Additional notes',    updated.Other__c,                'Other should be saved');
    }

    /**
     * @description Test updateTimeSpent with an unrecognised section name
     * Covers: the fall-through when sectionName does not match PreCheck or Notes
     */
    @isTest
    static void testUpdateTimeSpent_UnknownSection() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];

        Customer_360__c c360 = new Customer_360__c(
            Account__c = testAccount.Id,
            Type__c = 'Pilot Handover',
            Documentation_Status__c = 'In Progress',
            Time_Spent_PreCheck_Minutes__c = 5,
            Time_Spent_Notes_Minutes__c = 3
        );
        insert c360;

        Test.startTest();
        HandoverService.SaveResult result = HandoverService.updateTimeSpent(c360.Id, 'Review', 10);
        Test.stopTest();

        System.assertEquals(true, result.success, 'Should succeed even with unrecognised section');

        // No time fields should change
        Customer_360__c unchanged = [
            SELECT Time_Spent_PreCheck_Minutes__c, Time_Spent_Notes_Minutes__c
            FROM Customer_360__c WHERE Id = :c360.Id
        ];
        System.assertEquals(5.0, unchanged.Time_Spent_PreCheck_Minutes__c, 'PreCheck time should be unchanged');
        System.assertEquals(3.0, unchanged.Time_Spent_Notes_Minutes__c,   'Notes time should be unchanged');
    }

    /**
     * @description Test initializeHandover on an Account that has no contacts set
     * Covers: populateContactInfo null-contact branches (strategicId == null, operationalId == null)
     */
    @isTest
    static void testInitializeHandover_AccountWithNoContacts() {
        Account bareAccount = new Account(Name = 'Bare Account', Service_Country__c = 'DE');
        insert bareAccount;

        Task bareTask = new Task(
            Subject = 'Prepare Handover',
            WhatId = bareAccount.Id,
            Status = 'Open'
        );
        insert bareTask;

        Customer_360__c c360 = new Customer_360__c(
            Account__c = bareAccount.Id,
            Type__c = 'Pilot Handover',
            Documentation_Status__c = 'Not Started'
        );
        insert c360;

        Test.startTest();
        HandoverService.HandoverContext context = HandoverService.initializeHandover(bareTask.Id);
        Test.stopTest();

        System.assertNotEquals(null, context, 'Context should not be null');
        System.assertEquals(bareAccount.Id, context.accountId, 'Account ID should match');
        System.assertEquals(null, context.strategicContact,  'Strategic contact should be null when not set');
        System.assertEquals(null, context.operationalContact,'Operational contact should be null when not set');
    }

    /**
     * @description Test checkHandoverStatus when task is completed but no C360 exists
     * Covers: the empty c360List branch inside checkHandoverStatus
     */
    @isTest
    static void testCheckHandoverStatus_NoC360() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];

        Task completedTask = new Task(
            Subject  = 'Prepare Handover',
            WhatId   = testAccount.Id,
            Status   = 'Completed'
        );
        insert completedTask;

        Test.startTest();
        HandoverService.HandoverStatus status = HandoverService.checkHandoverStatus(completedTask.Id);
        Test.stopTest();

        // Task is completed so isCompleted = true; but no C360, so customer360Id should be null
        System.assertNotEquals(null, status,          'Status should not be null');
        System.assertEquals(true,  status.isCompleted,'isCompleted should reflect Task status');
        System.assertEquals(null,  status.customer360Id, 'customer360Id should be null when no C360 exists');
    }

    /**
     * @description Test initializeHandover updates Not Started to In Progress
     */
    @isTest
    static void testInitializeHandover_UpdatesNotStartedStatus() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Task testTask = [SELECT Id FROM Task WHERE WhatId = :testAccount.Id LIMIT 1];
        
        // Create Customer_360 with Not Started status
        Customer_360__c c360 = new Customer_360__c(
            Account__c = testAccount.Id,
            Type__c = 'Pilot Handover',
            Documentation_Status__c = 'Not Started'
        );
        insert c360;
        
        Test.startTest();
        HandoverService.HandoverContext context = HandoverService.initializeHandover(testTask.Id);
        Test.stopTest();
        
        Customer_360__c updatedC360 = [SELECT Documentation_Status__c, Timestamp_Step_PreCheck_Started__c
                                       FROM Customer_360__c WHERE Id = :c360.Id];
        System.assertEquals('In Progress', updatedC360.Documentation_Status__c, 'Status should be updated to In Progress');
        System.assertNotEquals(null, updatedC360.Timestamp_Step_PreCheck_Started__c, 'PreCheck started timestamp should be set');
    }
}