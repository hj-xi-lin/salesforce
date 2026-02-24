@isTest
public class Test_scheduleLocalDemoHeldUpdate {
  @isTest static void testScheduleUpdate() {
        Test.startTest();
        scheduleLocalDemoHeldUpdate sct = new scheduleLocalDemoHeldUpdate();
        string cronExp = '0 0 3 1/1 * ? *'; //run every day at 3.00 AM
        system.schedule('Test Local Demo Held Update Batch', cronExp, sct);
        Test.stopTest();
    }
}