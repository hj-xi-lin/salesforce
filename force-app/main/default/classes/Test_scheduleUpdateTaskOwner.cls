@isTest
public class Test_scheduleUpdateTaskOwner {
    @isTest static void testScheduleUpdate() {
        Test.startTest();
        scheduleUpdateTaskOwner sct = new scheduleUpdateTaskOwner();
        string cronExp = '0 0 3 1/1 * ? *'; //run every day at 3.00 AM
        system.schedule('Test Task Owner update', cronExp, sct);
        Test.stopTest();
    }

}