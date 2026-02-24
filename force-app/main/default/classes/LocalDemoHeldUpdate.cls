/*
 *      @author Lisa Müller
 *      @date   25-Jul-2023
 *      @description   RO-1620 Class to perform update of Demo Held Timestamp of lost Local opps 
 *
 *      Modification Log:
 *      ------------------------------------------------------------------------------------
 *      Developer                       Date                Description
 *      ------------------------------------------------------------------------------------
 *      Lisa Müller					11.09.2023				Populate previous timestamps RO-1674
 * 
 */

public with sharing class LocalDemoHeldUpdate {
    public static void UpdateDemoFields(List<Opportunity> oppList){
        
        // get opp & account IDs & maps for query
        Set<Id> oppIds = new Set<Id>();
        Set<Id> accIds = new Set<Id>();
        Map<Id, Id> accToOppMap = new Map<Id, Id>();
        Map<Id, Id> accToOppOwnerMap = new Map<Id, Id>();
        Map<Id, datetime> accToOppCreatedDateMap = new Map<Id, datetime>();
        for(Opportunity opp: oppList){
            oppIds.add(opp.Id);
            accIds.add(opp.AccountId);
            accToOppMap.put(opp.AccountId, opp.Id);
            accToOppOwnerMap.put(opp.AccountId, opp.OwnerId);
            accToOppCreatedDateMap.put(opp.AccountId, opp.CreatedDate);
        }
        
        // get task records by query         
        Task[] relevantCalls = [SELECT Id, OwnerId, CreatedDate, WhatId FROM Task WHERE (CallType = 'Inbound' OR CallType = 'Outbound') AND CallDurationInSeconds >= 120 AND (WhatId IN :oppIds OR WhatId IN :accIds) ORDER BY CreatedDate ASC];
 
        // create map of opp Id to related call (if any)
        Map<Id, Task> oppIdToCallMap = new Map<Id, Task>();
        for (Task call: relevantCalls){
            // if related to an opp and not in map: add to map
            if(oppIds.contains(call.WhatId) && !oppIdToCallMap.containsKey(call.WhatId)){
       			oppIdToCallMap.put(call.WhatId, call);
            }
            // if related to an account and not in map and owner and created date match the corresponding opp data: add to map
            else if( accIds.contains(call.WhatId) && !oppIdToCallMap.containsKey(accToOppMap.get(call.WhatId)) && accToOppOwnerMap.get(call.WhatId) == call.OwnerId && accToOppCreatedDateMap.get(call.WhatId) <= call.CreatedDate){
           		oppIdToCallMap.put(accToOppMap.get(call.WhatId), call);
            }
    	}
        
        // loop through opps & update
        for (Opportunity opp: oppList){
            if (oppIdToCallMap.containsKey(opp.Id)){
                Task relatedCall = oppIdToCallMap.get(opp.Id);
                opp.Demo_Date__c = relatedCall.CreatedDate.date();
                opp.Hunter__c = relatedCall.OwnerId;
                opp.Timestamp_Demo_Held__c = relatedCall.CreatedDate.date();
                opp.Timestamp_Demo_Held_Time__c = relatedCall.CreatedDate;
                
                // populate previous timestamps if empty
                if (opp.Timestamp_Not_reached_yet__c == NULL){
                    opp.Timestamp_Not_reached_yet__c = relatedCall.CreatedDate.date();
                    opp.Timestamp_Not_reached_yet_time__c = relatedCall.CreatedDate;
                }
                if (opp.Timestamp_Qualified_Prospect__c == NULL){
                    opp.Timestamp_Qualified_Prospect__c = relatedCall.CreatedDate.date();
                    opp.Timestamp_Qualified_Prospect_Time__c = relatedCall.CreatedDate;
                }
                if (opp.Timestamp_Currently_in_Contact__c == NULL){
                    opp.Timestamp_Currently_in_Contact__c = relatedCall.CreatedDate.date();
                    opp.Timestamp_Currently_in_Contact_Time__c = relatedCall.CreatedDate;
            	}               
                if (opp.Timestamp_Demo_Scheduled__c == NULL){
                    opp.Timestamp_Demo_Scheduled__c = relatedCall.CreatedDate.date();
                }
                if (opp.Timestamp_Demo_confirmed__c == NULL){
                    opp.Timestamp_Demo_confirmed__c = relatedCall.CreatedDate.date();
                }
            }
        }
        
     	try{
            update oppList;
            }catch(Exception e){
                
            }
      	
    }

}