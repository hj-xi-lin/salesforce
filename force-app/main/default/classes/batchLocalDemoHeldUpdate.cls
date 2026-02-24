/*
 *      @author Lisa Müller
 *      @date   25-Jul-2023
 *      @description   RO-1620 Batch Class to perform bulk update of Demo Held Timestamp of lost Local opps 
 *
 *      Modification Log:
 *      ------------------------------------------------------------------------------------
 *      Developer                       Date                Description
 *      ------------------------------------------------------------------------------------
 *      Lisa Müller					11.09.2023				Add Timestamp fields to query
 * 
 * 
 */
global class batchLocalDemoHeldUpdate implements Database.Batchable<sObject>, Database.AllowsCallouts {
    global Database.QueryLocator start(Database.BatchableContext bc){
        Id salesRecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Opportunity' AND DeveloperName = 'Sales' LIMIT 1].Id;
        String query = 'SELECT Id, AccountId, OwnerId, CreatedDate, Demo_Date__c, Hunter__c, Timestamp_Demo_Held__c, Timestamp_Demo_Held_Time__c, Timestamp_Not_reached_yet__c, Timestamp_Not_reached_yet_time__c, Timestamp_Qualified_Prospect__c, Timestamp_Qualified_Prospect_Time__c, Timestamp_Currently_in_Contact__c, Timestamp_Currently_in_Contact_Time__c, Timestamp_Demo_Scheduled__c, Timestamp_Demo_confirmed__c FROM Opportunity WHERE RecordTypeId = \'' + salesRecordTypeId + '\' AND StageName = \'Closed Lost\' AND Segment_Opp_V02__c = \'Small\'  AND dateTimestampClosedWonLost__c = TODAY AND Timestamp_Demo_Held__c =NULL ';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List<Opportunity> oppList){
        if(!oppList.isEmpty() && !Test.isRunningTest()){
            LocalDemoHeldUpdate.UpdateDemoFields(oppList);
        }
    }

    global void finish(Database.BatchableContext bc) {
    }
}