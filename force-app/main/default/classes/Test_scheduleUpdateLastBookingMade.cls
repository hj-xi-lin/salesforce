@isTest
public class Test_scheduleUpdateLastBookingMade {
    @isTest static void testScheduleUpdate() {
        Test.startTest();
        scheduleUpdateLastBookingMade sct = new scheduleUpdateLastBookingMade();
        string cronExp = '0 0 3 1/1 * ? *'; //run every day at 3.00 AM
        system.schedule('Test Update Last Booking Made', cronExp, sct);
        Test.stopTest();
    }
}