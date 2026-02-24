@isTest
public class test_batchAutoCloseOpps {
    @isTest
    static void testBatchAutoCloseOpps() {
        // Retrieve necessary record type IDs
        Id oppSalesRT = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Sales').getRecordTypeId();
        Id oppTransactionalRT = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Sales_Transactional').getRecordTypeId();
        Id accOutboundRT = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Outbound').getRecordTypeId();

        // Create test accounts
        Account testAcct1 = new Account(
            Name = 'Auto Closing Sales Account 1',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Sales').getRecordTypeId(),
            Service_Country__c = 'DE',
            HeyJobs_Category__c = 'Logistics',
            NumberOfEmployees = 1234,
            plOpenJobs__c = '5-9',
            GTM_Motion_Account__c = 'Subscription New Business'
        );

        Account testAcct2 = new Account(
            Name = 'Auto Closing Sales Account 2',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Sales').getRecordTypeId(),
            Service_Country__c = 'DE',
            HeyJobs_Category__c = 'Logistics',
            NumberOfEmployees = 234,
            plOpenJobs__c = '5-9',
            GTM_Motion_Account__c = 'Inside Sales'
        );

        insert new List<Account>{testAcct1, testAcct2};

        // Create test opportunities
        List<Opportunity> testOpps = new List<Opportunity>{
            new Opportunity(Name = 'Test_ToBeClosed', RecordTypeId = oppTransactionalRT, StageName = 'Ready for Sales', CloseDate = Date.today(), Competitor_1_current_future__c = 'None', AccountId = testAcct1.Id),
            new Opportunity(Name = 'Test_TooYoung', RecordTypeId = oppSalesRT, StageName = 'Not reached yet', CloseDate = Date.today(), AccountId = testAcct2.Id, Opportunity_Creation_Trigger__c = '2. Auto ClosedWon'),
            new Opportunity(Name = 'Test_ToBeClosed_NoTrigger', RecordTypeId = oppSalesRT, StageName = 'Not reached yet', CloseDate = Date.today(), AccountId = testAcct2.Id),
            new Opportunity(Name = 'Test_EnterpriseNewBusiness', RecordTypeId = oppSalesRT, StageName = 'Not reached yet', CloseDate = Date.today(), AccountId = testAcct2.Id, Opportunity_Creation_Trigger__c = '2. Auto ClosedWon', GTM_Motion_Opportunity__c = 'Enterprise New Business')
        };

        insert testOpps;

        // Modify Created Dates
        Integer oppThresholdAge1 = Integer.valueOf(Label.HouseKeeping_OppLosingThreshold); // 30 days
        Integer oppThresholdAge2 = Integer.valueOf(Label.HouseKeeping_UploadOppLosingThreshold); // 60 days
        DateTime thresholdDateTime1 = DateTime.now().addDays(-oppThresholdAge1);
        DateTime thresholdDateTime2 = DateTime.now().addDays(-oppThresholdAge2);
        Test.setCreatedDate(testOpps[0].Id, thresholdDateTime1.addDays(-31)); // 31 days old
        Test.setCreatedDate(testOpps[1].Id, thresholdDateTime1.addDays(1));  // 29 days old
        Test.setCreatedDate(testOpps[2].Id, thresholdDateTime2.addDays(-1)); // 61 days old
        Test.setCreatedDate(testOpps[3].Id, thresholdDateTime1.addDays(-1)); // 31 days old

        Test.startTest();
        Database.executeBatch(new batchAutoCloseOpps());
        Test.stopTest();

        // Re-query all Opportunities after batch execution for fresh data
        List<Opportunity> refreshedTestOpps = [
            SELECT Id, Record_Type__c, StageName, plLossReason__c, Account.OwnerId, Account.RecordTypeId, Account.Stage_ACM__c, GTM_Motion_Opportunity__c
            FROM Opportunity
            WHERE Id IN :testOpps
        ];

        // Assertions
        for (Opportunity opp : refreshedTestOpps) {
            if (opp.Id == testOpps[0].Id || opp.Id == testOpps[2].Id) {
                System.assertEquals('Closed Lost', opp.StageName, 'Opp should be closed.');
                System.assertEquals(Label.HouseKeeping_OppLosingLossReason, opp.plLossReason__c, 'Opp should have the correct loss reason.');
                System.assertEquals(accOutboundRT, opp.Account.RecordTypeId, 'Account should be in RT Outbound.');
            }
        }
    }
}