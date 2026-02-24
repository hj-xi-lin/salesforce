@isTest
public class Test_ScheduleUpdateCategoryOnAccount {
    @isTest static void test1() {
        Test.startTest();
        ScheduleUpdateCategoryOnAccountBatch sct = new ScheduleUpdateCategoryOnAccountBatch();
        string cronExp = '0 0 3 1/1 * ? *'; //run every day at 3.00 AM
        system.schedule('Test Account Update Batch', cronExp, sct);
        Test.stopTest();
    }
}