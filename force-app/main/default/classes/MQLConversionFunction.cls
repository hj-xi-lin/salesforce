/*
*      @author Arun Kumar
*      @date   21-Nov-2023
*      @description   Logic to handle the conversion of MQLs
*
*      Modification Log:
*      ------------------------------------------------------------------------------------
*      Developer        Date                Description
*      ------------------------------------------------------------------------------------
*       Arun Kumar      23-Apr-2024         Updated convertLead(),postMQLConversionUpdates() for RO-2054                
*/

public with sharing class MQLConversionFunction {
    
    public static final string MQL_CONVERSION = 'MQL Conversion';
    
    /**
@Methodname     : checkMQLConversionEligibilityOnInsert
@Param          : List<Lead>
@Return         : Null
@Description    : To check if the MQL could be converted during the creation
**/
    public static void checkMQLConversionEligibilityOnInsert(List<Lead> newLeadList){
         
        Map<Lead, String> leadVsConversionTypeMap = new Map<Lead, String>();
        Map<Id, Id> leadVsCampaignIdMap = new Map<Id, Id>();
        
        //Check for the conversion eligibility
       for(Lead ld : newLeadList){
            if(ld.Domain_Match_on_Lead__c == Integer.valueOf(SYSTEM.Label.SSSU_Domain_Match_Count) && ld.Timestamp_SSSU_lead__c == NULL
               && ld.Timestamp_Latest_MQL_conversion__c != NULL){
                   leadVsConversionTypeMap.put(ld, MQL_CONVERSION);
                   leadVsCampaignIdMap.put(ld.Id, ld.Webinar_Campaign_Source__c);
               }
        }
        
        //Send lead to initiate conversion
        if(!leadVsConversionTypeMap.isEmpty()){
            initiateMQLConversion(leadVsConversionTypeMap, leadVsCampaignIdMap);
        }   
    }
    
    /**
@Methodname     : checkMQLConversionEligibilityOnUpdate
@Param          : List<Lead>
@Return         : Null
@Description    : To check if the MQL could be converted during the Timestamp Latest MQL Conversion updates
**/
    public static void checkMQLConversionEligibilityOnUpdate(List<Lead> newLeadList, List<Lead> oldLeadList){
        
        Map<Id, Lead> oldLeadMap = new Map<Id, Lead>();
        Map<Lead, String> leadVsConversionTypeMap = new Map<Lead, String>();
        Map<Id, Id> leadVsCampaignIdMap = new Map<Id, Id>();
        
        for(Lead ld : oldLeadList){
            oldLeadMap.put(ld.Id, ld);
        }
        
        //Check for the conversion eligibility
       for(Lead ld : newLeadList){
            if(ld.Domain_Match_on_Lead__c == Integer.valueOf(SYSTEM.Label.SSSU_Domain_Match_Count) && ld.Timestamp_SSSU_lead__c == NULL
               && (oldLeadMap.get(ld.Id).Timestamp_Latest_MQL_conversion__c != ld.Timestamp_Latest_MQL_conversion__c) && ld.Timestamp_Latest_MQL_conversion__c != NULL){
                       leadVsConversionTypeMap.put(ld, MQL_CONVERSION);
                       leadVsCampaignIdMap.put(ld.Id, ld.Webinar_Campaign_Source__c);
                   }
        }
        
        //Send lead to initiate conversion
        if(!leadVsConversionTypeMap.isEmpty()){
            initiateMQLConversion(leadVsConversionTypeMap, leadVsCampaignIdMap);
        }
    }
    
     /**
@Methodname     : initiateMQLConversion
@Param          : Map<Lead, String>, Map<Id, Id>
@Return         : Null
@Description    : To initiate the MQL Conversions
**/
    
    public static void initiateMQLConversion(Map<Lead, String> leadVsProcessMap, Map<Id, Id> leadVsCampaignIdMap){
        
        List<Database.LeadConvertResult> conversionResults = new List<Database.LeadConvertResult>();
        
        //Initiate lead conversion
        if(!leadVsProcessMap.isEmpty()){
            conversionResults = convertLead(leadVsProcessMap);
        }
        
        //Perform updates on the converted records
        if(!conversionResults.isEmpty()){
            postMQLConversionUpdates(conversionResults, leadVsCampaignIdMap);
        }
    }
        
    /**
@Methodname     : convertLead
@Param          : List<Lead>
@Return         : Null
@Description    : To convert the MQLs to account, contact and opportunity
**/
    
    public static List<Database.LeadConvertResult> convertLead(Map<Lead,String> leadVsProcessNameMap){
        
        Id presalesAdminID = [SELECT Id FROM User WHERE Name = 'Pre-Sales Admin' LIMIT 1].Id;
        List<Database.LeadConvert> mqlLeadConverts = new List<Database.LeadConvert>();
        List<Database.LeadConvertResult> leadConvertResultList = new List<Database.LeadConvertResult>();
        
        // Convert leads
        for(Lead mqlLead : leadVsProcessNameMap.keySet()){
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(mqlLead.Id);
            lc.setOwnerId(presalesAdminID);
            lc.setDoNotCreateOpportunity(true);
            lc.setConvertedStatus('Converted');
            mqlLeadConverts.add(lc);
        }
        
        if(!mqlLeadConverts.isEmpty()){
            try{
                leadConvertResultList = Database.convertLead(mqlLeadConverts);
            }catch(Exception e){
                Logger.finest('Failed MQL conversion: '+ mqlLeadConverts+' '+'The error occurred: '+ e.getMessage());
                Logger.saveLog();
            }
        }
        
        return leadConvertResultList;
    }
    
    /**
@Methodname     : postConversionUpdates
@Param          : List<Database.LeadConvertResult>
@Return         : Null
@Description    : Updating Recordtypes and creating related records for the Account, Contact and Opportunity from MQL Conversion
**/
    
    public static void postMQLConversionUpdates(List<Database.LeadConvertResult> leadConversionResults, Map<Id, Id> leadVsCampaignMap){
        
        Id accountSalesRT                   = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Sales').getRecordTypeId();
        //Id oppSalesRT                         = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sales').getRecordTypeId();
        Set<Id> convertedAccIdSet           = new Set<Id>();
        Set<Id> convertedConIdSet           = new Set<Id>();
        //Set<Id> convertedOppIdSet             = new Set<Id>();
        List<sObject> convertedObjList      = new List<sObject>();
        //Map<Id, Id> conVsOppIdMap         = new Map<Id, Id>();
        Map<Id, Id> oppVsLeadIdMap          = new Map<Id, Id>();
        
        //Retrieve the converted account, contact and opportunity Ids
        for(Database.LeadConvertResult lcr : leadConversionResults){
            if(lcr.isSuccess()){
                convertedAccIdSet.add(lcr.getAccountId());
                convertedConIdSet.add(lcr.getContactId());
                //convertedOppIdSet.add(lcr.getOpportunityId());
                oppVsLeadIdMap.put(lcr.getOpportunityId(),lcr.getLeadId());
                //conVsOppIdMap.put(lcr.getContactId(),lcr.getOpportunityId());
            }
        }
        
        //Update converted accounts
        if(!convertedAccIdSet.isEmpty()){
            for(Id accId : convertedAccIdSet){
                Account acc      = new Account();
                acc.Id           = accId;
                acc.RecordTypeId = accountSalesRT;
                convertedObjList.add(acc);
            }
        }
        
        //update converted opportunities
        /*
        if(!convertedOppIdSet.isEmpty()){
            for(Id oppId : convertedOppIdSet){
                Opportunity opp     = new Opportunity();
                opp.Id              = oppId;
                opp.RecordTypeId    = oppSalesRT;
                opp.StageName       = 'Qualified Prospect';
                opp.CloseDate       = SYSTEM.Today()+30;
                opp.CampaignId      = leadVsCampaignMap.get(oppVsLeadIdMap.get(oppId));
                convertedObjList.add(opp);
            }
        }*/
        
        //Update converted contacts
        if(!convertedConIdSet.isEmpty()){
            for(Id conId : convertedConIdSet){
                Contact con = new Contact();
                con.Id      = conId;
                convertedObjList.add(con);
            }
        }
        
        if(!convertedObjList.isEmpty()){
            try{
                upsert convertedObjList;
            }catch(Exception e){
                Logger.finest('Failed to update converted MQL: '+convertedObjList+' '+'The error occurred: '+e.getMessage());
                Logger.saveLog();
            }
        } 
    }
}