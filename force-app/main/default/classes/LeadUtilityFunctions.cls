/*
 *      @author Arun Kumar
 *      @date   29-Jul-2023
 *      @description   Logic to handle the lead object related functions
 *
 *      Modification Log:
 *      ------------------------------------------------------------------------------------
 *      Developer                       Date                Description
 *      ------------------------------------------------------------------------------------
 *      
 * 
 * 
 */
public with sharing class LeadUtilityFunctions {

    /**
    * @Methodname     : calculateDomainMatchCount
    * @Param          : List<Lead>
    * @Return         : Null
    * @Description    : Performs three functions
    * 1. Call to create SSSU Duplicate case
    * 2. Calculates and updates domain match on lead
    * 3. Convert the lead if domain match is zero
**/
    
    public static void calculateDomainMatchCount(List<Lead> leadList){
        
        Set<String> leadDomainSet = new Set<String>();
        List<Lead> sssuNewLeadList = new List<Lead>();
        List<Lead> domainOnLeadList = new List<Lead>();
        Map<String, Integer> domainVsMatchCountsMap = new Map<String, Integer>();
        
        //Create SSSU Duplicate Cases
        createSSSUDuplicateCase(leadList);
        
        for(Lead ld : leadList){
            if(ld.Email_Domain__c != NULL){
                leadDomainSet.add(ld.Email_Domain__c);
            }
        }
        
        // Fetch accounts with same email domain
        if(!leadDomainSet.isEmpty()){
            for(AggregateResult result : [SELECT txtEmailDomain__c, COUNT(Id) matchCount
                                          FROM Account
                                          WHERE txtEmailDomain__c IN :leadDomainSet
                                          GROUP BY txtEmailDomain__c
                                         ]) {
                                             String domain = (String) result.get('txtEmailDomain__c');
                                             Integer matchCount = (Integer) result.get('matchCount');
                                             domainVsMatchCountsMap.put(domain.toLowerCase(), matchCount);
                                         }
            
            // Identify the matched domains
            for(Lead ld : leadList){
                if (ld.Email_Domain__c != null){
                    if(domainVsMatchCountsMap.containsKey(ld.Email_Domain__c)){
                        ld.Domain_Match_on_Lead__c = domainVsMatchCountsMap.get(ld.Email_Domain__c);
                        domainOnLeadList.add(ld);
                    }else{
                        ld.Domain_Match_on_Lead__c = 0;
                        sssuNewLeadList.add(ld);
                    }
                }
            }  
        }
        
        //Update domain match count on lead
        domainOnLeadList.addAll(sssuNewLeadList);
        if(!domainOnLeadList.isEmpty()){
            try{
                update domainOnLeadList;
            }catch(Exception e){
                System.debug('Error while updating domain match on lead'+e.getStackTraceString());
            }
        }
        
        //Auto convert the leads whose domain match is zero
        if(!sssuNewLeadList.isEmpty()){
            selfserviceLeadConversion.convertLead(sssuNewLeadList);
        }
    }
    
    /**
@Methodname     : createSSSUDuplicateCase
@Param          : List<Lead>
@Return         : Null
@Description    : To create SSSU Duplicate Check case types for eligible signups
**/
    
    public static void createSSSUDuplicateCase(List<Lead> signedUpLeadList){
        List<Case> sssuCaseList = new List<Case>();
        Id caseSSSULeadDuplicateRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('SSSU Lead Duplicate Case').getRecordTypeId();
        
        for(Lead inputLead : signedUpLeadList){
            if(inputLead.Timestamp_SSSU_lead__c != NULL && inputLead.Timestamp_SSSU_HS_Workflow_completed__c != NULL){
                Case cs = new Case();
                cs.Company_Name__c 			= inputLead.Company;
                cs.Email__c 				= inputLead.Email ;
                cs.Email_domain__c 			= inputLead.Email_Domain__c;
                cs.Lead_Owner__c 			= inputLead.OwnerId;
                cs.Lead_Phone__c 			= inputLead.Phone;
                cs.Lead__c 					= inputLead.Id;
                cs.OwnerId 					= inputLead.OwnerId;
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
    
    /**
@Methodname     : domainMatchAndConversionCheck
@Param          : List<Lead>
@Return         : Null
@Description    : To be called from flow to start the domain match and lead conversion
**/
    @InvocableMethod(Label = 'Initiate Domain match and conversion (if applicable)')
    public static void domainMatchAndConversionCheck(List<InputVariables> inputList){
        
        List<Lead> leadInputList = new List<Lead>();
        Lead leadInfo = inputList.get(0).signedLead;
        leadInputList.add(leadInfo);
        calculateDomainMatchCount(leadInputList);
    }
    
    public class InputVariables{
        @InvocableVariable
        public Lead signedLead;
    }
}