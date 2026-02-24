/*
 *      @author Arun Kumar
 *      @date   29-Aug-2023
 *      @description   Batch class to retrieve and send accounts for populating HeyJobs_Category__c and X2020_Reference_Clients__c
 *
 *      Modification Log:
 *      ------------------------------------------------------------------------------------
 *      Developer                       Date                Description
 *      ------------------------------------------------------------------------------------
 *      
 * 
 */
global class batchCategoryAndClientOnAccount implements Database.Batchable<sObject> {

    global Database.QueryLocator start(Database.BatchableContext bc){
        String query = 'SELECT Id, Category_3__c, HeyJobs_Category__c, X2020_Reference_Clients__c FROM Account WHERE Category_3__c <> NULL AND X2020_Reference_Clients__c = NULL';
        String filter = ' AND (CreatedDate = YESTERDAY OR LastModifiedDate = YESTERDAY)';
        if(Test.isrunningtest()){
            return Database.getQueryLocator(query);
        }else{
            query = query + filter;
            return Database.getQueryLocator(query);
        }
        
    }

    global void execute(Database.BatchableContext bc, List<Account> accList){
        if(!accList.isEmpty()){
            UtilityFunctions.processCategoryAndClientOnAccount(accList);
        }
    }

    global void finish(Database.BatchableContext bc) {
    }
}