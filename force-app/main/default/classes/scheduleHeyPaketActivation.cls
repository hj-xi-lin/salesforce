/*
 *      @author Arun Kumar
 *      @date   21-Apr-2023
 *      @description   Schedule Class to trigger bulk activation of HeyPakets
 *
 *      Modification Log:
 *      ------------------------------------------------------------------------------------
 *      Developer                       Date                Description
 *      ------------------------------------------------------------------------------------
 *      
 * 
 */
global class scheduleHeyPaketActivation implements Schedulable {
    global void execute(SchedulableContext SC) {
       batchHeyPaketActivation batch = new batchHeyPaketActivation();
       Database.executeBatch(batch);
    }
}