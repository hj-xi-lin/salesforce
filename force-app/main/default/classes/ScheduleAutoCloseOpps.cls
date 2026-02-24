/*
*      @author Lisa Müller
*      @date   16-Apr-2024
*      @description   Schedulable apex to automatically close open opps RO-2036
*
*      Modification Log:
*      ------------------------------------------------------------------------------------
*      Developer                       Date                Description
*      ------------------------------------------------------------------------------------
* 
* 
*/

public class ScheduleAutoCloseOpps implements Schedulable{
    public void execute(SchedulableContext SC){
        
        batchAutoCloseOpps oppBatch = new batchAutoCloseOpps();
        Database.executeBatch(oppBatch);
        
    }

}