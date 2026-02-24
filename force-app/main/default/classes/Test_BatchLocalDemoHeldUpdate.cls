@isTest
public class Test_BatchLocalDemoHeldUpdate {
    @isTest
    static void testBatchLocalDemoHeldUpdate() {
        // Create test data - account and opportunity records
        Account testAccount = new Account(
            Name = 'Test Account',
            Service_Country__c = 'DE'
        );
        insert testAccount;
        List<Opportunity> testOpportunities = new List<Opportunity>();
        for (Integer i = 0; i < 5; i++) {
            Opportunity opp = new Opportunity(
                Name = 'Test Opportunity ' + i,
                RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sales').getRecordTypeId(),
                StageName = 'Closed Lost',
                dateTimestampClosedWonLost__c = Date.today(),
                Timestamp_Demo_Held__c = null,
                CloseDate = Date.today(),
                AccountId = testAccount.Id
            );
            testOpportunities.add(opp);
        }
        insert testOpportunities;
        
        Test.startTest();
        Database.executeBatch(new batchLocalDemoHeldUpdate());
        Test.stopTest();

    
        }

    }