/*
*      @author Arun Kumar
*      @date   09-Jun-2025
*      @description  
*
*      Modification Log:
*      ------------------------------------------------------------------------------------
*      Developer                       Date                Description
*      ------------------------------------------------------------------------------------
*      
* 
*/

public class scheduleOldJobCleanup implements Schedulable {
    public void execute(SchedulableContext context) {
        Database.executeBatch(new batchOldJobCleanup());
    }
}