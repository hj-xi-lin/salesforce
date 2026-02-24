@IsTest
public class test_scheduleDeleteClosedTasks {
    
    @IsTest 
    static void testScheduleDeleteClosedTasks() {
        Test.startTest();
        scheduleDeleteClosedTasks sct = new scheduleDeleteClosedTasks();
        String cronExp = '0 0 2 1/1 * ? *'; // Run every day at 2:00 AM
        System.schedule('Test Schedule Delete Closed Tasks', cronExp, sct);
        Test.stopTest();
    }
}