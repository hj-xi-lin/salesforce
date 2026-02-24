/*
*      @author - Varun Subhash
*      @date - 16-Apr-2024
*      @description - Schedulable apex for transfer of Inactive accounts RO-2027
*
*      Modification Log:
*      ------------------------------------------------------------------------------------
*      Developer                       Date                Description
*      ------------------------------------------------------------------------------------
* 
* 
*/


public class ScheduleTransferInactiveOwnersBatch implements Schedulable {
    public void execute(SchedulableContext SC) {
        // Instantiate and execute the batch job when this method is invoked by the scheduler
        TransferInactiveOwnersBatch batch = new TransferInactiveOwnersBatch();
        Database.executeBatch(batch);
    }
}