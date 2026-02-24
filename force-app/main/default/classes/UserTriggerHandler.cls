/*
 *      @author Arun Kumar
 *      @date   02-May-2022
 *      @description Handler class to control the execution sequence
 *
 *      Modification Log:
 *      ------------------------------------------------------------------------------------
 *      Developer                       Date                Description
 *      ------------------------------------------------------------------------------------
 *      Arun Kumar                  02-May-2022             Created for RO-879
 * 
 */

public without sharing class UserTriggerHandler {

    public enum TriggerCont {isINSERT,isUPDATE,isDELETE,isUNDELETE} 
    
    public static void onBeforeInsert(List<User> triggerOld , List<User> triggerNew , Map<Id,User> triggerOldMap , Map<Id,User> triggerNewMap){
        UserTriggerFunctions.checkServiceCountry(triggerNew, triggerOldMap, false, true);
        
    }
    
    public static void onBeforeUpdate(List<User> triggerOld , List<User> triggerNew , Map<Id,User> triggerOldMap , Map<Id,User> triggerNewMap){

        //if(mustBeExecuted(triggerNewMap.keySet())){
            UserTriggerFunctions.checkServiceCountry(triggerNew, triggerOldMap, true, false);
        //}
    }  
}