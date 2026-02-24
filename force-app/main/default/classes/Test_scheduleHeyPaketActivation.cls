@isTest
public class Test_scheduleHeyPaketActivation {
	@isTest static void testScheduleUpdate() {
        Test.startTest();
        scheduleHeyPaketActivation sct = new scheduleHeyPaketActivation();
        string cronExp = '0 0 3 1/1 * ? *'; //run every day at 3.00 AM
        system.schedule('Test HeyPaket Activation Batch', cronExp, sct);
        Test.stopTest();
    }
}