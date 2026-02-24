@isTest
private class Test_batchOldJobCleanup {
    @isTest
    static void testBatchJob() {
        // Create required Account
        Account acct = new Account(Name = 'Test Account');
        insert acct;

        Date today = Date.today();
        List<Job__c> jobs = new List<Job__c>();

        // Active job (Published within 30 days)
        jobs.add(new Job__c(
            Published_At__c = today.addDays(-10),
            Account__c = acct.Id
        ));

        // Active job (Last updated within 30 days)
        jobs.add(new Job__c(
            Published_At__c = today.addDays(-40),
            Last_Updated_On__c = today.addDays(-10),
            Account__c = acct.Id
        ));

        // Inactive job (Published and updated beyond 30 days)
        jobs.add(new Job__c(
            Published_At__c = today.addDays(-40),
            Last_Updated_On__c = today.addDays(-40),
            Account__c = acct.Id
        ));

        // Inactive job (Published beyond 30 days, no Last_Updated_On__c)
        jobs.add(new Job__c(
            Published_At__c = today.addDays(-40),
            Account__c = acct.Id
        ));

        insert jobs;

        // Execute the batch job
        Test.startTest();
        Database.executeBatch(new batchOldJobCleanup());
        Test.stopTest();

        // Verify results
        Integer totalJobsAfterDeletion = [SELECT COUNT() FROM Job__c];
        System.assertEquals(2, totalJobsAfterDeletion, 'Only active jobs should remain');
    }
}