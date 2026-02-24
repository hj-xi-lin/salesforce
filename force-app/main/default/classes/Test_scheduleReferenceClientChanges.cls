@isTest
public class Test_scheduleReferenceClientChanges {
    @isTest static void testScheduleUpdate() {
        Test.startTest();
        scheduleReferenceClientChanges sct = new scheduleReferenceClientChanges();
        string cronExp = '0 0 3 1/1 * ? *'; //run every day at 3.00 AM
        system.schedule('Test Reference client changes on Account', cronExp, sct);
        Test.stopTest();
    }

}