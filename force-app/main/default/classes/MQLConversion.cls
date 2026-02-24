/*
*      @author Arun Kumar
*      @date   23-Nov-2023
*      @description   Class to streamline the MQL Conversion
*
*      Modification Log:
*      ------------------------------------------------------------------------------------
*      Developer                       Date                Description
*      ------------------------------------------------------------------------------------
*  
*/
public with sharing class MQLConversion implements TriggerAction.AfterInsert, TriggerAction.AfterUpdate{
    
    /**
@Methodname     : afterInsert
@Param          : List<Lead>
@Return         : Null
@Description    : To initiate the checking process if the MQL could be converted and further actions during the creation
**/
    public void afterInsert(List<Lead> newList){
         MQLConversionFunction.checkMQLConversionEligibilityOnInsert(newList);
    }
    
    /**
@Methodname     : afterUpdate
@Param          : List<Lead>
@Return         : Null
@Description    : To initiate the checking process if the MQL could be converted and further actions during the updates
**/
    public void afterUpdate(List<Lead> newList, List<Lead> oldList){
         MQLConversionFunction.checkMQLConversionEligibilityOnUpdate(newList, oldList);
    }
}