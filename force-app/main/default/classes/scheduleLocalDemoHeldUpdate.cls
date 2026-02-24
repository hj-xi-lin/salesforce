/*
 *      @author Lisa Müller
 *      @date   28-Jul-2023
 *      @description   RO-1620 Schedule Class to trigger bulk class of Local Demo Held Timestamp Updates 
 *
 *      Modification Log:
 *      ------------------------------------------------------------------------------------
 *      Developer                       Date                Description
 *      ------------------------------------------------------------------------------------
 *      
 * 
 */


global class scheduleLocalDemoHeldUpdate implements Schedulable {
    global void execute(SchedulableContext SC) {
       batchLocalDemoHeldUpdate batch = new batchLocalDemoHeldUpdate();
       Database.executeBatch(batch);
    }
}