@isTest
public class Test_scheduleAccountHappinessChanges {
    @isTest static void testScheduleUpdate() {
        Test.startTest();
        scheduleAccountHappinessChanges sct = new scheduleAccountHappinessChanges();
        string cronExp = '0 0 3 1/1 * ? *'; //run every day at 3.00 AM
        system.schedule('Test Account Happiness Updates', cronExp, sct);
        Test.stopTest();
    }

}