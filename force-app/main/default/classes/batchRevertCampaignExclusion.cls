/*
 *      @author Arun Kumar
 *      @date   28-Mar-2025
 *      @description   Batch Class to make the contacts eligible for Outreach Campaigns after 6 weeks of original exclusion
 *
 *      Modification Log:
 *      ------------------------------------------------------------------------------------
 *      Developer                       Date                Description
 *      ------------------------------------------------------------------------------------
 *      
 * 
 */
global class batchRevertCampaignExclusion implements Database.Batchable<sObject>, Database.AllowsCallouts {
    global Database.QueryLocator start(Database.BatchableContext bc){
        String query = 'SELECT Id, Name, Exclude_from_Outreach__c, Timestamp_Exclude_from_Outreach__c  FROM Contact WHERE Exclude_from_Outreach__c = True AND Timestamp_Exclude_from_Outreach__c  < LAST_N_DAYS:42 ORDER BY LastModifiedDate ASC';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<Contact> conList){
        if(!conList.isEmpty()){
            for(Contact con : conList){
                con.Exclude_from_Outreach__c = FALSE;
                con.Timestamp_Exclude_from_Outreach__c  = NULL;
            }
            
            try{
                update conList;
            }catch(Exception e){
                Logger.finest('Failed to revert the contacts as eligible for outreach: '+ conList+' '+'The error occurred: '+ e.getMessage());
                Logger.saveLog();
            }
        }
    }

    global void finish(Database.BatchableContext bc) {
    }
}