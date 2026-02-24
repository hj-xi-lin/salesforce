/*
 *      @author Arun Kumar
 *      @date   11-Mar-2022
 *      @description   Class to handle the business logic on Account Trigger
 *
 *      Modification Log:
 *      ------------------------------------------------------------------------------------
 *      Developer                       Date                Description
        Varun Subhash                   20.02.2024          RO - 1973 
        Lisa Müller                     20.02.2025          Removed createContacts method to enable field deletion
        Varun Subhash                   26.01.2026          Removed legacy account fields.
 *      ------------------------------------------------------------------------------------
 *      
 * 
 */

public with sharing class AccountTriggerFunction {

    /**
    @Methodname     : updateSegmentation
    @Param          : List<Account>
    @Return         : Null
    @Description    : To update the Segment_v02__c field based on the numberofEmployees
    **/
    public static void updateSegmentation(List<Account> newAccountList){
    }

    /**
    @Methodname     : heyJobsCategoryOnUpdate
    @Param          : Trigger.newList, Trigger.oldMap
    @Return         : Null
    @Description    : Marks the boolean as true, if the HeyJobs category is blank
    **/
    public static void heyJobsCategoryOnUpdate(List<Account> newAccountList, List<Account> oldAccountList){
    }
    
    /**
    @Methodname     : heyJobsCategoryOnInsert
    @Param          : Trigger.newList
    @Return         : Null
    @Description    : Marks the boolean as true, if the HeyJobs category is blank
    **/
    public static void heyJobsCategoryOnInsert(List<Account> newAccountList){
    }
    
    /**
    @Methodname     : validateUmbrellaCompany
    @Param          : List<account>
    @Return         : Null
    @Description    : Prevents inserting or updating an account to umbrella account if it has opportunities associated with it
    **/
    public static void validateUmbrellaCompany(List<account> accList) {
    
        Set<string> accIds = new Set<string>();
        Map<string,list<opportunity>> accIdVsOpp = new map<string,list<opportunity>>();
        
        for(Account acc : accList) {
            if(acc.Umbrella_Company__c) {
                accIds.add(acc.id);
            }
        }
       
        if(!accIds.isEmpty()) {
            for(opportunity opp : [SELECT Id, AccountId FROM opportunity WHERE accountid IN :accIds]){
                if(!accIdVsOpp.containskey(opp.accountid)){
                    accIdVsOpp.put(opp.accountid, new list<opportunity>());
                    accIdVsOpp.get(opp.accountid).add(opp);
                }    
            }
            
            if(!accIdVsOpp.isEmpty()) {
                for(Account ac : accList) {
                    if(accIdVsOpp.containskey(ac.id) && accIdVsOpp.get(ac.id).size() > 0){
                        ac.addError('You can not check Umbrella Company. This Account has related Opportunities attached.');
                    }
                }
            }
        }
    } 
}