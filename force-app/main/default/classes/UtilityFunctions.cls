/*
*      @author Arun Kumar
*      @date   03-Aug-2022
*      @description   Utility Class to store reusable business logics
*
*      Modification Log:
*      ------------------------------------------------------------------------------------
*      Developer        Date            Description
*      ------------------------------------------------------------------------------------
*       Arun Kumar      29.08.2023      Created processCategoryAndClientOnAccount() for RO-1525
*       Arun Kumar      29.08.2023      Created processReferenceClientChanges() for RO-1525
*       Arun Kumar      29.08.2023      Created processAccountHappinessChanges() for RO-1570
*       Arun Kumar      15.04.2024      Created getRecruiterFirstAndLastName() for RO-1952
*/

public with sharing class UtilityFunctions {
    
    /**
@Methodname     : updateStageACMOnReactivation
@Param          : List<Opportunity>
@Return         : List<Account>
@Description    : To update the Stage_ACM__c field on Account based on the Timestamp_Reactivation__c on opportunity
**/
    public static List<Account> updateStageACMOnReactivation(List<Opportunity> oppList){
        
        //Fetch the Closed Lost opportunities
        Set<Id> accountIdSet = new Set<Id>();
        List<Account> accountList = new List<Account>();
        
        if(!oppList.isEmpty()){
            for(Opportunity opp : oppList){
                accountIdSet.add(opp.AccountId);
            }
        }
        
        //Approach 1
        if(!accountIdSet.isEmpty()){
            for(Account acc: [SELECT Id, Stage_ACM__c FROM Account WHERE Id =: accountIdSet]){
                acc.Stage_ACM__c = 'Prospect';
                accountList.add(acc);
            }
        }
        
        return accountList;
    }
    
    
    /**
@Methodname     : processCategoryAndClientOnAccount
@Param          : List<Account>
@Return         : List<Account>
@Description    : To update the HeyJobs_Category__c and X2020_Reference_Clients__c field on Account based on the Category_3__c
**/
    public static void processCategoryAndClientOnAccount(List<Account> accountList){
        
        Set<String> categorySet = new Set<String>();
        List<Account> categorisedAccList = new List<Account>();
        List<Category3__c> categoryList = new List<Category3__c>();
        
        for(Account acc : accountList){
            categorySet.add(acc.Category_3__c);
        }
        
        if(!categorySet.isEmpty()){
            categoryList = [SELECT Category__c, Reference_Clients__c, HeyJobs_Category__c  FROM Category3__c WHERE Category__c IN :categorySet];
        }
        
        if(!categoryList.isEmpty()){
            for(Account acc : accountList){
                for(Category3__c ct : categoryList){
                    if(ct.Category__c == acc.Category_3__c){
                        acc.X2020_Reference_Clients__c = ct.Category__c;
                        acc.HeyJobs_Category__c = ct.HeyJobs_Category__c;
                        categorisedAccList.add(acc);
                    }
                }  
            }
        }
        
        if(!categorisedAccList.isEmpty()){
            try{
                update categorisedAccList;
            }catch(Exception e){
                System.debug('Error while updating Heyjobs category and reference clients on account');
            }
        }
    }
    
    /**
@Methodname     : processReferenceClientChanges
@Param          : List<Category3__c>
@Return         : List<Account>
@Description    : To update the X2020_Reference_Clients__c field on Account based on the latest changes in the Reference client values
**/
    public static void processReferenceClientChanges (List<Category3__c> changedCategoryList){
        
        Set<String> accCategorySet = new Set<String>();
        List<Account> accList = new List<Account>();
        Map<String, String> categoryVsNewReferenceMap = new Map<String, String>();
        
        for(Category3__c ctry : changedCategoryList){
            accCategorySet.add(ctry.Category__c);
            categoryVsNewReferenceMap.put(ctry.Category__c, ctry.Reference_Clients__c);
        }
        
        if(!accCategorySet.isEmpty()){
            for(Account acc : [SELECT Id, Category_3__c, HeyJobs_Category__c, X2020_Reference_Clients__c FROM Account WHERE Category_3__c IN :accCategorySet]){
                if(acc.Category_3__c != NULL && !categoryVsNewReferenceMap.isEmpty() && categoryVsNewReferenceMap.containsKey(acc.Category_3__c)){
                    acc.X2020_Reference_Clients__c = categoryVsNewReferenceMap.get(acc.Category_3__c);
                    accList.add(acc);
                }
            }
        }
        
        if(!accList.isEmpty()){
            try{
                update accList;
            }catch(Exception e){
                System.debug('Error while updating reference clients');
            }
        }
    }
    
    
    
     /**
@Methodname     : getRecruiterFirstAndLastName
@Param          : List<RecruiterDetailsInput>
@Return         : List<RecruiterDetailsOutput>
@Description    : Based on the input from the flow, this method splits the recruiter name to FirstName and LastName
**/

    @InvocableMethod(Label = 'Get Recruiter First and Last Name')
    public static List<RecruiterDetailsOutput> getRecruiterFirstAndLastName(List<RecruiterDetailsInput> recruiterInputList){
        List<RecruiterDetailsOutput> firstAndLastNameList = new List<RecruiterDetailsOutput>();
        
        for (RecruiterDetailsInput input : recruiterInputList) {
            if (String.isNotBlank(input.recruiterName)) {
                String[] nameParts = input.recruiterName.trim().split('\\s+');
                RecruiterDetailsOutput output = new RecruiterDetailsOutput();
                if(nameParts.size() > 1) {
                    output.recruiterFirstName = nameParts[0];
                    output.recruiterLastName = '';
                    for (Integer i = 1; i < nameParts.size(); i++) {
                        output.recruiterLastName += (String.isEmpty(output.recruiterLastName) ? '' : ' ') + nameParts[i];
                    }
                }else if(nameParts.size() == 1){
                    output.recruiterFirstName = '';
                    output.recruiterLastName = nameParts[0];
                }
                firstAndLastNameList.add(output);
            } else {
                continue;
            }
        }
        return firstAndLastNameList;
    }
    
    public class RecruiterDetailsInput {
        @InvocableVariable
        public String recruiterName;
    }
    
    public class RecruiterDetailsOutput {
        @InvocableVariable
        public String recruiterFirstName;
        @InvocableVariable
        public String recruiterLastName;
    }
}