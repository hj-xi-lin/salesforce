/*
*      @author Arun Kumar
*      @date   27-Jan-2023
*      @description   Logic to handle the conversion of SSSU leads
*
*      Modification Log:
*      ------------------------------------------------------------------------------------
*      Developer                       Date                Description
*      ------------------------------------------------------------------------------------
*      Arun Kumar            17.05.2023      Created method domainMatchChanges() for RO-1443
*      Arun Kumar            17.05.2023      Updated method convertLead() for RO-1443
*      Arun Kumar            19.05.2023      Created method sendConversionErrorToSlack() for RO-1443 
*      Arun Kumar            19.05.2023      Created method generateLeadConversionError() for RO-1443
*      Arun Kumar            08.06.2023      Updated method domainMatchChanges() for RO-1560
*      Arun Kumar            15.12.2023      Updated method convertLead() for RO-1672
* 
*/
public with sharing class selfserviceLeadConversion {
    
    /**
@Methodname     : convertLead
@Param          : List<Lead>, Map<Id, Lead>
@Return         : Null
@Description    : To convert the SSSU leads to new accounts and contacts based on conditions
**/
    public static void convertLead(List<Lead> leadList){
        
        List<Id> accountIdList                  = new List<Id>();
        List<Lead> sssuLeadsList                = new List<Lead>();
        List<Account> existingAccountList       = new List<Account>();
        List<Account> accountToUpdate           = new List<Account>();
        List<Database.LeadConvert> leadConverts = new List<Database.LeadConvert>();
        Map<Id, Id> accIdvsOwnerIdMap           = new Map<Id, Id>();
        Map<Id, Id> leadIdVsAccountIdMap        = new Map<Id, Id>();
        
        Id preSalesAdminID;
        Id accountSalesRT       = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Sales').getRecordTypeId();
        Id accountOutboundRT    = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Outbound').getRecordTypeId();
        Id accountResearchRT    = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Research').getRecordTypeId();
        leadIdVsAccountIdMap    = LeadTriggerFunctions.leadIdVsAccountIdMap;

        
        for(Lead inputLead : leadList){
            if(!inputLead.IsConverted && inputLead.Timestamp_SSSU_lead__c != NULL && inputLead.Timestamp_SSSU_HS_Workflow_completed__c != NULL){
                sssuLeadsList.add(inputLead);
            }
            
            if(inputLead.Existing_Account_Name__c != NULL){
                accountIdList.add(inputLead.Existing_Account_Name__c);
            }
        }
        
        if(!sssuLeadsList.isEmpty()){
            
            if(!accountIdList.isEmpty()){
                for(Account acc: [SELECT Id, OwnerId, RecordtypeId FROM Account WHERE Id IN :accountIdList]){
                    accIdvsOwnerIdMap.put(acc.Id, acc.OwnerId);
                    existingAccountList.add(acc);
                }
            }
            
            preSalesAdminID = sssuLeadsList[0].OwnerId;
            for(Lead sslead : sssuLeadsList){
                Database.LeadConvert lc = new Database.LeadConvert();
                lc.setLeadId(sslead.Id);
                lc.setDoNotCreateOpportunity(true);
                if(sslead.Existing_Account_Name__c != NULL){
                    lc.setAccountId(sslead.Existing_Account_Name__c);
                    lc.setOwnerId(accIdvsOwnerIdMap.get(sslead.Existing_Account_Name__c));
                }else if(!leadIdVsAccountIdMap.isEmpty() && leadIdVsAccountIdMap.containsKey(sslead.Id)){
                    lc.setAccountId(leadIdVsAccountIdMap.get(sslead.Id));
                }
                lc.setConvertedStatus('Converted');
                leadConverts.add(lc);
            }
            
            if(!leadConverts.isEmpty()){
                try{
                    List<Database.LeadConvertResult> lcr = Database.convertLead(leadConverts);
                    processLeadConversionOutput(lcr);
                }catch(Exception e){
                    //RO-1443
                    Logger.finest('Failed SSSU conversion: '+ leadConverts+' '+'The error occurred: '+ e.getMessage());
                    Logger.saveLog();
                    sendConversionErrorToSlack('SSSU_Errors',leadConverts[0].getLeadID(), e.getMessage());
                }
                
            }
            
            if(!existingAccountList.isEmpty()){
                for(Account acc : existingAccountList){
                    if(acc.OwnerId != accIdvsOwnerIdMap.get(acc.Id)){
                        acc.OwnerId = accIdvsOwnerIdMap.get(acc.Id);
                    }
                    
                    if(acc.RecordtypeId == accountOutboundRT || acc.RecordtypeId == accountResearchRT){
                        acc.RecordtypeId = accountSalesRT;
                        acc.OwnerId = preSalesAdminID;
                    }
                    accountToUpdate.add(acc);
                }
                
                if(!accountToUpdate.isEmpty()){
                    try{
                        update accountToUpdate;
                    }catch(Exception e){
                        Logger.finest('Failed Account Update of SSSU conversion: '+ accountToUpdate+' '+'The error occurred: '+ e.getMessage());
                        Logger.saveLog();
                    }
                }
            }
        }
    }
    
    /**
@Methodname     : domainMatchChanges
@Param          : List<Lead>, Map<Id, Lead>
@Return         : Null
@Description    : To call the autolaunched flow to trigger the lead conversion
**/
    /* public static void domainMatchChanges(List<Lead> leadList, Map<Id, Lead> oldLeadMap){

Map<String, Object> flowInputs = new Map<String, Object>();
Feature_Activation__mdt fa = Feature_Activation__mdt.getInstance('SSSU_Automatic_Lead_Converison');
Boolean isActive = (Boolean)fa.get('Is_Active__c');

if(isActive){
for(Lead ld : leadList){
if(/*oldLeadMap.get(ld.Id).Domain_Match_on_Lead__c != ld.Domain_Match_on_Lead__c && ld.Domain_Match_on_Lead__c == 0 && ld.Timestamp_SSSU_HS_Workflow_completed__c != NULL){
flowInputs.put('varLeadId', ld);
Flow.Interview.SSSU_Automatic_lead_conversion leadConversionFlow = new Flow.Interview.SSSU_Automatic_lead_conversion(flowInputs);
leadConversionFlow.start();
}
}
}
} 
*/
    
    /**
@Methodname     : sendConversionErrorToSlack
@Param          : String, String
@Return         : Null
@Description    : To send slack message about the errors in lead conversion
**/
    
    @future (callout = true)
    public static void sendConversionErrorToSlack(String channelName, String leadId, String errorMessage){
        List<SlackNotifications.SlackMessageRequest> srList = new List<SlackNotifications.SlackMessageRequest>();
        SlackNotifications.SlackMessageRequest sr = new SlackNotifications.SlackMessageRequest();
        sr.channelName = channelName;
        sr.message = generateLeadConversionError(leadId, errorMessage);
        srList.add(sr);
        SlackNotifications.sendMessage(srList);
        //SlackNotifications.sendMessage(inputList);
    }
    
    /**
@Methodname     : generateLeadConversionError
@Param          : String 
@Return         : Null
@Description    : To generate appropriate error message for the lead conversion
**/
    public static String generateLeadConversionError(String leadId, String errorText){
        
        String errorMessage;
        //String leadId = leadConvertList[0].getLeadID();
        String leadUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/' + leadId;
        String messageText = 'An error occurred during the automatic conversion of the SSSU Lead. Please try to convert manually '+errorText;
        
        Lead lc = new Lead();
        lc = [SELECT Id, Name FROM Lead WHERE ID =: leadId];
        
        Map<String, Object> message = new Map<String, Object>();
        message.put('text', messageText);
        List<Map<String, Object>> attachments = new List<Map<String, Object>>();
        Map<String, Object> attachment = new Map<String, Object>();
        List<Map<String, Object>> fields = new List<Map<String, Object>>();
        Map<String, Object> field = new Map<String, Object>();
        //field.put('title', 'Customer Details:');
        field.put('value', '<' + leadUrl + '|'+lc.Name+'>');
        field.put('short', true);
        fields.add(field);
        attachment.put('fields', fields);
        attachments.add(attachment);
        message.put('attachments', attachments);
        errorMessage = JSON.serialize(message);
        
        return errorMessage;
    }
    
    /**
    @Methodname     : processLeadConversionOutput
    @Param          : Trigger.New, Trigger.Old
    @Return         : Null
    @Description    : To update contact field after getting converted from lead
    **/
    
    public static void processLeadConversionOutput(List<Database.LeadConvertResult> sssuLeadConversionResult){
        
        Map<Id, Id> accIdVsConIdMap = new Map<Id, Id>();
        
        //Get converted account and contact Ids
        if(!sssuLeadConversionResult.isEmpty()){
            for(Database.LeadConvertResult lcr : sssuLeadConversionResult){
                accIdVsConIdMap.put(lcr.getAccountId(),lcr.getContactId());
            }
        }
        
        //Send the converted information for publishing
        /*if(!accIdVsConIdMap.isEmpty()){
            PublishPlatformEvents.publishBackendUserCreationEvent(accIdVsConIdMap);
        }*/
        
        Feature_Activation__mdt fa = Feature_Activation__mdt.getInstance('updateCustomConversionOnContact');
        Boolean isActive = (Boolean)fa.get('Is_Active__c');
        
        if(isActive){
            Set<Id> contactIdSet = new Set<Id>();
            List<sObject> convertedRecordList = new List<sObject>();
            
            if(!sssuLeadConversionResult.isEmpty()){
                for(Database.LeadConvertResult lcr : sssuLeadConversionResult){
                    contactIdSet.add(lcr.getContactId());
                }
            }
            
            if(!contactIdSet.isEmpty()){
                for(Id conId : contactIdSet){
                    Contact con = new Contact();
                    con.Id = conId;
                    con.Custom_Lead_Conversion__c = true;
                    convertedRecordList.add(con);
                }
                
                if(!convertedRecordList.isEmpty()){
                    try{
                        upsert convertedRecordList;
                        //ContactTriggerFunctions.callingBackendForAccess(sssuContactList);
                    }catch(Exception e){
                        Logger.finest('Failed Contact Update post SSSU conversion: '+ convertedRecordList+' '+'The error occurred: '+ e.getMessage());
                        Logger.saveLog();
                    }
                }
            }
        }
    }
    
    /**
    @Methodname     : initiateCustomLeadConversion
    @Param          : Trigger.New, Trigger.Old
    @Return         : Null
    @Description    : To initiate the lead conversion based on field changes
    **/
    
    public static void initiateCustomLeadConversion(List<Lead> leadList, Map<Id, Lead> oldLeadMap){
        
        Feature_Activation__mdt fa = Feature_Activation__mdt.getInstance('initiateCustomLeadConversion');
        Boolean isActive = (Boolean)fa.get('Is_Active__c');
        
        if(isActive){
            List<Lead> sssuLeadList = new List<Lead>();
            
            for(Lead ld : leadList){
                if(ld.Conversion_Trigger__c != oldLeadMap.get(ld.Id).Conversion_Trigger__c && ld.Conversion_Trigger__c == TRUE){
                    sssuLeadList.add(ld);
                }
            }
            
            if(!sssuLeadList.isEmpty()){
                convertLead(sssuLeadList);
            }
        }
    }
    
    /**
@Methodname     : convertLead
@Param          : List<InputVariables>
@Return         : Null
@Description    : To call the lead conversion from the flows
**/
    
    @InvocableMethod(Label = 'Initiate Lead Conversion')
    public static void convertLead(List<InputVariables> inputList){
        
        List<Lead> leadInputList = new List<Lead>();
        Lead leadInfo = inputList.get(0).signedLead;
        leadInputList.add(leadInfo);
        convertLead(leadInputList);
    }
    
    public class InputVariables{
        @InvocableVariable
        public Lead signedLead;
    }
}