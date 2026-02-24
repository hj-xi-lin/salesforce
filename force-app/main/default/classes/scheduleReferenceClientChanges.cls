/*
 *      @author Arun Kumar
 *      @date   29-Aug-2023
 *      @description   Apex class to schedule the update of reference client changes
 *
 *      Modification Log:
 *      ------------------------------------------------------------------------------------
 *      Developer                       Date                Description
 *      ------------------------------------------------------------------------------------
 *      
 * 
 */
global class scheduleReferenceClientChanges implements Schedulable  {
    global void execute(SchedulableContext sc) {
       batchReferenceClientChanges batch = new batchReferenceClientChanges();
       Database.executeBatch(batch);
    }
}