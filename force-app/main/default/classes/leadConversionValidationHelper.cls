public class leadConversionValidationHelper 
{
    public static void validateLeads(List<Lead> leadList) 
    {
        Map<string,Lead> leadMap = new Map<string,Lead>();
        Set<string> convertedAccIds = new set<string>();
        Set<string> convertedOpportunityIds = new set<string>();
        
        for(lead ld : leadList) 
        {
            if(ld.IsConverted) 
            {
                system.debug('--LEAD-->>'+ld);
                if(ld.Service_Country__c != null) 
                {
                    leadMap.put(ld.id, ld);
                    if(ld.ConvertedAccountId != null) {
                        convertedAccIds.add(ld.ConvertedAccountId);
                    }
                    if(ld.ConvertedOpportunityId != null) {
                        convertedOpportunityIds.add(ld.ConvertedOpportunityId);
                    }
                } else {
                    ld.addError('You have to define a Service Country before you can convert the Lead to an Account.');
                }
            }
        }
        system.debug('--leadMap-->>'+leadMap.size());
        system.debug('--convertedAccIds-->>'+convertedAccIds.size());
        system.debug('--convertedOpportunityIds-->>'+convertedOpportunityIds.size());
        
        if(!leadMap.isEmpty()) 
        {
            Map<string,Account> accMap;
            Map<string,Opportunity> oppMap;
            if(!convertedAccIds.isEmpty()) {
                accMap = new map<string,account>([select id, Service_Country__c, Umbrella_Company__c from account where id in :convertedAccIds]);
            }
            if(!convertedOpportunityIds.isEmpty()) {
                oppMap = new map<string,Opportunity>([select id, Service_Country__c from Opportunity where id in :convertedOpportunityIds]);
            }
            system.debug('---accMap-->>'+accMap);
            system.debug('---oppMap-->>'+oppMap);
            
            for(string ld : leadMap.keySet()) {
                lead leadObj = leadMap.get(ld);
                // Account Validation for Service Country
                if(leadObj.ConvertedAccountId != null && accMap != null && !accMap.isEmpty() && accMap.containsKey(leadObj.ConvertedAccountId)) {
                    if(leadObj.Service_Country__c != accMap.get(leadObj.ConvertedAccountId).Service_Country__c) {
                        leadObj.addError('You can not convert a Lead into an Account when they have different Service Countries.');
                    } else if(accMap.get(leadObj.ConvertedAccountId).Umbrella_Company__c) {
                        // Validation for Account marked as Umbrella Company.
                        leadObj.addError('You can not convert the lead into account with Umbrella company.');
                    }
                }
                // Opportunity validation for Service Country
                else if(leadObj.ConvertedOpportunityId != null && oppMap != null && !oppMap.isEmpty() && oppMap.containsKey(leadObj.ConvertedOpportunityId)) {
                    if(leadObj.Service_Country__c != oppMap.get(leadObj.ConvertedOpportunityId).Service_Country__c) {
                        leadObj.addError('You can not convert a Lead into an Opportunity when they have different Service Countries.');
                    }
                }
            }
        }
    }
}