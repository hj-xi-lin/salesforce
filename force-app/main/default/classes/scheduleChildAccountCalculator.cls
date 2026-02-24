/*
*      @author Lisa Müller
*      @date   16-Jul-2024
*      @description   Schedulable apex to automatically recalculate the number of child accounts RO-2157
*
*      Modification Log:
*      ------------------------------------------------------------------------------------
*      Developer                       Date                Description
*      ------------------------------------------------------------------------------------
* 
* 
*/

public class scheduleChildAccountCalculator implements Schedulable{
    public void execute(SchedulableContext SC){
        
        batchChildAccountCalculator.calculateChildAccounts();
        
    }

}