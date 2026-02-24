/*
 *      @author Varun Subhash
 *      @date   09-Apr-2024
 *      @description   Update the related account for YCBM events not linked to any account
 *
 *      Modification Log:
 *      ------------------------------------------------------------------------------------
 *      Developer                       Date                Description
 *      ------------------------------------------------------------------------------------
 * 
 */
 
public class EventTriggerHandler implements TriggerAction.BeforeInsert {
    
    public void beforeInsert(List<Event> triggerNew) {
        EventTriggerFunction.updateRelatedAccount(trigger.new);
    }
}