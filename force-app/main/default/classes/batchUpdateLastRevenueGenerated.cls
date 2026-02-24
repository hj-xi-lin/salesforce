/*
*      @author Arun Kumar
*      @date   15-Dec-2024
*      @description  
*
*      Modification Log:
*      ------------------------------------------------------------------------------------
*      Developer                       Date                Description
*      ------------------------------------------------------------------------------------
*      
* 
*/
global class batchUpdateLastRevenueGenerated implements Database.Batchable<sObject>, Database.AllowsCallouts {
    global Database.QueryLocator start(Database.BatchableContext bc){
        String query = 'SELECT Id, Last_Revenue_Generated__c, Ultimate_Account_ID__c FROM Account WHERE Last_Revenue_Generated__c <> NULL';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List<Account> accountList){
        if(!accountList.isEmpty()){
            Set<Id> ultimateAccountIdSet = new Set<Id>();
            Map<Id, Account> accountToUpdateMap = new Map<Id, Account>();
            Map<Id, Account> ultimateAccountMap;
            List<Account> accountToUpdateList = new List<Account>();
            
            for(Account acc : accountList){
                ultimateAccountIdSet.add(acc.Ultimate_Account_ID__c);
            }
            
            if(!ultimateAccountIdSet.isEmpty()){
                ultimateAccountMap = new Map<Id, Account>([SELECT Id, Last_Revenue_Generated_Date_Hierarchy__c FROM Account WHERE Id IN :ultimateAccountIdSet]);
            }
            
            if(!ultimateAccountMap.isEmpty()){
                for(Account acc : accountList){
                    if(ultimateAccountMap.containsKey(acc.Ultimate_Account_ID__c)){
                        if((ultimateAccountMap.get(acc.Ultimate_Account_ID__c).Last_Revenue_Generated_Date_Hierarchy__c == NULL)
                           || (ultimateAccountMap.get(acc.Ultimate_Account_ID__c).Last_Revenue_Generated_Date_Hierarchy__c != NULL 
                               && ultimateAccountMap.get(acc.Ultimate_Account_ID__c).Last_Revenue_Generated_Date_Hierarchy__c < acc.Last_Revenue_Generated__c)
                           || (accountToUpdateMap.containsKey(acc.Ultimate_Account_ID__c) &&
                               accountToUpdateMap.get(acc.Ultimate_Account_ID__c).Last_Revenue_Generated_Date_Hierarchy__c < acc.Last_Revenue_Generated__c)
                          ){
                              ultimateAccountMap.get(acc.Ultimate_Account_ID__c).Last_Revenue_Generated_Date_Hierarchy__c = acc.Last_Revenue_Generated__c;
                              accountToUpdateMap.put(acc.Ultimate_Account_ID__c, ultimateAccountMap.get(acc.Ultimate_Account_ID__c));
                          }
                    }
                }
            }
            
            if(!accountToUpdateMap.isEmpty()){
                try{
                    update accountToUpdateMap.values();
                }catch(Exception e){
                    //Add logic for catching exception
                }
            }
        }
    }
    
    global void finish(Database.BatchableContext bc) {
    }
}