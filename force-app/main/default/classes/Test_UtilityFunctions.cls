@isTest
private class Test_UtilityFunctions {

    @isTest
    static void testGetRecruiterFirstAndLastName_MultipleString() {
        List<UtilityFunctions.RecruiterDetailsInput> recruiterInputList = new List<UtilityFunctions.RecruiterDetailsInput>();
        UtilityFunctions.RecruiterDetailsInput recruiterInput = new UtilityFunctions.RecruiterDetailsInput();
        recruiterInput.recruiterName = 'John Doe Smith';
        recruiterInputList.add(recruiterInput);
        
        Test.startTest();
        List<UtilityFunctions.RecruiterDetailsOutput> results =
            UtilityFunctions.getRecruiterFirstAndLastName(recruiterInputList);
        Test.stopTest();
        
        System.assertEquals(1, results.size());
        System.assertEquals('John', results[0].recruiterFirstName);
        System.assertEquals('Doe Smith', results[0].recruiterLastName);
    }
    
    @isTest
    static void testGetRecruiterFirstAndLastName_SingleString() {
        List<UtilityFunctions.RecruiterDetailsInput> recruiterInputList = new List<UtilityFunctions.RecruiterDetailsInput>();
        UtilityFunctions.RecruiterDetailsInput recruiterInput = new UtilityFunctions.RecruiterDetailsInput();
        recruiterInput.recruiterName = 'Alexandra';
        recruiterInputList.add(recruiterInput);
        
        Test.startTest();
        List<UtilityFunctions.RecruiterDetailsOutput> results =
            UtilityFunctions.getRecruiterFirstAndLastName(recruiterInputList);
        Test.stopTest();
        
        System.assertEquals(1, results.size());
        System.assertEquals('', results[0].recruiterFirstName);
        System.assertEquals('Alexandra', results[0].recruiterLastName);
    }
    
    @isTest
    static void testUpdateStageACMOnReactivation() {
        Account testAccount = new Account(Name='Test Account', Service_Country__c = 'DE');
        insert testAccount;
        
        Opportunity testOpportunity = new Opportunity(
            Name='Test Opportunity',
            AccountId=testAccount.Id,
            StageName='Closed Lost',
            CloseDate= Date.today()+15
        );
        insert testOpportunity;
        
        List<Opportunity> oppList = new List<Opportunity>{ testOpportunity };
        
        Test.startTest();
        List<Account> updatedAccounts =
            UtilityFunctions.updateStageACMOnReactivation(oppList);
        Test.stopTest();
        
        System.assertEquals(1, updatedAccounts.size());
        System.assertEquals('Prospect', updatedAccounts[0].Stage_ACM__c);
    }

    @isTest
    static void testProcessCategoryAndClientOnAccount() {

        Category3__c cat = new Category3__c(
            Category__c = 'Logistics',
            Reference_Clients__c = 'Deutsche Post',
            HeyJobs_Category__c = 'Logistics'
        );
        insert cat;

        Account acc = new Account(
            Name = 'Acc1',
            Service_Country__c = 'DE',
            Category_1__c = 'Service Provider',
            Category_2__c = 'Transport & Logistics',
            Category_3__c = 'Logistics'
        );
        insert acc;

        Test.startTest();
        UtilityFunctions.processCategoryAndClientOnAccount(new List<Account>{ acc });
        Test.stopTest();

        Account updated = [
            SELECT X2020_Reference_Clients__c, HeyJobs_Category__c
            FROM Account WHERE Id = :acc.Id
        ];

        System.assertEquals('Logistics', updated.X2020_Reference_Clients__c);
        System.assertEquals('Logistics', updated.HeyJobs_Category__c);
    }

    @isTest
    static void testProcessReferenceClientChanges() {

        Category3__c cat = new Category3__c(
            Category__c = 'Logistics',
            Reference_Clients__c = 'OldValue',
            HeyJobs_Category__c = 'Logistics'
        );
        insert cat;

        Account acc = new Account(
            Name = 'Retail Acc',
            Service_Country__c='DE',
            Category_1__c = 'Service Provider',
            Category_2__c = 'Transport & Logistics',
            Category_3__c = 'Logistics'
        );
        insert acc;

        Category3__c changed = new Category3__c(
            Id = cat.Id,
            Category__c = 'Logistics',
            Reference_Clients__c = 'NewClient'
        );

        Test.startTest();
        UtilityFunctions.processReferenceClientChanges(new List<Category3__c>{ changed });
        Test.stopTest();

        Account updated = [
            SELECT X2020_Reference_Clients__c
            FROM Account WHERE Id=:acc.Id
        ];

        System.assertEquals('NewClient', updated.X2020_Reference_Clients__c);
    }
}