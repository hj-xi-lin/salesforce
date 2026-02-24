@isTest
public class Test_ScheduleCreateAutomatedTasks {
    @isTest static void test1() {
        Test.startTest();
        ScheduleCreateAutomatedTasks sct = new ScheduleCreateAutomatedTasks();
        string cronExp = '0 0 0 1 1/3 ? *';
        system.schedule('Test Automated Tasks', cronExp, sct);
        Test.stopTest();
    }
}