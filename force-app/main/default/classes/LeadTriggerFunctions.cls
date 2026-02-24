/*
*      @author Arun Kumar
*      @date   15-Sep-2023
*      @description   Logic to handle the conversion of SSSU leads
*
*      Modification Log:
*      ------------------------------------------------------------------------------------
*      Developer                       Date                Description
*      ------------------------------------------------------------------------------------
*		Arun Kumar					16-Oct-2023			Added the method populateDomainMatchForPrivateEmails()
*		Arun Kumar					05-Dec-2023			Added checkLeadMatchWithCompanyName() for RO-1672
*		Arun Kumar					05-Dec-2023			Updated method checkConversionEligibility() on insertion for RO-1672
*		//Arun Kumar					13-Dec-2023			Updated method populateEmailDomainMatch() for RO-1672
*/
public with sharing class LeadTriggerFunctions{
    
    public static Map<Id, Id> leadIdVsAccountIdMap;
    /**
@Methodname     : populateEmailDomainMatch
@Param          : List<Lead>, Set<String>
@Return         : List<Lead>
@Description    : To populate the email domain matches on lead
**/
    public static List<Lead> populateEmailDomainMatch(List<Lead> leadList, Set<String> emailDomainSet){
        List<Lead> matchedLeadList 				= new List<Lead>();
        Map<String, Integer> domainMatchCounts 	= new Map<String, Integer>();
       
        // Query the Account records for matching Email Domains
        if(!emailDomainSet.isEmpty()){
            for (AggregateResult result : [SELECT txtEmailDomain__c, COUNT(Id) matchCount
                                           FROM Account
                                           WHERE txtEmailDomain__c IN :emailDomainSet
                                           GROUP BY txtEmailDomain__c]) {
                                               //Fetch individual results from aggregated results
                                               String domain 		= (String) result.get('txtEmailDomain__c');
                                               Integer matchCount 	= (Integer) result.get('matchCount');
                                               
                                               //Map the individual results in collections
                                               domainMatchCounts.put(domain.toLowerCase(), matchCount);
                                           }
        }
        
        // Update the Domain Match Count field on the new Lead records
        for (Lead ld : leadList) {
            if(!domainMatchCounts.isEmpty() && domainMatchCounts.containsKey(ld.Email_Domain__c.toLowerCase())){
                ld.Domain_Match_on_Lead__c = domainMatchCounts.get(ld.Email_Domain__c.toLowerCase());
            }else{
                ld.Domain_Match_on_Lead__c = Integer.valueOf(SYSTEM.Label.SSSU_Domain_Match_Count);
            }  
        }
        
        return leadList;
    }
    
    /**
@Methodname     : checkEmailDomainMatch
@Param          : List<Lead>
@Return         : Null
@Description    : To initiate the email domain population during record creation
**/
    public static void checkEmailDomainMatch(List<Lead> newLeadList){
        Set<String> emailDomainSet = new Set<String>();
        List<Lead> leadList = new List<Lead>();
        
        for(Lead ld : newLeadList){
            if(ld.Email_Domain__c != NULL){
                leadList.add(ld);
                emailDomainSet.add(ld.Email_Domain__c);
            }
        }
        
        if(!leadList.isEmpty() && !emailDomainSet.isEmpty()){
            leadList = populateEmailDomainMatch(leadList, emailDomainSet);
        }
    }
    
    
    /**
@Methodname     : checkEmailDomainMatch
@Param          : List<Lead>, List<Lead>
@Return         : Null
@Description    : To initiate the email domain population during record updates
**/
    public static void checkEmailDomainMatch(List<Lead> newLeadList, List<Lead> oldLeadList){
        
        Set<String> emailDomainSet = new Set<String>();
        List<Lead> leadList = new List<Lead>();
        Map<Id, Lead> oldLeadMap = new Map<Id, Lead>();
        
        for(Lead oldLead : oldLeadList){
            oldLeadMap.put(oldLead.Id, oldLead);
        }
        
        for(Lead ld : newLeadList){
            if(ld.Email_Domain__c != NULL && !oldLeadMap.isEmpty() && oldLeadMap.containsKey(ld.Id) && oldLeadMap.get(ld.Id).Timestamp_SSSU_lead__c != ld.Timestamp_SSSU_lead__c && ld.Timestamp_SSSU_lead__c != NULL){
                emailDomainSet.add(ld.Email_Domain__c);
                leadList.add(ld);
            }
        }
         
        if(!leadList.isEmpty() && !emailDomainSet.isEmpty()){
            leadList = populateEmailDomainMatch(leadList, emailDomainSet);
        } 
    }
    
         /**
@Methodname     : populateDomainMatchForPrivateEmails
@Param          : List<Lead>
@Return         : Null
@Description    : To populate the Domain match count as zero for private email domains
**/
    public static void populateDomainMatchForPrivateEmails(List<Lead> newLeadList){
        Set<String> emailDomainSet = new Set<String>();
        List<Lead> leadList = new List<Lead>();
        
        for(Lead ld : newLeadList){
            if(ld.Email_Domain__c == NULL){
               ld.Domain_Match_on_Lead__c = 0;
            }
        }
    }
    
    /**
@Methodname     : checkConversionEligibility
@Param          : List<Lead>
@Return         : Null
@Description    : To initiate the lead conversion during record creation
**/
    public static void checkConversionEligibility(List<Lead> newLeadList){
        
        List<Lead> sssuLeadList 				= new List<Lead>();
        List<Lead> leadWithDomainsList 			= new List<Lead>();
        leadIdVsAccountIdMap					= new Map<Id, Id>();
        Map<String, Id> leadDomainVsIdMap		= new Map<String, Id>();
        Map<String, String> leadDomainVsCompanyMap = new Map<String, String>();
        Boolean isEligible 						= FeatureManagement.checkPermission('SSSU_Lead_Conversion_LTE');
        
        // Lead information is processed and based on whether the permission to convert upto 5 email domain matches is assigned to user or not.
        // If the permission is not assigned, then only when the domain match count is zero, the automatic lead conversion and BE access is enabled
        // If the permission is assigned, then the lead could be converted until the domain match counts is five by mapping to an existing account
        
        if(isEligible){
            for(Lead newLead : newLeadList){
                if(newLead.Domain_Match_on_Lead__c <= Integer.valueOf(SYSTEM.Label.SSSU_Domain_Match_Count_LTE) && newLead.Timestamp_SSSU_lead__c != NULL && newLead.Timestamp_SSSU_HS_Workflow_completed__c != NULL){ //RO-1672
                    leadWithDomainsList.add(newLead);
                    leadDomainVsIdMap.put(newLead.Email_Domain__c, newLead.Id);
                    leadDomainVsCompanyMap.put(newLead.Email_Domain__c, newLead.Company.toLowerCase());
                }
            }
        }else{
            for(Lead newLead : newLeadList){
                if(newLead.Domain_Match_on_Lead__c == Integer.valueOf(SYSTEM.Label.SSSU_Domain_Match_Count) && newLead.Timestamp_SSSU_lead__c != NULL && newLead.Timestamp_SSSU_HS_Workflow_completed__c != NULL){ //RO-1672
                    sssuLeadList.add(newLead);
                }
            }
        }
		
        //Initiating lead conversions where domain match is zero
        if(!sssuLeadList.isEmpty()){
            selfserviceLeadConversion.convertLead(sssuLeadList);
        }
        
        //Initiating further checks for the leads where domain match is greater than zero, before converting
        if(!leadWithDomainsList.isEmpty()){
            validateLeadsWithDomainMatches(leadWithDomainsList, leadDomainVsCompanyMap, leadDomainVsIdMap);
        }
    }
    
    /**
@Methodname     : checkConversionEligibility
@Param          : List<Lead>, List<Lead>
@Return         : Null
@Description    : To initiate the lead conversion during record updates
**/
    public static void checkConversionEligibility(List<Lead> newLeadList, List<Lead> oldLeadList){
        
        Boolean isEligible 							= FeatureManagement.checkPermission('SSSU_Lead_Conversion_LTE');
        List<Lead> sssuLeadList 					= new List<Lead>();
        List<Lead> leadWithDomainsList 				= new List<Lead>();
        leadIdVsAccountIdMap						= new Map<Id, Id>();
        Map<Id, Lead> oldLeadMap 					= new Map<Id, Lead>();
        Map<String, Id> leadDomainVsIdMap			= new Map<String, Id>();
        Map<String, String> leadDomainVsCompanyMap 	= new Map<String, String>();   
        
        for(Lead oldLead : oldLeadList){
            oldLeadMap.put(oldLead.Id, oldLead);
        }
        
        // Lead information is processed and based on whether the permission to consider upto 5 email domain matches is assigned to user or not.
        // If the permission is not assigned, then only when the domain matches are zero, the automatic lead conversion and BE access is enabled
        // If the permission is assigned, then the email domain matches upto five are considered and the lead is mapped to an existing account based on the specifications
        
        for(Lead newLead : newLeadList){
            if(oldLeadMap.containsKey(newLead.Id) 
               && ((oldLeadMap.get(newLead.Id).Timestamp_SSSU_lead__c != newLead.Timestamp_SSSU_lead__c) || (oldLeadMap.get(newLead.Id).Timestamp_SSSU_HS_Workflow_completed__c != newLead.Timestamp_SSSU_HS_Workflow_completed__c))
               && newLead.Timestamp_SSSU_lead__c != NULL && newLead.Timestamp_SSSU_HS_Workflow_completed__c != NULL ){
                   if(isEligible){
                       if(newLead.Domain_Match_on_Lead__c <= Integer.valueOf(SYSTEM.Label.SSSU_Domain_Match_Count_LTE)){
                           leadWithDomainsList.add(newLead);
                           leadDomainVsIdMap.put(newLead.Email_Domain__c, newLead.Id);
                           leadDomainVsCompanyMap.put(newLead.Email_Domain__c, newLead.Company.toLowerCase());
                       } 
                   }else{
                       if(newLead.Domain_Match_on_Lead__c == Integer.valueOf(SYSTEM.Label.SSSU_Domain_Match_Count)){
                       		sssuLeadList.add(newLead);
                       }
                   }  
               }
        }

        //Initiating lead conversions where domain match is zero
        if(!sssuLeadList.isEmpty()){
            selfserviceLeadConversion.convertLead(sssuLeadList);
        }
        
        //Initiating further checks for the leads where domain match is less than or equal to expanded limit, before converting
        if(!leadWithDomainsList.isEmpty()){
            validateLeadsWithDomainMatches(leadWithDomainsList, leadDomainVsCompanyMap, leadDomainVsIdMap);
        }
    }
       
    /**
@Methodname     : createSSSUDuplicateCase
@Param          : List<Lead>
@Return         : Null
@Description    : To create SSSU Duplicate Check case types for eligible signups
**/
    
    public static void createSSSUDuplicateCase(List<Lead> signedUpLeadList){
        Boolean isEligible 		= FeatureManagement.checkPermission('SSSU_Lead_Conversion_LTE');
        List<Case> sssuCaseList = new List<Case>();
        List<Lead> sssuLeadList = new List<Lead>();
        Map<Id, Integer> leadIdVsOpenCaseMap = new Map<Id, Integer>();
        
        for(Lead ld : signedUpLeadList){
            if(ld.Timestamp_SSSU_lead__c != NULL && ld.Timestamp_SSSU_HS_Workflow_completed__c != NULL && ld.Domain_Match_on_Lead__c != NULL 
               && ((!isEligible && ld.Domain_Match_on_Lead__c > Integer.valueOf(SYSTEM.Label.SSSU_Domain_Match_Count)) 
                   || (isEligible && ld.Domain_Match_on_Lead__c <= Integer.valueOf(SYSTEM.Label.SSSU_Domain_Match_Count_LTE)))
              ){
                sssuLeadList.add(ld);
            }         
        }
        
        if(!sssuLeadList.isEmpty()){
            Id caseSSSULeadDuplicateRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('SSSU Lead Duplicate Case').getRecordTypeId();
            Id cusopsQueueId = [SELECT Id FROM Group WHERE DeveloperName = 'CusOps_Case_Queue' LIMIT 1].Id;
            
            for(AggregateResult result : [SELECT Lead__c, count(Id) openCase 
                                          FROM Case 
                                          WHERE Lead__c <> NULL
                                          AND Lead__c IN :signedUpLeadList
                                          AND RecordTypeId =: caseSSSULeadDuplicateRT 
                                          AND Status NOT IN ('Closed', 'Lost') 
                                          GROUP BY Lead__c ]){
                                              Id inputLeadId = (Id)result.get('Lead__c');
                                              Integer openCaseCount = (Integer)result.get('openCase');
                                              leadIdVsOpenCaseMap.put(inputLeadId, openCaseCount);
                                          }
            
            for(Lead inputLead : signedUpLeadList){
                if(!leadIdVsOpenCaseMap.containsKey(inputLead.Id) || leadIdVsOpenCaseMap.get(inputLead.Id) == 0){
                    Case cs = new Case();
                    cs.Company_Name__c 			= inputLead.Company;
                    cs.Email__c 				= inputLead.Email ;
                    cs.Email_domain__c 			= inputLead.Email_Domain__c;
                    cs.Lead_Owner__c 			= inputLead.OwnerId;
                    cs.Lead_Phone__c 			= inputLead.Phone;
                    cs.Lead__c 					= inputLead.Id;
                    cs.OwnerId 					= cusopsQueueId;
                    cs.Priority 				= 'SSSU Duplicate Check';
                    cs.RecordTypeId 			= caseSSSULeadDuplicateRT;
                    cs.Service_Country_Lead__c 	= inputLead.Service_Country__c;
                    cs.Status 					= 'New';
                    cs.Subject 					= 'SSSU Lead Duplicate';
                    cs.Timestamp_SSSU_Case__c 	= inputLead.Timestamp_SSSU_lead__c;
                    sssuCaseList.add(cs);
                }
            }
            
            if(!sssuCaseList.isEmpty()){
                try{
                    insert sssuCaseList;
                }catch(Exception e){
                    System.debug('Error while creating SSSU Duplicate Case'+e.getStackTraceString());
                }
            }
        }
    }
    
    /**
@Methodname     : checkLeadMatchWithCompanyName
@Param          : List<Lead>
@Return         : Null
@Description    : To check for the accounts based on the match between account name and lead company
**/
    
    public static void validateLeadsWithDomainMatches(List<Lead> leadWithDomainsList, Map<String, String> leadDomainVsCompanyMap, Map<String, Id> leadDomainVsIdMap){
        
        leadIdVsAccountIdMap = new Map<Id, Id>();
        
        if(!leadDomainVsCompanyMap.isEmpty()){
            for(Account exitingCustomer : [SELECT Id, txtEmailDomain__c, Name, txtCompanyId__c
                                           FROM Account
                                           WHERE txtEmailDomain__c IN :leadDomainVsCompanyMap.keySet()
                                          ]){
                                              if(exitingCustomer.txtCompanyId__c == NULL && leadDomainVsCompanyMap.get(exitingCustomer.txtEmailDomain__c) == exitingCustomer.Name.toLowerCase() && !leadDomainVsIdMap.isEmpty() && leadDomainVsIdMap.containsKey(exitingCustomer.txtEmailDomain__c)){
                                                  leadIdVsAccountIdMap.put(leadDomainVsIdMap.get(exitingCustomer.txtEmailDomain__c), exitingCustomer.Id); 
                                              } 
                                          }
        }
        
        if(!leadWithDomainsList.isEmpty()){
            selfserviceLeadConversion.convertLead(leadWithDomainsList);
        }
    }

}