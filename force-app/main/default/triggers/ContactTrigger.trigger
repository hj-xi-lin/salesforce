/*
 *      @author Arun Kumar
 *      @date   12-Jun-2023
 *      @description   Contact trigger
 *
 *      Modification Log:
 *      ------------------------------------------------------------------------------------
 *      Developer                       Date                Description
 *      ------------------------------------------------------------------------------------
 * 
 */
trigger ContactTrigger on Contact (before insert,
  after insert,
  before update,
  after update,
  before delete,
  after delete,
  after undelete
) {
  new MetadataTriggerHandler().run();
}