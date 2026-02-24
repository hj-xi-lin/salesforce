@isTest
public class Test_scheduleUpdateStageACM {
    @isTest static void testScheduleUpdate() {
        Test.startTest();
        scheduleUpdateStageACM sct = new scheduleUpdateStageACM();
        string cronExp = '0 0 3 1/1 * ? *'; //run every day at 3.00 AM
        system.schedule('Test Account Stage ACM Batch', cronExp, sct);
        Test.stopTest();
    }

}