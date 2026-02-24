/*
*      @author Arun Kumar
*      @date   19-Sep-2023
*      @description   Class to streamline the logic in After Update Context of Lead Trigger
*
*      Modification Log:
*      ------------------------------------------------------------------------------------
*      Developer                       Date                Description
*      ------------------------------------------------------------------------------------
*  
*/
public with sharing class LeadAfterUpdateHandler implements TriggerAction.AfterUpdate {

    public void afterUpdate(List<Lead> newList, List<Lead> oldList){
        LeadTriggerFunctions.createSSSUDuplicateCase(newList);
        LeadTriggerFunctions.checkConversionEligibility(newList, oldList);
    }
}