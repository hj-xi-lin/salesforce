/*
*      @author Arun Kumar
*      @date   17-Dec-2024
*      @description  
*
*      Modification Log:
*      ------------------------------------------------------------------------------------
*      Developer                       Date                Description
*      ------------------------------------------------------------------------------------
*      
* 
*/
global class scheduleUpdateLastBookingMade implements Schedulable  {
    global void execute(SchedulableContext sc) {
       batchUpdateLastBookingMade batch = new batchUpdateLastBookingMade();
       Database.executeBatch(batch);
    }
}