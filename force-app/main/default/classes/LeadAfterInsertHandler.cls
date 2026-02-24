/*
*      @author Arun Kumar
*      @date   19-Sep-2023
*      @description   Class to streamline the logic in After Insert Context of Lead Trigger
*
*      Modification Log:
*      ------------------------------------------------------------------------------------
*      Developer                       Date                Description
*      ------------------------------------------------------------------------------------
*  
*/
public with sharing class LeadAfterInsertHandler implements TriggerAction.AfterInsert {

    public void afterInsert(List<Lead> newList){
        LeadTriggerFunctions.createSSSUDuplicateCase(newList);
        LeadTriggerFunctions.checkConversionEligibility(newList);
        
    }
}