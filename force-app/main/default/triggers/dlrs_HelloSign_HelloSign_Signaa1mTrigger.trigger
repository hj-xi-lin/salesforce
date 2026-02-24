/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
trigger dlrs_HelloSign_HelloSign_Signaa1mTrigger on HelloSign__HelloSign_Signature_Request__c
    (before delete, before insert, before update, after delete, after insert, after undelete, after update)
{
    dlrs.RollupService.triggerHandler(HelloSign__HelloSign_Signature_Request__c.SObjectType);
}