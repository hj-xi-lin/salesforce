trigger leadConversionValidation on Lead (before update, after update) {
    if(trigger.isbefore && trigger.isupdate) {
    	leadConversionValidationHelper.validateLeads(trigger.new);
        //selfserviceLeadConversion.convertLead(Trigger.New, Trigger.OldMap);
    }
    
    if(trigger.isafter && trigger.isupdate){
        //Commented for RO-1585
        //selfserviceLeadConversion.domainMatchChanges(Trigger.New, Trigger.OldMap);
        //selfserviceLeadConversion.convertLead(Trigger.New, Trigger.OldMap);
        selfserviceLeadConversion.initiateCustomLeadConversion(Trigger.New, Trigger.OldMap);
    }
}