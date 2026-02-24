/*
 *      @author Arun Kumar
 *      @date   12-Jun-2023
 *      @description   Business logic based on contact trigger
 *
 *      Modification Log:
 *      ------------------------------------------------------------------------------------
 *      Developer                       Date                Description
 *      ------------------------------------------------------------------------------------
 * 
 */
public with sharing class ContactTriggerFunctions {
    
    public static Map<Id, Account> accountMap;
    public static Map<Id, Contact> contactMap;
    
    public static void callingBackendForAccess (List<Contact> newContactList, Map<Id, Contact> oldContactMap){
        List<Id> contactIdList = new List<Id>();
        List<Id> accountIdList = new List<Id>();
        
        for(Contact con : newContactList){
            if(oldContactMap.get(con.Id).Backend_access_enabled__c != con.Backend_access_enabled__c && con.Backend_access_enabled__c == true && con.Timestamp_SSSU__c != NULL){
                contactIdList.add(con.Id);
                accountIdList.add(con.AccountId);
            }
        }
        
        //if(!contactIdList.isEmpty() && !accountIdList.isEmpty()){
        if(contactIdList != NULL && accountIdList != NULL){
        	createBEAccess(contactIdList,accountIdList,'a2L9L00000008k8UAA');
        }
    }
    
    @future (callout = true)
    public static void createBEAccess( List<Id> contactIdList, List<Id> accountIdList, String channelID){
        Map<String, Object> flowInputs = new Map<String, Object>();
        
        if(!contactIdList.isEmpty()){
            contactMap = new Map<Id, Contact>([SELECT Id, Name, AccountId, Email, FirstName, LastName, Blacklist__c
                       		FROM Contact 
                          	WHERE Id =:contactIdList]);
        }
        
        if(!accountIdList.isEmpty()){
            accountMap = new Map<Id, Account>([SELECT Id, Name, Blacklist__c, txtCompanyId__c, RecordTypeId, RecordType.Name, RecordType.DeveloperName, Service_Country__c, CurrencyIsoCode, Description_c__c 
                       		FROM Account 
                          	WHERE Id =:accountIdList]);
        }
        
        if((contactMap != NULL && !contactMap.isEmpty()) && (accountMap != NULL && !accountMap.isEmpty())){
            for(Contact con : contactMap.values()){
                flowInputs.put('varAccount', accountMap.get(con.AccountID));
                flowInputs.put('varContact', contactMap.get(con.Id));
                flowInputs.put('varSlackErrorChannel_ID',channelID);
                Flow.Interview.Automatic_BE_Company_User_Creation backendUserCreation = new Flow.Interview.Automatic_BE_Company_User_Creation(flowInputs);
                backendUserCreation.start();
            }
        }
    }
}