@isTest
public class Test_scheduleCategoryAndClientOnAccount {
    @isTest static void testScheduleUpdate() {
        Test.startTest();
        scheduleCategoryAndClientOnAccount sct = new scheduleCategoryAndClientOnAccount();
        string cronExp = '0 0 3 1/1 * ? *'; //run every day at 3.00 AM
        system.schedule('Test HeyJobs Category and Reference client on Account', cronExp, sct);
        Test.stopTest();
    }

}