@isTest
public class Test_scheduleRevertCampaignExclusion {
	@isTest static void testScheduleUpdate() {
        Test.startTest();
        scheduleRevertCampaignExclusion sct = new scheduleRevertCampaignExclusion();
        string cronExp = '0 0 3 1/1 * ? *'; //run every day at 3.00 AM
        system.schedule('Test HeyPaket Activation Batch', cronExp, sct);
        Test.stopTest();
    }
}