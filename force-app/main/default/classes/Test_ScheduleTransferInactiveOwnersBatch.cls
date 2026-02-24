@isTest
public class Test_ScheduleTransferInactiveOwnersBatch {
    @isTest 
    static void testScheduleTransferInactiveOwnersBatch() {
        Test.startTest();
        ScheduleTransferInactiveOwnersBatch sct = new ScheduleTransferInactiveOwnersBatch();
        string cronExp = '0 0 5 1/1 * ? *'; 
        system.schedule('Test Schedule Transfer InactiveOwnersBatch', cronExp, sct);
        Test.stopTest();
    }
}