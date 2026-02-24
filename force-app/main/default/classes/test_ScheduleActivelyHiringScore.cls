@isTest
public class test_ScheduleActivelyHiringScore {
    @isTest 
    static void testScheduleActivelyHiringScore() {
        Test.startTest();
        ScheduleActivelyHiringScore sct = new ScheduleActivelyHiringScore();
        string cronExp = '0 0 3 1/1 * ? *'; //run every day at 3.00 AM
        system.schedule('Test Schedule Actively HiringScore', cronExp, sct);
        Test.stopTest();
    }
}