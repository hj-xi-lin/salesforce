/*
*      @author Arun Kumar
*      @date   26-Oct-2023
*      @description   Class to streamline the logic in Before update context of Opportunity Trigger
*
*      Modification Log:
*      ------------------------------------------------------------------------------------
*      	Developer      	Date         	Description
*      ------------------------------------------------------------------------------------
*/

public class OpportunityBeforeUpdateHandler implements TriggerAction.BeforeUpdate{
    public void beforeUpdate(List<Opportunity> newList, List<Opportunity> oldList){
        HeyPaketUtility.checkActivationEligibility(newList, oldList);
    }
    
}