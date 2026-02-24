trigger QuoteTrigger on Quote (before update,before insert) {
	
    if(Trigger.isBefore && Trigger.isUpdate){
     	QuoteTriggerHandler.onBeforeUpdate(Trigger.New, Trigger.OldMap,Trigger.NewMap);
    }    
    
    if(Trigger.isBefore && Trigger.isInsert){
        QuoteTriggerHandler.onBeforeInsert(Trigger.New);
    }
}