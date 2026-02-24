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
global class scheduleUpdateLastRevenueGenerated implements Schedulable  {
    global void execute(SchedulableContext sc) {
       batchUpdateLastRevenueGenerated batch = new batchUpdateLastRevenueGenerated();
       Database.executeBatch(batch);
    }
}