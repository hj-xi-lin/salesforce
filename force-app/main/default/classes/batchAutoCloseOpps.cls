/*
*      @author Lisa Müller
*      @date   16-Apr-2024
*      @description   Logic to automatically close open opps RO-2036
*
*      Modification Log:
*      ------------------------------------------------------------------------------------
*       Developer                   Date                    Description
*      ------------------------------------------------------------------------------------
*       Lisa Müller                 2024-06-12              RO-2090 Include new Opp RT Transactional with new Stage
*       Varun Subhash               2024-07-12              RO-2146 Updated to exclude opps created via upload and 
*       Varun Subhash               2024-10-22              RO-2265 Excluded Account ownership updates to Lead Gen for Account of GTM Motion Insode Sales
*       Varun Subhash               2024-12-23              RO-2353 Removal of updates on Account
*/
public class batchAutoCloseOpps implements Database.Batchable<sObject> {
    
    // Getting RT & user IDs
    private static final Id oppSalesRT                  =   Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Sales').getRecordTypeId();
    private static final Id oppTransactionalRT          =   Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Sales_Transactional').getRecordTypeId();
    private static final Id accInventoryRT              =   Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Inventory_Partner').getRecordTypeId();
    private static final Id accAgencySalesRT            =   Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Agency_Sales').getRecordTypeId();
    private static final Id accAgencyCustomerSalesRT    =   Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Agency_Customer_Sales').getRecordTypeId();
    private static final Id accOutboundRT               =   Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Outbound').getRecordTypeId();
    private static final Id userLeadGenId;
    private static final Integer oppThresholdAge1;
    private static final Integer oppThresholdAge2;
    private static final Date oppThresholdDate1;
    private static final Date oppThresholdDate2;
    private static final String oppLossReason;
    
    static {
        userLeadGenId       =   [SELECT Id FROM User WHERE Name = 'Lead Gen' LIMIT 1].Id;
        oppThresholdAge1    =   Integer.valueOf(Label.HouseKeeping_OppLosingThreshold);
        oppThresholdAge2    =   Integer.valueOf(Label.HouseKeeping_UploadOppLosingThreshold);
        oppThresholdDate1   =   System.today().addDays(-oppThresholdAge1);
        oppThresholdDate2   =   System.today().addDays(-oppThresholdAge2);
        oppLossReason       =   Label.HouseKeeping_OppLosingLossReason;
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC){
        
        return Database.getQueryLocator([
            SELECT Id, Record_Type__c,StageName,GTM_Motion_Opportunity__c,CreatedDate,Opportunity_Creation_Trigger__c, AccountId, Account.RecordTypeId, Account.Stage_ACM__c, Account.Record_Type__c,Account.OwnerId,Account.GTM_Motion_Account__c FROM Opportunity WHERE 
                (RecordTypeId = :oppSalesRT OR RecordTypeId = :oppTransactionalRT)
                AND (StageName = 'Not reached yet' OR StageName = 'Qualified Prospect' OR StageName = 'Ready for Sales')
                AND ((Opportunity_Creation_Trigger__c != null AND CreatedDate <= :oppThresholdDate1) OR (Opportunity_Creation_Trigger__c = null AND CreatedDate <= :oppThresholdDate2))
                AND GTM_Motion_Opportunity__c NOT IN ('Enterprise Retention',  'Enterprise Expansion',  'Enterprise New Business')
              AND OwnerProfile__c != 'Large Prospector - External'
                AND Account.RecordTypeId != :accInventoryRT AND Account.RecordTypeId != :accAgencySalesRT AND Account.RecordTypeId != :accAgencyCustomerSalesRT    
            ]);
    }
    
    public void execute(Database.BatchableContext BC, List<Opportunity> opps) {
        List<Opportunity> oppsToUpdate  =   new List<Opportunity>();
        List<Account> acctsToUpdate     =   new List<Account>();
        Map<Id, Account> accountMap     =   new Map<Id, Account>();
               
        for (Opportunity opp : opps) {
            if (opp.Opportunity_Creation_Trigger__c != null && opp.Record_Type__c != 'oppTransactionalRT') {
                // Use oppThresholdDate1 for opportunities where Opportunity_Creation_Trigger__c is not null
                if ((opp.CreatedDate <= oppThresholdDate1)) {
                    opp.StageName     =   'Closed Lost';
                    opp.plLossReason__c =   oppLossReason;
                    oppsToUpdate.add(opp);
                   
                    if (!accountMap.containsKey(opp.AccountId)) {
                        accountMap.put(opp.AccountId, opp.Account);
                    }
                }
            } else {
                
                // Use oppThresholdDate2 for opportunities where Opportunity_Creation_Trigger__c is null
                if ((opp.CreatedDate <= oppThresholdDate2))  {
                    opp.StageName ='Closed Lost';
                    opp.plLossReason__c =   oppLossReason;
                    oppsToUpdate.add(opp);
                    if (!accountMap.containsKey(opp.AccountId)) {
                        accountMap.put(opp.AccountId, opp.Account);
                    }
                }
            }
        }
        System.debug('Account Info>>'+accountMap);
        for (Account acc : accountMap.values()) {
            System.debug('Account Updates>>');
            acc.RecordTypeId    =   accOutboundRT;
            acc.Stage_ACM__c    =   'Prospect';
            System.debug('Account Owner>>'+acc.OwnerId);
            acctsToUpdate.add(acc);
        }
        
        
        // Update records      
        Database.SaveResult[] resultsOpps   =   Database.update(oppsToUpdate, false);
        Database.SaveResult[] resultsAccts  =   Database.update(acctsToUpdate, false);
        // Log errors
        for (Database.SaveResult sr : resultsOpps) {
            if (!sr.isSuccess()) {
                for (Database.Error err : sr.getErrors()) {
                    System.debug('Failed to update Opportunity with ID: ' + sr.getId() + '. The error occurred: ' + err.getStatusCode() + ' - ' + err.getMessage());
                }
            }
        }
        
        for (Database.SaveResult sr : resultsAccts) {
            if (!sr.isSuccess()) {
                for (Database.Error err : sr.getErrors()) {
                    System.debug('Failed to update Account with ID: ' + sr.getId() + '. The error occurred: ' + err.getStatusCode() + ' - ' + err.getMessage());
                }
            }
        }       
        Logger.saveLog();
    }
    
    public void finish(Database.BatchableContext BC) {
    }
}