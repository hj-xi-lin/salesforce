/*
*      @author Arun Kumar
*      @date   21-Apr-2023
*      @description   Class to handle generic functions related to HeyPaket
*
*      Modification Log:
*      ------------------------------------------------------------------------------------
*      	Developer      	Date         	Description
*      ------------------------------------------------------------------------------------
*		Arun Kumar		08.06.2023		Updated heypaketActivation() to include additional fields
*	   	Arun Kumar		12.06.2023		Updated heypaketActivation() to include activating new packets and deactivating old packets
*		Arun Kumar		08.08.2023		RO-1604 : Updated heypaketActivation() to combine the field updates for renewal and upsell activations
*		Arun Kumar		08.08.2023		RO-1604 : Created createBudgetValidityCase().
*		Arun Kumar		08.08.2023		RO-1604 : Updated heypaketActivation() to include the calling of createBudgetValidityCase() in renewal/upsell logic
*		Arun Kumar		09.08.2023		RO-1604 : Updated heypaketActivation()to comment the calling for flow HeyPaket_Activation
*		Arun Kumar		24.10.2023		RO-1666 : Created checkHeyPaketActivationEligibility() for validating and triggering HeyPaket Activation
*		Lisa Müller		09.02.2024		RO-1941 : Updated error logging to create a single log for every record instead of one log for the whole batch
*/
public with sharing class HeyPaketUtility {
    
    /**
@Methodname     : checkHeyPaketActivationEligibility
@Param          : List<Opportunity>, List<Opportunity>
@Return         : Null
@Description    : To trigger the HeyPaket activation for the opportunity if the criteria is matched
**/ 
    public static void checkActivationEligibility(List<Opportunity> newList, List<Opportunity> oldList){
        
        List<Opportunity> opptoActivateList = new List<Opportunity>();
        Map<Id, Opportunity> oldOppMap = new Map<Id, Opportunity>();
        
        for(Opportunity opp : oldList){
           oldOppMap.put(opp.Id, opp); 
        }
        
        for(Opportunity opp : newList){
            if(oldOppMap.containsKey(opp.Id) && oldOppMap.get(opp.Id).StageName != opp.StageName 
               && opp.StageName == SYSTEM.Label.STAGE_CLOSED_WON && opp.HeyPaket_Start_Date__c == SYSTEM.Today() && opp.HeyPaket_Status__c != 'Active'){
                opptoActivateList.add(opp);
            }
        }
        
        if(!opptoActivateList.isEmpty()){
            heypaketActivation(opptoActivateList);
        }
    }
    
     /**
@Methodname     : heypaketActivation
@Param          : List<Opportunity>
@Return         : Null
@Description    : To initiate the HeyPaket activation
**/ 
    public static void heypaketActivation(List<Opportunity> oppList){
        
        Set<Id> accountIds = new Set<Id>();
        List<Account> activatedAccList = new List<Account>();
        List<Opportunity> deactivatedOppList = new List<Opportunity>();
        Map<Id, Account> accountMap;
        Map<Id, Id> oppIdVsAccIdMap = new Map<Id, Id>();
        
        //Retrieve eligibility 
        Feature_Activation__mdt fa = Feature_Activation__mdt.getInstance('HeyPaket_Activation_via_Customisation');
        Boolean isActive = (Boolean)fa.get('Is_Active__c');
        
        for(Opportunity opp : oppList) {
            accountIds.add(opp.AccountId);
        }
        
        accountMap = new Map<Id, Account>([SELECT Id, Name, Next_HeyPaket__c, Last_HeyPaket__c, Active_HeyPaket__c, Active_HeyPaket__r.HeyPaket_Status__c, Active_HeyPaket__r.HeyPaket_Type__c FROM Account WHERE Id IN :accountIds]);
        
        if(isActive){
            for(Opportunity opp : oppList){
                opp.HeyPaket_Status__c = SYSTEM.Label.HeyPaket_Active;
                opp.Timestamp_HeyPaket_Activation__c = System.now();
                if(!opp.HeyPaket_Start_Date_reached__c) opp.HeyPaket_Start_Date_reached__c = TRUE;
                
                if(!accountMap.isEmpty() && accountMap.containsKey(opp.AccountId)){
                    if(accountMap.get(opp.AccountId).Active_HeyPaket__c == NULL){//New Activation
                        //Activating accounts
                        accountMap.get(opp.AccountId).Active_HeyPaket__c = opp.Id;
                        accountMap.get(opp.AccountId).Next_HeyPaket__c = NULL;
                        activatedAccList.add(accountMap.get(opp.AccountId));
                        //To do - Logic to send New Activation Slack message
                    }else if((accountMap.get(opp.AccountId).Active_HeyPaket__c != NULL && accountMap.get(opp.AccountId).Active_HeyPaket__r.HeyPaket_Status__c == SYSTEM.Label.HeyPaket_Renewed) // Renewal
                            || (accountMap.get(opp.AccountId).Active_HeyPaket__c != NULL && (accountMap.get(opp.AccountId).Active_HeyPaket__r.HeyPaket_Status__c == SYSTEM.Label.HeyPaket_Active || accountMap.get(opp.AccountId).Active_HeyPaket__r.HeyPaket_Status__c == SYSTEM.Label.HeyPaket_Cancelled)) // Upsell
                            ){
                        //Deactivating previous Pakets
                        accountMap.get(opp.AccountId).Active_HeyPaket__r.HeyPaket_Status__c = SYSTEM.Label.HeyPaket_Inactive;
                        deactivatedOppList.add(accountMap.get(opp.AccountId).Active_HeyPaket__r);
                        //Activating Renewal & upsell accounts
                        accountMap.get(opp.AccountId).Last_HeyPaket__c = accountMap.get(opp.AccountId).Active_HeyPaket__c;
                        accountMap.get(opp.AccountId).Active_HeyPaket__c = opp.Id;
                        accountMap.get(opp.AccountId).Next_HeyPaket__c = NULL;
                        activatedAccList.add(accountMap.get(opp.AccountId));
                        //To do - Logic to send Renewal activation Slack message
                        
                        //Checking eligibility for budget validity case - Professional to Professional (or) Professional to Ultimate (or) Ultimate to Ultimate
                        if((accountMap.get(opp.AccountId).Active_HeyPaket__r.HeyPaket_Type__c == SYSTEM.Label.HeyPaket_Professional && opp.HeyPaket_Type__c == SYSTEM.Label.HeyPaket_Professional) 
                           || (accountMap.get(opp.AccountId).Active_HeyPaket__r.HeyPaket_Type__c == SYSTEM.Label.HeyPaket_Ultimate && opp.HeyPaket_Type__c == SYSTEM.Label.HeyPaket_Ultimate)
                          	|| (accountMap.get(opp.AccountId).Active_HeyPaket__r.HeyPaket_Type__c == SYSTEM.Label.HeyPaket_Professional && opp.HeyPaket_Type__c == SYSTEM.Label.HeyPaket_Ultimate)){
                                oppIdVsAccIdMap.put(accountMap.get(opp.AccountId).Last_HeyPaket__c, accountMap.get(opp.AccountId).Id);
                        }
                    }
                    /* Commented as a part of RO-1604. The entry point is combined with the renewal activations
                     * else if(accountMap.get(opp.AccountId).Active_HeyPaket__c != NULL && (accountMap.get(opp.AccountId).Active_HeyPaket__r.HeyPaket_Status__c == SYSTEM.Label.HeyPaket_Active || accountMap.get(opp.AccountId).Active_HeyPaket__r.HeyPaket_Status__c == SYSTEM.Label.HeyPaket_Cancelled)){
                        //Deactivating previous Pakets
                        accountMap.get(opp.AccountId).Active_HeyPaket__r.HeyPaket_Status__c = SYSTEM.Label.HeyPaket_Inactive;
                        deactivatedOppList.add(accountMap.get(opp.AccountId).Active_HeyPaket__r);
                        //Activating Upsell accounts
                        accountMap.get(opp.AccountId).Last_HeyPaket__c = accountMap.get(opp.AccountId).Active_HeyPaket__c;
                        accountMap.get(opp.AccountId).Active_HeyPaket__c = opp.Id;
                        accountMap.get(opp.AccountId).Next_HeyPaket__c = NULL;
                        activatedAccList.add(accountMap.get(opp.AccountId));
                        //To do - Logic to send Upsell activation Slack message
                    }*/
                }
            }
            
            //RO-1604
            if(!oppIdVsAccIdMap.isEmpty()){
                createBudgetValidityCase(oppIdVsAccIdMap);
            }
            
            /*if(!deactivatedOppList.isEmpty()){
                oppList.addAll(deactivatedOppList);
            }*/
            
            // Record updates and Error Logs
            String controlDatabaseMethod = System.Label.HeyPaketActivation_DataBaseMethod;
            if(controlDatabaseMethod == 'Yes'){
                
                //Update deactivated packets
                if(!deactivatedOppList.isEmpty()){
                	Database.SaveResult[] resultsDeactivatedOppList = Database.update(deactivatedOppList, false);
                	// Log errors
                	for (Database.SaveResult sr : resultsDeactivatedOppList) {
                    	if (!sr.isSuccess()) {
                        	for(Database.Error err : sr.getErrors()) {
                            	Logger.finest('HeyPaket activation failed - unable to deactivate old paket: ' + sr.getId() + '. The error occurred: ' + err.getStatusCode() + ' - ' + err.getMessage());
                            	}
                        	}
                    	}		
                	Logger.saveLog();
            	}
                
                //Activate latest packets
                Database.SaveResult[] resultsOppList = Database.update(oppList, false);
                // Log errors
                for (Database.SaveResult sr : resultsOppList) {
                    if (!sr.isSuccess()) {
                        for(Database.Error err : sr.getErrors()) {
                            Logger.finest('HeyPaket activation failed - unable to activate opp: ' + sr.getId() + '. The error occurred: ' + err.getStatusCode() + ' - ' + err.getMessage());
                        }
                    }
                }
                Logger.saveLog();
                
                //Update accounts with recent packet information
                Database.SaveResult[] resultsAccList = Database.update(activatedAccList, false);
                // Log errors
                for (Database.SaveResult sr : resultsAccList) {
                    if (!sr.isSuccess()) {
                        for(Database.Error err : sr.getErrors()) {
                            Logger.finest('HeyPaket activation failed - unable to update accounts with activation details: ' + sr.getId() + '. The error occurred: ' + err.getStatusCode() + ' - ' + err.getMessage());
                        }
                    }
                }		
                Logger.saveLog();                
                
            } else{
                
                //Update deactivated packets
                if(!deactivatedOppList.isEmpty()){
                    try{
                        update deactivatedOppList;  
                    }catch(Exception e){
                        Logger.finest('HeyPaket activation failed - unable to deactivate old pakets : '+deactivatedOppList+' '+'The error occurred: '+e.getMessage());
                        Logger.saveLog();
                    }
                }
                
                //Activate latest packets
                try{
                    update oppList;
                }catch(Exception e){
                    Logger.finest('HeyPaket activation failed - unable to activate opps : '+oppList+' '+'The error occurred: '+e.getMessage());
                    Logger.saveLog();
                }
                
                //Update accounts with recent packet information
                try{
                    update activatedAccList;
                }catch(Exception e){
                    Logger.finest('HeyPaket activation failed - unable to update accounts with activation details : '+activatedAccList+' '+'The error occurred: '+e.getMessage());
                    Logger.saveLog();
                }
                                 
            }
            
        }/*Commented as a part of RO-1604. 
           else{
            Map<String, Object> flowInputs = new Map<String, Object>();
            flowInputs.put('varOppList', oppList);
            flowInputs.put('varAccountList', accountMap.values());
            Flow.Interview.HeyPaket_Activation heypaketActivationFlow = new Flow.Interview.HeyPaket_Activation(flowInputs);
            if(!Test.isRunningTest()){
                heypaketActivationFlow.start();
            }
        }*/
    }
    
    /**
    @Methodname     : createBudgetValidityCase
    @Param          : Map<Id, Id> -> Opportunity Id and Account Id
    @Return         : Null
    @Description    : RO-1604 - To create Budget Validity case for deactivated HeyPakets
    **/
    
    public static void createBudgetValidityCase(Map<Id, Id> oppVsAccIdMap){
        
        Feature_Activation__mdt fa = Feature_Activation__mdt.getInstance('createBudgetValidityCase');
        Boolean isActive = (Boolean)fa.get('Is_Active__c');
        
        if(isActive){
            List<Case> budgetCaseList = new List<Case>();
            Id caseRepeatPurchaseRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get(SYSTEM.Label.Case_Repeat_Purchase).getRecordTypeId();
            Id cusOpsQueueId = [SELECT Id FROM Group WHERE DeveloperName = 'CusOps_Case_Queue'].Id;
            
            if(!oppVsAccIdMap.isEmpty()){
                for(Id oppId : oppVsAccIdMap.keySet()){
                    Case budgetCase = new Case();
                    budgetCase.Subject = SYSTEM.Label.HeyPaket_Budget_Extension_Case ;
                    budgetCase.Description_RichText__c = SYSTEM.Label.HeyPaket_Budget_Validity_Case_Description;
                    budgetCase.Opportunity__c = oppId;
                    budgetCase.RecordTypeId = caseRepeatPurchaseRT;
                    budgetCase.Status = SYSTEM.Label.New_Case;
                    budgetCase.AccountId = oppVsAccIdMap.get(oppId);
                    budgetCase.OwnerId = cusOpsQueueId;
                    budgetCaseList.add(budgetCase);
                }
            }
            
            if(!budgetCaseList.isEmpty()){
                try{
                    insert budgetCaseList;
                }catch(Exception e){
                    System.debug('Error occurred while inserting budget validity case'+e.getMessage());
                }
            }  
        }
    }
}