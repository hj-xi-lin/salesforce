/*
 *      @author Arun Kumar
 *      @date   02-May-2022
 *      @description 
 *
 *      Modification Log:
 *      ------------------------------------------------------------------------------------
 *      Developer                       Date                Description
 *      ------------------------------------------------------------------------------------
 *      Arun Kumar                  02-May-2022             Created for RO-879
 * 
 */
trigger UserTrigger on User (after delete, after insert, after undelete, after update, before delete, before insert, before update) {

    if (Trigger.isBefore){
        if (Trigger.isInsert) {
            //UserTriggerHandler.onBeforeInsert(Trigger.old , Trigger.new , Trigger.oldMap , Trigger.newMap);
        }
        
        if(Trigger.isUpdate){
            //UserTriggerHandler.onBeforeUpdate(Trigger.old , Trigger.new , Trigger.oldMap , Trigger.newMap);
        }
    }
}