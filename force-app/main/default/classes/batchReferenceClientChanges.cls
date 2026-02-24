/*
 *      @author Arun Kumar
 *      @date   29-Aug-2023
 *      @description   Batch class to retrieve and send accounts for populating the updated X2020_Reference_Clients__c
 *
 *      Modification Log:
 *      ------------------------------------------------------------------------------------
 *      Developer                       Date                Description
 *      ------------------------------------------------------------------------------------
 *      
 * 
 */
global class batchReferenceClientChanges implements Database.Batchable<sObject> {

    global Database.QueryLocator start(Database.BatchableContext bc){
        String query = 'SELECT Id, Updated__c, Category__c, Old_Reference_Clients__c, Reference_Clients__c FROM Category3__c WHERE Updated__c = TRUE';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<Category3__c> categoryList){
        if(!categoryList.isEmpty()){
            UtilityFunctions.processReferenceClientChanges(categoryList);
        }
    }

    global void finish(Database.BatchableContext bc) {
    }
}