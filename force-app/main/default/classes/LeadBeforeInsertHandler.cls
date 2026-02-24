/*
*      @author Arun Kumar
*      @date   19-Sep-2023
*      @description   Class to streamline the logic in Before Insert Context of Lead Trigger
*
*      Modification Log:
*      ------------------------------------------------------------------------------------
*      Developer                       Date                Description
*      ------------------------------------------------------------------------------------
*  		Arun Kumar					16-Oct-2023				Added the calling for populateDomainMatchForPrivateEmails()
*/
public with sharing class LeadBeforeInsertHandler implements TriggerAction.BeforeInsert{
    
    public void beforeInsert(List<Lead> newList){
        LeadTriggerFunctions.populateDomainMatchForPrivateEmails(newList);
        LeadTriggerFunctions.checkEmailDomainMatch(newList);
    }

}