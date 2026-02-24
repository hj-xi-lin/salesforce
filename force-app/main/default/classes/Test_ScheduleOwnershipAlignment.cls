@isTest
public class Test_ScheduleOwnershipAlignment {
    @isTest 
    static void testScheduleOwnershipAlignment() {
        Test.startTest();
        ScheduleOwnershipAlignment sct = new ScheduleOwnershipAlignment();
        string cronExp = '0 0 3 1/1 * ? *'; //run every day at 3.00 AM
        system.schedule('Test Schedule Ownership Alignment', cronExp, sct);
        Test.stopTest();
    }
}