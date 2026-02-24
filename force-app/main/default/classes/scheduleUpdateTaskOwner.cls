/*
 *      @author Arun Kumar
 *      @date   24-Mar-2023
 *      @description   Schedule class to trigger the update of task ownership
 *
 *      Modification Log:
 *      ------------------------------------------------------------------------------------
 *      Developer                       Date                Description
 *      ------------------------------------------------------------------------------------
 *      
 * 
 */

global class scheduleUpdateTaskOwner implements Schedulable  {
    global void execute(SchedulableContext sc) {
       batchUpdateTaskOwner batch = new batchUpdateTaskOwner();
       Database.executeBatch(batch);
    }
}