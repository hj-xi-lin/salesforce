@isTest
public class test_ScheduleAutoCloseOpps {
    @isTest 
    static void testScheduleAutoCloseOpps() {
        Test.startTest();
        ScheduleAutoCloseOpps sct = new ScheduleAutoCloseOpps();
        string cronExp = '0 0 3 1/1 * ? *'; //run every day at 3.00 AM
        system.schedule('Test Schedule Auto Close Opps', cronExp, sct);
        Test.stopTest();
    }
}