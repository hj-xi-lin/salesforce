@isTest
private class Test_scheduleOldJobCleanup {
    @isTest
    static void testScheduler() {
        Test.startTest();
        String cronExpression = '0 0 6 ? * 1'; // Every Sunday at 6:00 AM
        System.schedule('Test Job Cleanup Weekly Schedule', cronExpression, new scheduleOldJobCleanup());
        Test.stopTest();
        CronTrigger ct = [SELECT Id, CronExpression FROM CronTrigger WHERE CronJobDetail.Name = 'Test Job Cleanup Weekly Schedule'];
        System.assertEquals('0 0 6 ? * 1', ct.CronExpression, 'Cron expression should match weekly schedule');
    }
}