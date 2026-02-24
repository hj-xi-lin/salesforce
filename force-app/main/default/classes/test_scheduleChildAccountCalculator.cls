@isTest
public class test_scheduleChildAccountCalculator {
    @isTest 
    static void testScheduleChildAccountCalculator() {
        Test.startTest();
        scheduleChildAccountCalculator sct = new scheduleChildAccountCalculator();
        string cronExp = '0 0 3 1/1 * ? *'; //run every day at 3.00 AM
        system.schedule('Test Schedule Child Account Calculator', cronExp, sct);
        Test.stopTest();
    }
}