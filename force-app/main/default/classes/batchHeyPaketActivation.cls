/*
 *      @author Arun Kumar
 *      @date   21-Apr-2023
 *      @description   Batch Class to perform bulk activation of HeyPakets
 *
 *      Modification Log:
 *      ------------------------------------------------------------------------------------
 *      Developer                       Date                Description
 *      ------------------------------------------------------------------------------------
 *      
 * 
 */
global class batchHeyPaketActivation implements Database.Batchable<sObject>, Database.AllowsCallouts {
    global Database.QueryLocator start(Database.BatchableContext bc){
        String query = 'SELECT Id, Name, AccountId, HeyPaket_Type__c, HeyPaket_Status__c, HeyPaket_Start_Date__c, HeyPaket_Start_Date_reached__c FROM Opportunity WHERE HeyPaket_Status__c = \'Scheduled\' AND HeyPaket_Start_Date__c = TODAY';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<Opportunity> oppList){
        if(!oppList.isEmpty() && !Test.isRunningTest()){
            HeyPaketUtility.heypaketActivation(oppList);
        }
    }

    global void finish(Database.BatchableContext bc) {
    }
}