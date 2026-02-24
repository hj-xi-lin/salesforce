@isTest
public class Test_scheduleUpdateLastRevenueGenerated {
    @isTest static void testScheduleUpdate() {
        Test.startTest();
        scheduleUpdateLastRevenueGenerated sct = new scheduleUpdateLastRevenueGenerated();
        string cronExp = '0 0 3 1/1 * ? *'; //run every day at 3.00 AM
        system.schedule('Test Update Last Revenue Made', cronExp, sct);
        Test.stopTest();
    }
}