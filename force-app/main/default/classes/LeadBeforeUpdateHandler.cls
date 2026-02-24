/*
*      @author Arun Kumar
*      @date   19-Sep-2023
*      @description   Class to streamline the logic in Before Update Context of Lead Trigger
*
*      Modification Log:
*      ------------------------------------------------------------------------------------
*      Developer                       Date                Description
*      ------------------------------------------------------------------------------------
*  
*/
public with sharing class LeadBeforeUpdateHandler implements TriggerAction.BeforeUpdate{
    
    public void beforeUpdate(List<Lead> newList, List<Lead> oldList){
         LeadTriggerFunctions.checkEmailDomainMatch(newList, oldList);
    }
}