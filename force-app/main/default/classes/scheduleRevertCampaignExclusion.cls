/*
 *      @author Arun Kumar
 *      @date   28-Mar-2025
 *      @description   Schedule Class to initiate the batch for marking the contacts eligible for Outreach Campaigns after 6 weeks of original exclusion
 *
 *      Modification Log:
 *      ------------------------------------------------------------------------------------
 *      Developer                       Date                Description
 *      ------------------------------------------------------------------------------------
 *      
 * 
 */
global class scheduleRevertCampaignExclusion implements Schedulable  {
    global void execute(SchedulableContext sc) {
       batchRevertCampaignExclusion batch = new batchRevertCampaignExclusion();
       Database.executeBatch(batch);
    }
}