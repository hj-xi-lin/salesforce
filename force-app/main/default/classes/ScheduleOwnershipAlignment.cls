/*
*      @author Lisa Müller
*      @date   02-Jan-2024
*      @description   Schedulable apex for ownership alignment updates RO-1623
*
*      Modification Log:
*      ------------------------------------------------------------------------------------
*      Developer                       Date                Description
*      ------------------------------------------------------------------------------------
* 
* 
*/

public class ScheduleOwnershipAlignment implements Schedulable{
    public void execute(SchedulableContext SC){
        
        AlignContactOwnership contactBatch = new AlignContactOwnership();
        Database.executeBatch(contactBatch);
        
        AlignOppOwnership oppBatch = new AlignOppOwnership();
        Database.executeBatch(oppBatch);
        
    }

}