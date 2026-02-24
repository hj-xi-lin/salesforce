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
global class batchUpdateLastBookingMade implements Database.Batchable<sObject>, Database.AllowsCallouts {
    global Database.QueryLocator start(Database.BatchableContext bc){
        String query = 'SELECT Id, Amount, Timestamp_Closed_Won__c, AccountId, Account.Ultimate_Account_ID__c FROM Opportunity WHERE StageName = \'Closed Won\' AND Timestamp_Closed_Won__c = YESTERDAY AND Amount <> NULL AND Amount > 0';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List<Opportunity> oppList){
        if(!oppList.isEmpty()){
            List<Account> accountList = new List<Account>();
            Map<Id, Account> ultimateParentMap;
            Map<Id, Account> accountToUpdate = new Map<Id, Account>();
            Set<Id> ultimateAccountIdSet = new Set<Id>();
            
            for(Opportunity opp : oppList){
                ultimateAccountIdSet.add(opp.Account.Ultimate_Account_ID__c);
            }
            
            if(!ultimateAccountIdSet.isEmpty()){
                ultimateParentMap = new Map<Id, Account>([SELECT Id, Last_Booking_Generated_Date_Hierarchy__c
                                                          FROM Account
                                                          WHERE Id IN :ultimateAccountIdSet]);
            }
            
            if(!ultimateParentMap.isEmpty()){
                for(Opportunity opp : oppList){
                    if(ultimateParentMap.containsKey(opp.Account.Ultimate_Account_ID__c)){
                        if((ultimateParentMap.get(opp.Account.Ultimate_Account_ID__c).Last_Booking_Generated_Date_Hierarchy__c == NULL)
                           || (ultimateParentMap.get(opp.Account.Ultimate_Account_ID__c).Last_Booking_Generated_Date_Hierarchy__c != NULL 
                               && ultimateParentMap.get(opp.Account.Ultimate_Account_ID__c).Last_Booking_Generated_Date_Hierarchy__c < opp.Timestamp_Closed_Won__c)
                           || (accountToUpdate.containsKey(opp.Account.Ultimate_Account_ID__c) 
                               && accountToUpdate.get(opp.Account.Ultimate_Account_ID__c).Last_Booking_Generated_Date_Hierarchy__c < opp.Timestamp_Closed_Won__c)
                          ){
                              ultimateParentMap.get(opp.Account.Ultimate_Account_ID__c).Last_Booking_Generated_Date_Hierarchy__c = opp.Timestamp_Closed_Won__c;
                              accountToUpdate.put(opp.Account.Ultimate_Account_ID__c,ultimateParentMap.get(opp.Account.Ultimate_Account_ID__c)); 
                          }
                    }
                }
            }
           
            if(!accountToUpdate.isEmpty()){
                try{
                    update accountToUpdate.values();
                }catch(Exception e){
                    //Add error logging mechanism
                }
            }
        }
    }
    
    global void finish(Database.BatchableContext bc) {
    }
}