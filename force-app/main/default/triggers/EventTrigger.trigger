/*
*      @author Varun Subhash
*      @date- 12 Apr 2024
*      @description   Trigger on Event
*
*      Modification Log:
*      ------------------------------------------------------------------------------------
*      Developer                       Date                Description
*      ------------------------------------------------------------------------------------
*  
*/

trigger EventTrigger on Event (before insert) {
    new MetadataTriggerHandler().run();            
}