/*
*      @author Arun Kumar
*      @date   19-Sep-2023
*      @description   Trigger on Lead
*
*      Modification Log:
*      ------------------------------------------------------------------------------------
*      Developer                       Date                Description
*      ------------------------------------------------------------------------------------
*  
*/
trigger LeadTrigger on Lead (before insert,
  after insert,
  before update,
  after update,
  before delete,
  after delete,
  after undelete
) {
  new MetadataTriggerHandler().run();
}