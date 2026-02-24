/*
 *      @author Arun Kumar
 *      @date   12-Jun-2023
 *      @description   Logic to control the Contact trigger events
 *
 *      Modification Log:
 *      ------------------------------------------------------------------------------------
 *      Developer                       Date                Description
 *      ------------------------------------------------------------------------------------
 * 
 */
public class ContactTriggerHandler {
 private static Set<Id>             processedIds;  
    private Boolean                    isExecuting; 
    
    /**
    * Constructor 
    */
    public ContactTriggerHandler(Boolean isExecuting){
        this.isExecuting = isExecuting; 
        if(processedIds == null) processedIds = new Set<Id>();  
    }
    
    /*
    *  Identify whether a trigger event must be executed or not. 
    */  
      
    /*private Boolean mustBeExecuted(Set<Id> ids){
        
        //In a Before context we have to verify that these IDS have not been processed yet But not add them to the Set or the after won't fire. 
        if(Trigger.isBefore){
            if(processedIds.containsAll(ids)){     
                return false; //If set contains Ithese DS then it run on an After in a previous execution within the same context.  
            }else{
                return true;  
            } 
        }else{
            if(!processedIds.containsAll(ids)){              
                processedIds.addAll(ids); 
                return true;
            }else{
                return false; 
            }
        } 
    }*/

    public enum TriggerCont {isINSERT,isUPDATE,isDELETE,isUNDELETE} 
    
    /*
    *   BEFORE
    */

    // BEFORE INSERT
   
    /*
    *   AFTER
    */

    //AFTER INSERT

    //AFTER UPDATE
    public void onAfterUpdate(List<Contact> triggerOld , List<Contact> triggerNew , Map<Id,Contact> triggerOldMap , Map<Id,Contact> triggerNewMap){
		//ContactTriggerFunctions.callingBackendForAccess(triggerNew, triggerOldMap);
    }
    
    }