trigger AccountTriggerHeyJobs on Account (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    
    /*AccountTrigger_Handler handler = new AccountTrigger_Handler(Trigger.isExecuting);
    
    if (Trigger.isBefore){
        if (Trigger.isInsert) {
            handler.onBeforeInsert(Trigger.new);
            handler.validateUmbrellaCompany(Trigger.new);
        }

        if(Trigger.isUpdate){
            handler.onBeforeUpdate(Trigger.old , Trigger.new , Trigger.oldMap , Trigger.newMap);
            handler.validateUmbrellaCompany(Trigger.new);
        }
    }*/
}